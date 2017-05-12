# Cache::Memcached::AnyEvent
#   is the API
# Cache::Memcached::AnyEvent::Selector
#   is the guts that selects sockets to talk to.
# Cache::Memcached::AnyEvent::Protocol
#   is the guy that actually speaks to memcached

package Cache::Memcached::AnyEvent;
use strict;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Carp;
use Module::Runtime ();
use Storable ();
use Scalar::Util ();

use constant +{
    HAVE_ZLIB => eval { require Compress::Zlib; 1 },
    # We may use stuff other than Storable, so the flag name is more generic
    F_SERIALIZE => 1, 
    F_COMPRESS => 2,
    COMPRESS_SAVINGS => 0.20,
};

our $VERSION = '0.00023';

sub new {
    my $class = shift;
    my %args  = @_ == 1 ? %{$_[0]} : @_;

    $args{protocol_class}   ||= 'Text';
    $args{selector_class}   ||= 'Traditional';
    $args{serializer_class} ||= 'Storable';

    my $self  = bless {
        auto_reconnect => 5,
        compress_threshold => 10_000,
        protocol => undef,
        reconnect_delay => 5,
        servers => undef,
        namespace => undef,
        %args,
        _active_servers => [],
        _active_server_count => 0,
        _is_connected => undef,
        _is_connecting => undef,
        _queue => [],
        _server_handles => {},
    }, $class;

    return $self;
}

# lazy build
sub selector {
    return $_[0]->{selector} ||=
        $_[0]->_build_helper('Selector', $_[0]->{selector_class});
}

sub protocol {
    $_[0]->{protocol} ||=
        $_[0]->_build_helper('Protocol', $_[0]->{protocol_class});
}

sub serializer {
    $_[0]->{serializer} ||=
        $_[0]->_build_helper('Serializer', $_[0]->{serializer_class});
}

sub _build_helper {
    my ($self, $prefix, $klass) = @_;
    if ($klass !~ s/^\+//) {
        $klass = "Cache::Memcached::AnyEvent::${prefix}::$klass";
    }

    Module::Runtime::check_module_name($klass);
    Module::Runtime::require_module($klass);
    return $klass->new(memcached => $self);
}

BEGIN {
    foreach my $attr ( qw(auto_reconnect compress_threshold reconnect_delay servers namespace) ) {
        eval <<EOSUB;
            sub $attr {
                my \$self = shift;
                my \$ret  = \$self->{$attr};
                if (\@_) {
                    \$self->{$attr} = shift;
                }
                return \$ret;
            }
EOSUB
        Carp::confess if $@;
    }
}

sub _connect_one {
    my ($self, $server, $cv) = @_;

    return if $self->{_is_connecting}->{$server};

    $cv->begin if $cv;
    my ($host, $port) = split( /:/, $server );
    $port ||= 11211;

    $self->{_is_connecting}->{$server} = tcp_connect $host, $port, sub {
        $self->_on_tcp_connect($server, @_);
        $cv->end if $cv;
    };
}

sub _on_tcp_connect {
    my ($self, $server, $fh, $host, $port) = @_;

    delete $self->{_is_connecting}->{$server}; # thanks, buddy
    if (! $fh) {
        # connect failed
        warn("failed to connect to $server [$!]");

        if ($self->{auto_reconnect} > $self->{_connect_attempts}->{ $server }++) {
            # XXX this watcher holds a reference to $self, which means
            # it will make your program wait for it to fire until 
            # auto_reconnect attempts have been made. 
            # if you need to close immediately, you need to call disconnect
            $self->{_reconnect}->{$server} = AE::timer $self->{reconnect_delay}, 0, sub {
                delete $self->{_reconnect}->{$server};
                $self->_connect_one($server);
            };
        }
    } else {
        my $h; $h = AnyEvent::Handle->new(
            fh => $fh,
            on_drain => sub {
                my $h = shift;
                if (defined $h->{wbuf} && $h->{wbuf} eq "") {
                    delete $h->{wbuf}; $h->{wbuf} = "";
                }
                if (defined $h->{rbuf} && $h->{rbuf} eq "") {
                    delete $h->{rbuf}; $h->{rbuf} = "";
                }
            },
            on_eof => sub {
                my $h = delete $self->{_server_handles}->{$server};
                $h->destroy();
                undef $h;
            },
            on_error => sub {
                my $h = delete $self->{_server_handles}->{$server};
                $h->destroy();
                $self->_connect_one($server) if $self->{auto_reconnect};
                undef $h;
            },
        );

        $self->_add_active_server( $server, $h );
        delete $self->{_connect_attempts}->{ $server };
        $self->protocol->prepare_handle( $fh );
    }
}

