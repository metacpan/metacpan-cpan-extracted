package Argon::Stream;

use Moo;
use Types::Standard qw(-types);
use AnyEvent;
use AnyEvent::Socket;
use Carp;
use Coro;
use Coro::Handle;
use Socket qw(unpack_sockaddr_in inet_ntoa);
use Argon::Message;
use Argon qw(:logging);

#-------------------------------------------------------------------------------
# Non-blocking Coro::Handle for this connection.
#-------------------------------------------------------------------------------
has handle => (
    is        => 'rwp',
    isa       => InstanceOf['Coro::Handle'],
    required  => 1,
    clearer   => '_clear_handle',
    predicate => 'is_connected',
    handles   => {fh => 'fh'}
);

#-------------------------------------------------------------------------------
# The host:port for this connection.
#-------------------------------------------------------------------------------
has addr => (
    is       => 'lazy',
    isa      => Str,
    init_arg => undef,
);

sub _build_addr {
    my $self = shift;
    my ($port, $ip) = unpack_sockaddr_in($self->handle->sockname);
    my $host = inet_ntoa($ip);
    sprintf('%s:%d', $host, $port);
}

#-------------------------------------------------------------------------------
# Connects to $host:$port. Returns once the connection is made.
#-------------------------------------------------------------------------------
sub connect {
    my ($class, $host, $port) = @_;
    my $rouse = rouse_cb;
    my $stream;
    my $error;

    tcp_connect($host, $port,
        sub {
            my $fh = shift;
            if ($fh) {
                $stream = $class->new(handle => unblock $fh);
            } else {
                $error = "error connecting to $host:$port: $!";
            }

            $rouse->();
        },
        sub { $Argon::CONNECT_TIMEOUT },
    );

    rouse_wait($rouse);
    croak $error if $error;
    return $stream;
}

#-------------------------------------------------------------------------------
# Closes the connection.
#-------------------------------------------------------------------------------
sub close {
    my $self = shift;
    $self->handle->close;
    $self->_clear_handle;
}

#-------------------------------------------------------------------------------
# Writes $msg to the line.
#-------------------------------------------------------------------------------
sub write {
    my ($self, $msg) = @_;
    croak 'not connected' unless $self->is_connected;
    $self->handle->print($msg->encode . $Argon::EOL);
}

#-------------------------------------------------------------------------------
# Reads an Argon::Message from the line. Throws an error on junk input.
#-------------------------------------------------------------------------------
sub read {
    my $self = shift;
    croak 'not connected' unless $self->is_connected;
    my $line = $self->handle->readline($Argon::EOL) or return;
    do { local $\ = $Argon::EOL ; chomp $line };
    return Argon::Message->decode($line);
}

1;
