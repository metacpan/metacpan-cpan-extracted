package Argon::Service;

use Moo;
use MooX::HandlesVia;
use Types::Standard qw(-types);
use Carp;
use Coro;
use Coro::Handle;
use AnyEvent;
use AnyEvent::Socket;
use Guard;
use Argon::Message;
use Argon::Stream;
use Argon qw(:commands :logging);

#-------------------------------------------------------------------------------
# Listening port number. Assigned by OS and set if not provided by the caller.
#-------------------------------------------------------------------------------
has port => (
    is  => 'rwp',
    isa => Int,
);

#-------------------------------------------------------------------------------
# Listening host address. Assigned by OS and set if not provided by the caller.
#-------------------------------------------------------------------------------
has host => (
    is  => 'rwp',
    isa => Str,
);

#-------------------------------------------------------------------------------
# Address in the format of host:port. Set on initialization from the listening
# socket.
#-------------------------------------------------------------------------------
has address => (
    is       => 'rwp',
    isa      => Str,
    init_arg => undef,
);

#-------------------------------------------------------------------------------
# Stores the rouse callback used to shut down the service.
#-------------------------------------------------------------------------------
has stop_cb => (
    is          => 'rwp',
    isa         => CodeRef,
    init_arg    => undef,
    handles_via => 'Code',
    handles     => { stop => 'execute' }
);

#-------------------------------------------------------------------------------
# Starts the service. Once the socket is built, the host, port, and address are
# all set to the actual values according to the socket. If provided, $cb is
# called once the service is started.
#-------------------------------------------------------------------------------
sub start {
    my ($self, $cb) = @_;

    $self->_set_stop_cb(rouse_cb);
    my $sigint  = AnyEvent->signal(signal => 'INT',  cb => $self->stop_cb);
    my $sigterm = AnyEvent->signal(signal => 'TERM', cb => $self->stop_cb);

    my $guard = tcp_server(
        $self->host,
        $self->port,
        # accept callback
        sub {
            my ($fh, $host, $port) = @_;
            async_pool { $self->process_requests(unblock($fh), "$host:$port") };
        },
        # prepare callback
        sub {
            my ($fh, $host, $port) = @_;
            INFO 'Service started on %s:%d', $host, $port;
            $self->_set_port($port);
            $self->_set_host($host);
            $self->_set_address("$host:$port");
            $self->init;
            $cb->($self->address) if $cb && ref $cb eq 'CODE';
        },
    );

    rouse_wait($self->stop_cb);
    $self->shutdown;
    INFO 'Service stopped';
}

#-------------------------------------------------------------------------------
# Process requests for a single client.
#-------------------------------------------------------------------------------
sub process_requests {
    my ($self, $handle, $addr) = @_;
    my $stream = Argon::Stream->new(handle => $handle);

    INFO 'Accepted connection from client (%s)', $addr;
    $self->client_connected($addr);

    scope_guard {
        if ($@) {
            WARN 'Error occurred processing request from %s: %s', $addr, $@;
        }

        INFO 'Lost connection to client (%s)', $addr;
        $self->client_disconnected($addr);
    };

    while (my $msg = $stream->read) {
        async_pool {
            my $reply = eval { $self->dispatch($msg, $addr) };

            if ($@) {
                $reply = $msg->reply(cmd => $CMD_ERROR, payload => $@);
            } elsif (!$reply || !$reply->isa('Argon::Message')) {
                $reply = $msg->reply(cmd => $CMD_ERROR, payload => 'The server generated an invalid response.');
            }

            $stream->write($reply);
        };
    }
}

#-------------------------------------------------------------------------------
# Methods triggered by the Argon::Service. These are used by derived classes to
# hook into different events in the service's life cycle.
#-------------------------------------------------------------------------------
sub init                { }
sub client_connected    { }
sub client_disconnected { }
sub shutdown            { }

1;