sub _add_active_server {
    my ($self, $server, $h) = @_;
    push @{$self->{_active_servers}}, $server;
    $self->{_active_server_count}++;
    $self->{_server_handles}->{ $server } = $h;
}

sub add_server {
    my ($self, @servers) = @_;
    push @{$self->{servers}}, @servers;
    $self->selector->set_servers( $self->{servers} );
}

sub connect {
    my $self = shift;

    return if $self->{_is_connecting} || $self->{_is_connected};
    $self->disconnect();
    delete $self->{_is_disconnecting};

    $self->{_is_connecting} = {};
    $self->{_active_servers} = [];
    $self->{_active_server_count} = 0;
    my $connect_cv = AE::cv {
        delete $self->{_is_connecting};
        if (! $self->{_active_server_count}) {
            die "Failed to connect to any memcached servers";
        }

        $self->{_is_connected} = 1;

        if (my $cb = $self->{ on_connect }) {
            $cb->($self);
        }
        $self->_drain_queue;
    };

    foreach my $server ( @{ $self->{ servers } }) {
        $self->_connect_one($server, $connect_cv);
    }
}

sub delete {
    my ($self, @args) = @_;
    my $cb       = pop @args if (ref $args[-1] eq 'CODE' or ref $args[-1] eq 'AnyEvent::CondVar');
    my $noreply  = !defined $cb;
    $self->_push_queue( $self->protocol->delete($self, @args, $noreply, $cb ) );
}

sub get_handle { shift->{_server_handles}->{ $_[0] } }

{
    my $installer = sub {
        my ($name, $code) = @_;
        {
            no strict 'refs';
            *{$name} = $code;
        }
    };

    foreach my $method ( qw( get get_multi ) ) {
        $installer->( $method, sub {
            my ($self, $keys, $cb) = @_;
            Scalar::Util::weaken($self);

            $self->_push_queue( $self->protocol->$method($self, $keys, $cb) );
        } );
    }

    foreach my $method ( qw( decr incr ) ) {
        $installer->($method, sub {
            my ($self, @args) = @_;
            my $cb = pop @args if (ref $args[-1] eq 'CODE' or ref $args[-1] eq 'AnyEvent::CondVar');
            my ($key, $value, $initial) = @args;
            Scalar::Util::weaken($self);
            $self->_push_queue( $self->protocol->$method( $self, $key, $value, $initial, $cb ) );
        });
    }

    foreach my $method ( qw(add append prepend replace set) ) {
        $installer->($method, sub {
            my ($self, @args) = @_;
            my $cb = pop @args if (ref $args[-1] eq 'CODE' or ref $args[-1] eq 'AnyEvent::CondVar');
            my ($key, $value, $exptime, $noreply) = @args;
            Scalar::Util::weaken($self);
            $self->_push_queue( $self->protocol->$method( $self, $key, $value, $exptime, $noreply, $cb ) );
        });
    }
}

sub stats {
    my ($self, @args) = @_;
    my $cb = pop @args if (ref $args[-1] eq 'CODE' or ref $args[-1] eq 'AnyEvent::CondVar');
    my ($name) = @args;
    $self->_push_queue( $self->protocol->stats($self, $name, $cb) );
}

sub version {
    my ($self, $cb) = @_;
    $self->_push_queue( $self->protocol->version($self, $cb) );
}

sub flush_all {
    my ($self, @args) = @_;
    my $cb = pop @args if (ref $args[-1] eq 'CODE' or ref $args[-1] eq 'AnyEvent::CondVar');
    my $noreply = !!$cb;
    my $delay = shift @args || 0;
    $self->_push_queue( $self->protocol->flush_all($self, $delay, $noreply, $cb) );
}

sub _push_queue {
    my ($self, $cb) = @_;
    push @{$self->{queue}}, $cb;
    $self->_drain_queue unless $self->{_is_draining};
}

sub _drain_queue {
    my $self = shift;
    if (! $self->{_is_connected}) {
        if ($self->{_is_connecting} or $self->{_is_disconnecting}) {
            return;
        }
        $self->connect;
        return;
    }

    if ($self->{_is_draining}) {
        return;
    }
    my $cb = shift @{$self->{queue}};
    return unless $cb;

    my $guard = AnyEvent::Util::guard {
        my $t; $t = AE::timer 0, 0, sub {
            $self->{_is_draining}--;
            undef $t;
            $self->_drain_queue;
        };
    };
    $self->{_is_draining}++;
    $cb->($guard);
}

