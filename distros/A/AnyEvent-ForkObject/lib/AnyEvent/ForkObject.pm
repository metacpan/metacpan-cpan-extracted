package AnyEvent::ForkObject;

use 5.010001;
use strict;
use warnings;

use Carp;
use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Handle;
use Scalar::Util qw(weaken blessed reftype);
use POSIX;
use IO::Handle;
use AnyEvent::Serialize qw(:all);
use AnyEvent::Tools qw(mutex);
use Devel::GlobalDestruction;


our $VERSION = '0.09';

sub new
{
    my ($class) = @_;

    my $self = bless { } => ref($class) || $class;
    my ($s1, $s2) = portable_socketpair;

    if ($self->{pid} = fork) {
        # parent
        $self->{mutex} = mutex;
        close $s2;
        fh_nonblocking $s1, 1;
        {
            weaken(my $self = $self);
            $self->{handle} = new AnyEvent::Handle
                fh => $s1,
                on_error => sub {
                    return unless $self;
                    return if $self->{destroyed};
                    delete $self->{handle};
                    $self->{fatal} = $!;
                    $self->{cb}(fatal => $self->{fatal}) if $self->{cb};
                };
        }
    } elsif (defined $self->{pid}) {
        # child
        close $s1;
        $self->{socket} = $s2;
        $self->{object} = {};
        $self->{no} = 0;
        $self->_start_server;
    } else {
        die $!;
    }

    return $self;
}

sub do :method
{
    my ($self, %opts) = @_;
    my $method = $opts{method} || 'new';
    my $invocant = $opts{module} || $opts{_invocant};
    my $cb = $opts{cb} || sub {  };
    my $args = $opts{args} || [];
    my $wantarray = $opts{wantarray};
    my $require = $opts{require};
    $wantarray = 0 unless exists $opts{wantarray};

    weaken $self;
    $self->{mutex}->lock(sub {
        my ($guard) = @_;
        return unless $self;
        return if $self->{destroyed};

        $self->{cb} = $cb;

        unless ($self->{handle}) {
            $cb->(fatal => 'Child process was destroyed');
            undef $guard;
            return;
        }

        if ($self->{fatal}) {
            $cb->(fatal => $self->{fatal});
            delete $self->{cb};
            undef $guard;
            return;
        }

        serialize {
                $require ? (r => $require) : (
                    i   => $invocant,
                    m   => $method,
                    a   => $args,
                    wa  => $wantarray
                )
            } => sub {
                return unless $self;
                return if $self->{destroyed} or $self->{fatal};

                $self->{handle}->push_write("$_[0]\n");
                return unless $self;
                return if $self->{destroyed} or $self->{fatal};

                $self->{handle}->push_read(line => "\n", sub {
                    deserialize $_[1] => sub {
                        return unless $self;
                        return if $self->{destroyed} or $self->{fatal};

                        my ($o, $error, $tail) = @_;

                        if ($error) {
                            $cb->(fatal => $error);
                            delete $self->{cb};
                            undef $guard;
                            return;
                        }

                        my $status = shift @$o;
                        if ($status eq 'ok') {
                            for (@$o) {
                                if (exists $_->{obj}) {
                                    $_ = bless {
                                        no => "$_->{obj}",
                                        fo => \$self,
                                    } => 'AnyEvent::ForkObject::OneObject';
                                    next;
                                }

                                $_ = $_->{res};
                            }
                            $cb->(ok => @$o);
                        } else {
                            $cb->($status => @$o);
                        }
                        delete $self->{cb};
                        undef $guard;
                    };
                    return;
                });

                return;
            };
    });

    return;
}


sub DESTROY
{
    my ($self) = @_;
    $self->{destroyed} = 1;
    $self->{handle}->push_write("'bye'\n") if $self->{handle};
    delete $self->{handle};

    return if in_global_destruction;

    # kill zombies
    my $cw;
    $cw = AE::child $self->{pid} => sub {
        my ($pid, $code) = @_;
        undef $cw;
    };
}

sub _start_server
{
    my ($self) = @_;
    croak "Something wrong" if $self->{pid};
    my $err_code = 0;

    require Data::StreamSerializer;

    my $socket = $self->{socket};
    $socket->autoflush(1);
    while(<$socket>) {
        my $response;
        next unless /\S/;
        my $cmd = eval $_;
        if ($@) {
            $err_code = 1;
            last;
        }

        unless (ref $cmd) {
            if ($cmd eq 'bye') {
                undef $_ for values %{ $self->{object} };
                delete $self->{object};
                last;
            }

            eval $cmd;

            if ($@) {
                $response = [ die => $@ ];
                goto RESPONSE;
            }

            $response = [ 'ok' ];
            goto RESPONSE;
        }

        # require
        if ($cmd->{r}) {
            eval "require $cmd->{r}";
            if ($@) {
                $response = [ die => $@ ];
                goto RESPONSE;
            }

            $response = [ 'ok' ];
            goto RESPONSE;
        }


        my ($invocant, $method, $args, $wantarray) = @$cmd{qw(i m a wa)};
        if ($invocant =~ /^\d+$/) {
            if ($method eq 'DESTROY') {
                delete $self->{object}{$invocant};
                $response = [ 'ok' ];
                goto RESPONSE;
            } else {
                $invocant = $self->{object}{$invocant}
            }
        }

        my @o;

        if ($method eq 'fo_attr') {
            unless (ref $invocant) {
                $response = [ die => 'fo_attr should be called as method' ];
                goto RESPONSE;
            }

            if ('ARRAY' eq reftype $invocant) {
                $invocant->[ $args->[0] ] = $args->[1] if @$args > 1;
                $o[0] = $invocant->[ $args->[0] ];
            } elsif ('HASH' eq reftype $invocant) {
                $invocant->{ $args->[0] } = $args->[1] if @$args > 1;
                $o[0] = $invocant->{ $args->[0] };
            } else {
                $response = [
                    die => "fo_attr can't access on blessed " .
                        reftype $invocant
                ];
                goto RESPONSE;
            }

        } else {
            if ($wantarray) {
                @o = eval { $invocant -> $method ( @$args ) };
            } elsif (defined $wantarray) {
                $o[0] = eval { $invocant -> $method ( @$args ) };
            } else {
                eval { $invocant -> $method ( @$args ) };
            }

            if ($@) {
                $response = [ die => $@ ];
                goto RESPONSE;
            }
        }

        for (@o) {
            if (ref $_ and blessed $_) {
                my $no = ++$self->{no};
                $self->{object}{$no} = $_;

                $_ = { obj => $no };
                next;
            }

            $_ = { res => $_ };
        }

        $response = [ ok => @o ];

        RESPONSE:
            my $sr = new Data::StreamSerializer($response);
            while(defined(my $part = $sr->next)) {
                print $socket $part;
            }
            print $socket "\n";
    }

    # destroy internal objects
    delete $self->{object};

    # we don't want to call any other destructors
    POSIX::_exit($err_code);
}

