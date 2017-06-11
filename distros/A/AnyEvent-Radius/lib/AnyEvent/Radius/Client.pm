package AnyEvent::Radius::Client;
# AnyEvent-based radius client
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle::UDP;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(
                handler packer auth_cache
                queue_cv write_cv read_cv
                sent_cnt reply_cnt queue_cnt
            ));

use Data::Radius::Constants qw(:all);
use Data::Radius::Dictionary ();
use Data::Radius::Packet ();

use constant {
    READ_TIMEOUT_SEC => 5,
    WRITE_TIMEOUT_SEC => 5,
    RADIUS_PORT => 1812,
    MAX_QUEUE => 255,
};

# new 'NAS'
# args:
#   ip
#   port
#   secret
#   dictionary
#   read_timeout
#   write_timeout
#- callbacks:
#    on_read
#    on_read_raw
#    on_read_timeout
#    on_write_timeout
#    on_error
sub new {
    my ($class, %h) = @_;

    die "No IP argument" if (! $h{ip});
    # either pre-created packer object, or need radius secret to create new one
    # dictionary is optional
    die "No radius secret" if (! $h{packer} && ! $h{secret});

    my $obj = bless {}, $class;
    $obj->init();

    my $on_read_cb = sub {
        my ($data, $handle, $from) = @_;
        $obj->read_cv->end;
        $obj->reply_cnt($obj->reply_cnt + 1);

        if ($h{on_read_raw}) {
            # dump raw data
            $h{on_read_raw}->($obj, $data, $from);
        }

        # using authenticator from request to verify reply
        my $request_id = $obj->packer()->request_id($data);
        # FIXME how to react on unknown request_id ?
        my $authenticator = delete $obj->auth_cache()->{ $request_id };
        if (! $authenticator) {
            # got unknown reply (with wrong request id?)
            if ($h{on_error}) {
                $h{on_error}->($obj, 'Unknown reply');
            }
            else {
                warn "Error: unknown reply";
            }
        }
        elsif ( $h{on_read} ) {
            # how to decode $from
            # my($port, $host) = AnyEvent::Socket::unpack_sockaddr($from);
            # my $ip = format_ipv4($host);

            my ($type, $req_id, $auth, $av_list) = $obj->packer()->parse($data, $authenticator);

            $h{on_read}->($obj, {
                        type => $type,
                        request_id => $req_id,
                        av_list => $av_list,
                        # from is sockaddr binary data
                        from => $from,
                        authenticator => $auth,
                    });
        }

        $obj->queue_cv->end;
    };

    my $on_read_timeout_cb = sub {
        my $handle = shift;
        if(! $obj->read_cv->ready) {
            if($h{on_read_timeout}) {
                $h{on_read_timeout}->($obj, $handle);
            }
            # stop queue
            $obj->queue_cv->send;
        }
        $handle->clear_rtimeout();
    };

    my $on_write_timeout_cb = sub {
        my $handle = shift;
        if(! $obj->write_cv->ready) {
            if($h{on_write_timeout}) {
                $h{on_write_timeout}->($obj, $handle);
            }
            # stop queue
            $obj->queue_cv->send;
        }
        $handle->clear_wtimeout();
    };

    # low-level socket errors
    my $on_error_cb = sub {
        my ($handle, $fatal, $error) = @_;
        # abort all
        $handle->clear_wtimeout();
        $handle->clear_rtimeout();
        $obj->queue_cv->send;
        if ($h{on_error}) {
            $h{on_error}->($obj, $error);
        }
        else {
            warn "Error occured: $error";
        }
    };

    my $handler = AnyEvent::Handle::UDP->new(
                connect => [ $h{ip}, $h{port} // RADIUS_PORT ],
                rtimeout => $h{read_timeout} // READ_TIMEOUT_SEC,
                wtimeout => $h{write_timeout} // WRITE_TIMEOUT_SEC,
                on_recv => $on_read_cb,
                on_rtimeout => $on_read_timeout_cb,
                on_wtimeout => $on_write_timeout_cb,
                # no packets to send
                #on_drain => sub { ... },
                on_error => $on_error_cb,
            );
    $obj->handler($handler);

    # allow to pass custom object
    my $packer = $h{packer} || Data::Radius::Packet->new(dict => $h{dictionary}, secret => $h{secret});
    $obj->packer($packer);

    return $obj;
}


sub _send_packet {
    my ($self, $packet) = @_;

    $self->queue_cnt($self->queue_cnt() + 1);

    # +1
    $self->queue_cv()->begin;
    $self->write_cv()->begin;
    $self->read_cv()->begin;

    my $cv = AnyEvent->condvar;

    $cv->cb(sub {
        $self->sent_cnt($self->sent_cnt() + 1);
        # -1
        $self->write_cv()->end;
    });

    # cv->send is called by Handle::UDP when packet is sent
    $self->handler()->push_send($packet, undef, $cv);
}

# wait for Handle to send all queued packets (or timeout)
# object is not usable after it - call init()
sub wait {
    my $self = shift;

    $self->queue_cv()->recv();
}

# reset vars - need to be called after wait() or on_ready()
sub init {
    my $self = shift;

    $self->read_cv(AnyEvent->condvar);
    $self->write_cv(AnyEvent->condvar);
    $self->queue_cv(AnyEvent->condvar);
    $self->sent_cnt(0);
    $self->reply_cnt(0);
    $self->queue_cnt(0);
    $self->auth_cache({});
}

# close open socket, object is unusable after it was called
sub destroy {
    my $self = shift;
    $self->handler()->destroy();
    $self->handler(undef);
}

sub DESTROY {
    my $self = shift;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    return if (! $self->handler());
    $self->handler()->destroy();
}

# group wait
# cv is AnyEvent condition var passed outside
#
# Example:
#  my $cv = AnyEvent->condvar;
#  $nas1->on_ready($cv);
#  $nas2->on_ready($cv);
#  $nas3->on_ready($cv);
#  $cv->recv;
#
sub on_ready {
    my ($self, $cv) = @_;

    $cv->begin();
    $self->queue_cv()->cb(sub { $cv->end });
}

sub load_dictionary {
    my ($class, $path) = @_;
    my $dict = Data::Radius::Dictionary->load_file($path);

    if(ref($class)) {
        $class->packer()->dict($dict);
    }

    return $dict;
}

# add packet to the queue
# type - radius code of request
# av_list - list of attributes in {Name => ... Value => ... } form
sub send_packet {
    my ($self, $type, $av_list) = @_;

    if ($self->queue_cnt >= MAX_QUEUE) {
        # queue overflow
        return undef;
    }

    my ($packet, $req_id, $auth) = $self->packer()->build(
                        type => $type,
                        av_list => $av_list,
                        with_msg_auth => 1,
                    );
    # required to verify reply
    $self->auth_cache()->{ $req_id } = $auth;

    $self->_send_packet($packet);

    return wantarray() ? ($req_id, $auth) : $req_id;
}

# shortcut methods:

sub send_auth {
    my $self = shift;
    return $self->send_packet(ACCESS_REQUEST, @_);
}

sub send_acct {
    my $self = shift;
    return $self->send_packet(ACCOUNTING_REQUEST, @_);
}

sub send_pod {
    my $self = shift;
    return $self->send_packet(DISCONNECT_REQUEST, @_);
}

sub send_coa {
    my $self = shift;
    return $self->send_packet(COA_REQUEST, @_);
}

1;

__END__

=head1 NAME

AnyEvent::Radius::Client - module to implement AnyEvent based RADIUS client

=head1 SYNOPSYS

    use AnyEvent;
    use AnyEvent::Radius::Client;

    my $dict = AnyEvent::Radius::Client->load_dictionary('path-to-radius-dictionary');

    sub read_reply_callback {
        # $h is HASH-REF {type, request_id, av_list, from, authenticator}
        my ($self, $h) = @_;
        ...
    }

    my $client = AnyEvent::Radius::Client->new(
                        ip => $ip,
                        port => $port,
                        on_read => \&read_reply_callback,
                        dictionary => $dict,
                        secret => $secret,
                    );
    $client->send_auth(AV_LIST1);
    $client->send_auth(AV_LIST2);
    ...
    $client->wait;
    ...
    $client->destroy;

=head1 DESCRIPTION

The L<AnyEvent::Radius::Client> module allows to send multiple RADIUS requests in non-blocking way,
and then wait for responses.


=head1 CONSTRUCTOR

=over

=item new ( ..options hash )

=over

=item ip

=item port - where to connect

=item secret - RADIUS secret string for remote server

=item dictionary - optional, dictionary loaded by L<load_dictionary()> method

=item read_timeout

=item write_timeout - network I/O timeouts (default is 5 second)

=item Callbacks:

=over

=item on_read - called when reply received, arguments is hash-ref with {request_id, type, av_list, authenticator} keys

=item on_read_raw - called when reply received, raw data packet is provided as argument

=item on_read_timeout - timeout waiting for reply from server. Aborts the waiting state

=item on_write_timeout - timeout sending request

=item on_error - invalid packet received, or low-level socket error

=back

=back

=back

=head1 METHODS

=over

=item load_dictionary ($dictionary-file)

Class method to load dictionary - returns the object to be passed to constructor

=item send_packet ( $type, $av_list )

Builds RADIUS packet using L<Data::Radius::Packet> and store it to outgoing queue.
Returns request id.
Note that it's not possible to schedule more than 255 requests - trying to add more will return undef

=item send_auth ($av_list)

=item send_acct ($av_list)

=item send_pod ($av_list)

=item send_coa ($av_list)

Helper methods to send RADIUS request of required type by L<send_request()>

=item wait()

Blocks until all requests are received or read timeout reached

=item on_ready ( $cond_var )

Used to coordinate multiple clients instead of L<wait()>

Example:

    my $cv = AnyEvent->condvar;
    $client1->on_ready($cv);
    $client2->on_ready($cv);
    $client3->on_ready($cv);
    $cv->recv;

Will be blocked until all clients finish their queue.

=item destroy()

Destroy the internal socket handle. Must be called when object is no longer required.
When called from callback, it is recommended to wrap this call into AnyEvent::postpone { ... } block.

=back

=head1 SEE ALSO

L<Authen::Radius>, L<AnyEvent::Radius::Server>, L<Data::Radius>

=head1 AUTHOR

Sergey Leschenko <sergle.ua at gmail.com>

PortaOne Development Team <perl-radius at portaone.com> is the current module's maintainer at CPAN.

=cut