sub disconnect {
    my $self = shift;

    my $handles = delete $self->{_server_handles};
    foreach my $handle ( values %$handles ) {
        if ($handle) {
            eval {
                $handle->stop_read;
                $handle->push_shutdown();
                $handle->destroy();
            };
        }
    }

    delete $self->{_is_connecting};
    delete $self->{_is_connected};
    delete $self->{_is_draining};

    $self->{_server_handles} = {};
    $self->{_is_disconnecting}++;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect;
}
    
sub _get_handle_for {
    $_[0]->selector->get_handle($_[1]);
}

sub _prepare_key {
    my ($self, $key) = @_;
    if (my $ns = $self->{namespace}) {
        $key = $ns . $key;
    }
    return $key;
}

sub normalize_key {
    my ($self, $key_ref) = @_;

    if (my $ns = $self->{namespace}) {
        $$key_ref =~ s/^$ns//;
    }
}

sub deserialize {
    my ($self, $flags_ref, $data_ref) = @_;
    if (defined $$flags_ref && defined $$data_ref) {
        if (HAVE_ZLIB && $$flags_ref & F_COMPRESS()) {
            $$data_ref = Compress::Zlib::memGunzip($$data_ref);
        }

        if ($$flags_ref & F_SERIALIZE()) {
            $self->serializer->deserialize($data_ref);
        }
    }
    return ();
}

sub should_serialize {
    return ref $_[1];
}

sub should_compress {
    my ($self, $len) = @_;

    if (HAVE_ZLIB) {
        my $threshold = $self->compress_threshold;
        my $compressable = $threshold && $len >= $threshold ;
        return $compressable;
    }

    return ();
}

sub serialize {
# XXX Micro optimization for this:
#    my ($self, $value_ref, $len_ref, $flags_ref) = @_;
#    $self->serializer->serialize($value_ref, $len_ref, $flags_ref);
    $_[0]->serializer->serialize($_[1], $_[2], $_[3]);
}

sub compress {
    my ($self, $value_ref, $len_ref, $flags_ref) = @_;
    my $c_val = Compress::Zlib::memGzip($$value_ref);
    my $c_len = bytes::length($c_val);

    if ($c_len < $$len_ref * ( 1 - COMPRESS_SAVINGS() ) ) {
        $$value_ref = $c_val;
        $$len_ref   = $c_len;
        $$flags_ref |= F_COMPRESS();
    }
}

1;

__END__

=head1 NAME

Cache::Memcached::AnyEvent - AnyEvent Compatible Memcached Client 

=head1 SYNOPSIS

    use Cache::Memcached::AnyEvent;

    my $memd = Cache::Memcached::AnyEvent->new({
        servers => [ '127.0.0.1:11211' ],
        compress_threshold => 10_000,
        namespace => 'myapp.',
    });

    $memd->get( $key, sub {
        my ($value) = @_;
        warn "got $value for $key";
    });

    $memd->disconnect();

    # use ketama algorithm instead of the traditional one
    my $memd = Cache::Memcached::AnyEvent->new({
        ...
        selector_class => 'Ketama',
        # or, selector => $object 
    });

    # use binary protocol instead of text
    my $memd = Cache::Memcached::AnyEvent->new({
        ...
        protocol_class => 'Binary',
        # or, protocol => $object,
    });


=head1 DESRIPTION

WARNING: BETA QUALITY CODE!

This module implements the memcached protocol as a AnyEvent consumer, and it implments both for text and binary protocols.

=head1 RATIONALE

There's another alternative L<AnyEvent> memcached client, L<AnyEvent::Memcached> which is perfectly fine, and I have nothing against you using that module. I just have some specific itches to scratch:

=over 4

=item Prerequisites

This module, L<Cache::Memcached::AnyEvent>, requires the bare minimum prerequisites to install. L<AnyEvent::Memcached> requires AnyEvent::Connection and Object::Event ;) Those modules are fine, I just don't use them, so I don't want them.

=item Binary Protocol

I was in the mood to implement the binary protocol. I don't believe it's a requirement to do anything, so this is purely a whim. There's nothing that requires binary protocol in the wild, so it has no practactical advantages. I just wanted to implement it :)

