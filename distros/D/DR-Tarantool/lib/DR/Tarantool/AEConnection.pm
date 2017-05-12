use utf8;
use strict;
use warnings;

package DR::Tarantool::AEConnection;
use AnyEvent;
use AnyEvent::Socket ();
use Carp;
use List::MoreUtils ();
use Scalar::Util ();

sub _errno() {
    while (my ($k, $v) = each(%!)) {
        return $k if $v;
    }
    return $!;
}

sub new {
    my ($class, %opts) = @_;

    $opts{state} = 'init';
    $opts{host}  ||= '127.0.0.1';
    croak 'port is undefined' unless $opts{port};


    $opts{on}{connected}    ||= sub {  };
    $opts{on}{connfail}     ||= sub {  };
    $opts{on}{disconnect}   ||= sub {  };
    $opts{on}{error}        ||= sub {  };
    $opts{on}{reconnecting} ||= sub {  };

    $opts{success_connects} = 0;
    $opts{wbuf} = '';

    $opts{read} = { any => [] };

    bless \%opts => ref($class) || $class;
}


sub on {
    my ($self, $name, $cb) = @_;
    croak "wrong event name: $name" unless exists $self->{on}{$name};
    $self->{on}{$name} = $cb || sub {  };
    $self;
}

sub fh      { $_[0]->{fh} }
sub state   { $_[0]->{state} }
sub host    { $_[0]->{host} }
sub port    { $_[0]->{port} }
sub error   { $_[0]->{error} }
sub errno   { $_[0]->{errno} }
sub reconnect_always    { $_[0]->{reconnect_always} }
sub reconnect_period    { $_[0]->{reconnect_period} }
sub timeout {
    my ($self) = @_;
    return $self->{timeout} if @_ == 1;
    return $self->{timeout} = $_[1];
}


sub set_error {
    my ($self, $error, $errno) = @_;
    $errno ||= $error;
    $self->{state} = 'error';
    $self->{error} = $error;
    $self->{errno} = $errno;
    $self->{on}{error}($self);
    $self->{guard} = {};
    $self->{wbuf} = '';

    $self->_check_reconnect;
    
}

sub _check_reconnect {
    Scalar::Util::weaken(my $self = shift);
    return if $self->state eq 'connected';
    return if $self->state eq 'connecting';
    return if $self->{guard}{rc};

    return unless $self->reconnect_period;
    unless ($self->reconnect_always) {
        return unless $self->{success_connects};
    }

    $self->{guard}{rc} = AE::timer $self->reconnect_period, 0, sub {
        return unless $self;
        delete $self->{guard}{rc};
        $self->{on}{reconnecting}($self);
        $self->connect;
    };
}

sub connect {
    Scalar::Util::weaken(my $self = shift);

    return if $self->state eq 'connected' or $self->state eq 'connecting';

    $self->{state} = 'connecting';
    $self->{error} = undef;
    $self->{errno} = undef;
    $self->{guard} = {};

    $self->{guard}{c} = AnyEvent::Socket::tcp_connect
        $self->host,
        $self->port,
        sub {
            $self->{guard} = {};
            my ($fh) = @_;
            if ($fh) {
                $self->{fh} = $fh;
                $self->{state} = 'connected';
                $self->{success_connects}++;
                $self->push_write('') if length $self->{wbuf};
                $self->{on}{connected}($self);
                return;
            }
    
            $self->{error} = $!;
            $self->{errno} = _errno;
            $self->{state} = 'connfail';
            $self->{guard} = {};
            $self->{on}{connfail}($self);
            return unless $self;
            $self->_check_reconnect;
        },
        sub {

        }
    ;

    if (defined $self->timeout) {
        $self->{guard}{t} = AE::timer $self->timeout, 0, sub {
            delete $self->{guard}{t};
            return unless $self->state eq 'connecting';

            $self->{error} = 'Connection timeout';
            $self->{errno} = 'ETIMEOUT';
            $self->{state} = 'connfail';
            $self->{guard} = {};
            $self->{on}{connfail}($self);
            $self->_check_reconnect;
        };
    }
   
    $self;
}

sub disconnect {
    Scalar::Util::weaken(my $self = shift);
    return if $self->state eq 'disconnect' or $self->state eq 'init';

    $self->{guard} = {};
    $self->{error} = 'Disconnected';
    $self->{errno} = 'SUCCESS';
    $self->{state} = 'disconnect';
    $self->{wbuf} = '';
    $self->{on}{disconnect}($self);
}


sub push_write {
    Scalar::Util::weaken(my $self = shift);
    my ($str) = @_;

    $self->{wbuf} .= $str;

    return unless $self->state eq 'connected';
    return unless length $self->{wbuf};
    return if $self->{guard}{write};

    $self->{guard}{write} = AE::io $self->fh, 1, sub {
        my $l = syswrite $self->fh, $self->{wbuf};
        unless(defined $l) {
            return if $!{EINTR};
            $self->set_error($!, _errno);
            return;
        }
        substr $self->{wbuf}, 0, $l, '';
        return if length $self->{wbuf};
        delete $self->{guard}{write};
    };
}




1;