package AnyEvent::ForkObject::OneObject;
use Carp;
use Scalar::Util qw(blessed);
use Devel::GlobalDestruction;

sub AUTOLOAD
{
    our $AUTOLOAD;
    my ($foo) = $AUTOLOAD =~ /([^:]+)$/;

    my ($self, @args) = @_;
    my $cb = pop @args;
    my $wantarray = 0;
    if ('CODE' ne ref $cb) {
        $wantarray = $cb;
        $cb = pop @args;
    }
    croak "Callback is required" unless 'CODE' eq ref $cb;

    my $fo = $self->{fo};

    unless ($$fo) {
        $cb->(fatal => 'Child process was already destroyed');
        return;
    }

    $$fo -> do(
        _invocant => $self->{no},
        method    => $foo,
        args      => \@args,
        cb        => $cb,
        wantarray => $wantarray
    );
    return;
}

sub DESTROY
{
    # You can call DESTROY by hand
    my ($self, $cb) = @_;
    return if in_global_destruction;
    $cb ||= sub {  };
    my $fo = $self->{fo};
    unless (blessed $$fo) {
        $cb->(fatal => 'Child process was already destroyed');
        return;
    }

    $$fo -> do(
        _invocant   => $self->{no},
        method      => 'DESTROY',
        cb          => $cb,
        wantarray   => undef,
    );
    return;
}

1;
__END__

=head1 NAME

AnyEvent::ForkObject - Async access on objects.

=head1 SYNOPSIS

    use AnyEvent::ForkObject;
    use DBI;

    my $fo = new AnyEvent::ForkObject;

    $fo->do(
        module => 'DBI',
        method => 'connect',
        args => [ 'dbi:mysql...' ],
        cb => sub {
            my ($status, $dbh) = @_;


            $dbh->selectrow_array('SELECT ?', undef, 1 + 1, sub {
                my ($status, $result) = @_;
                print "$result\n";   # prints 2
            });
        }
    );


    use AnyEvent::Tools qw(async_repeat);

    $dbh->prepare('SELECT * FROM tbl', sub {
        my ($status, $sth) = @_;
        $sth->execute(sub {
            my ($status, $rv) = @_;

            # fetch 30 rows
            async_repeat 30 => sub {
                my ($guard) = @_;

                $sth->fetchrow_hashref(sub {
                    my ($status, $row) = @_;
                    undef $guard;

                    # do something with $row
                });
            };

        });
    });

=head1 DESCRIPTION

There are a lot of modules that provide object interface. Using the module
You can use them in async mode.

=head1 METHODS

=head2 new

Constructor. Creates an instance that contains fork jail.

=head2 do

Creates an object inside jail. It receives the following named arguments:

=over


=item B<require>

Do B<require> inside jail. If the argument is exists, B<module>, B<method>
and B<wantarray> arguments will be ignored.

=item B<module>

Module name. For example 'B<DBI>'.

=item B<method>

Constructor name. Default value is 'B<new>'.

=item B<wantarray>

Context for method. Default is B<0> (SCALAR).

=item B<cb>

Done callback. The first argument is a status:

=over

=item B<die>

The method has thrown exception. The next argument contains B<$@>.

=item B<fatal>

A fatal error was occured (for example fork jail was killed).

=item B<ok>

Method has done. The following arguments contain all data that were returned
by the method.

=back

=back

If L</method> returns blessed object, it will provide all its methods in
modified form. Each method will receive one or two additional arguments:

=over

=item B<result callback>

A callback that will be called after method has done.

=item B<wantarray>

Context flag for method. Default value is B<0> (SCALAR).

=back

All objects provide additional method B<fo_attr> to access their field.
Example:

    # set attribute
    $dbh->fo_attr(RaiseError => 1, sub { my ($status, $attr) = @_; ... });

    # get attribute
    $dbh->fo_attr('RaiseError', sub { my ($status, $attr) = @_; ... });

=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 VCS

The project is placed in my git repo:
L<http://git.uvw.ru/?p=anyevent-forkobject;a=summary>

=cut