=item Cache::Memcached Interface

In general, this module follows the interface of Cache::Memcached.

=back

So choose according to your needs. If you for some reason don't want AnyEvent::Connection and Object::Event, want a binary protocol, and like to stick with Cache::Memcached interface (relatively speaking), then use this module. Otherwise, read the docs for each module, and choose the one that fits your needs.

=head1 METHODS

All methods interacting with a memcached server which can take a callback
function can also take a condvar instead. For example, 

    $memd->get( "foo", sub {
        my $value = shift;
    } );

is equivalent to

    my $cv = AE::cv {
        my $value = $_[0]->recv;
    };
    $memd->get( "foo", $cv );
    # optionally, call $cv->recv here.

=head2 new(%args) 

=over 4

=item auto_reconnect => $max_attempts

Set to 0 to disable auto-reconnecting

=item compress_threshold => $number

=item selector => $object

The selector is an object responsible for selecting the appropriate
Memcached server to store a particular key. This object MUST implement
the following methods:

    $object->set_server( @servernames );
    my $handle = $object->get_handle( $key );

By default if this argument is not specified, a selector object will
automatically be created using the value of the C<selector_class>
argument.

=item selector_class => $class_name_or_fragment

Specifies the selector class to be instantiated. The default value is "Traditional".

If the class name is preceded by a single '+', then that class name with the
'+' removed will be used as the class name. Otherwise, the prefix
"Cache::Memcached::AnyEvent::Selector::" will be added to the value
("Traditional" would be transformed to "Cache::Memcached::AnyEvent::Selector::Traditional")

=item namespace => $namespace

=item procotol => $object

The protocol is an object responsible for handling the actual talking to
the memcached servers. This object MUST implement all of the memcached
interface supported by Cache::Memcached::AnyEvent

By default if this argument is not specified, a protocol object will
automatically be created using the value of the C<protocol_class>
argument.

=item protocol_class => $classname

Specifies the protocol class to be instantiated. The default value is "Text".

If the class name is preceded by a single '+', then that class name with the
'+' removed will be used as the class name. Otherwise, the prefix
"Cache::Memcached::AnyEvent::Protocol::" will be added to the value
("Text" would be transformed to "Cache::Memcached::AnyEvent::Protocol::Text")

=item reconnect_delay => $seconds

Amount of time to wait between reconnect attempts

=item servers => \@servers

List of servers to use.

=back

C<%args> can also be a hashref.

=head2 auto_reconnect([$bool]);

Get/Set auto_reconnect flag.

=head2 add($key, $value[, $exptime, $noreply], $cb->($rc))

=head2 add_server( $host_port )

=head2 append($key, $value, $cb->($rc))

=head2 connect()

Explicitly connects to each server given. You DO NOT need to call this
explicitly.

=head2 decr($key, $delta[, $initial], $cb->($value))

=head2 delete($key, $cb->($rc))

=head2 disconnect()

=head2 flush_all()

=head2 get($key, $cb->($value))

=head2 get_handle( $host_port )

=head2 get_multi(\@keys, $cb->(\%values));

=head2 incr($key, $delta[, $initial], $cb->($value))

=head2 prepend($key, $value, $cb->($rc));

=head2 protocol($object)

=head2 replace($key, $value[, $exptime, $noreply], $cb->($rc))

=head2 remove($key, $cb->($rc))

Alias to delete

=head2 servers()

=head2 set($key, $value[, $exptime, $noreply], $cb->($rc))

=head2 stats($cmd, $cb->(\%stats))

=head2 version( $cb->(\%result) )

=head1 TODO

=over 4

=item Binary stats is not yet implemented.

=back

=head1 CONTRIBUTING

Contribution is welcome, but please make sure to follow this guideline:

=over 4

=item Please send changes AND tests.

In case of changes that supposedly fixes incorrect behavior, you MUST provide
me with a B<failing test case>. How should we know if you were hallucinating or just plain stupid if you can't reproduce it yourself?

=item Please send code, not an essay.

Please don't waste time trying to explain in a 10K email for stuff you can write in 10 lines of code.

I'm sorry, but I'm usually not interested in your opinion until I see some code. Writing essays to describe a software problem is stupid.

=item Please avoid emailing patches.

If at all possible, please use github pull requests instead of emailing me patches. Patches are stupid.

Please refer to the META.yml file for the repository location.

=back

So to summarize, contribution is welcome, but please don't be stupid.
If you can't follow the guideline, you will not be taken seriously.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
