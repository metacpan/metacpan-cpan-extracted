package Argon::Worker;

use Moo;
use Types::Standard qw(-types);
use Carp;
use Coro;
use Coro::ProcessPool;
use Guard;
use List::Util qw(max);
use Argon::Message;
use Argon::Stream;
use Argon qw(K :commands :logging);

extends 'Argon::Dispatcher';

#-------------------------------------------------------------------------------
# Manager's address in the format "host:port"
#-------------------------------------------------------------------------------
has manager => (
    is        => 'rwp',
    isa       => sub {
        croak sprintf("'%s' does not match host:port", ($_[0] || 'undef'))
            if !defined $_[0]
            || $_[0] !~ /^[\w\.]+:\d+$/;
    },
    predicate => 'is_managed',
);

#-------------------------------------------------------------------------------
# Number of worker processes
#-------------------------------------------------------------------------------
has workers => (
    is  => 'rwp',
    isa => Maybe[Int],
);

#-------------------------------------------------------------------------------
# Number of requests each worker process may handle before being restarted
#-------------------------------------------------------------------------------
has max_requests => (
    is  => 'ro',
    isa => Maybe[Int],
);

#-------------------------------------------------------------------------------
# Coro::ProcessPool object which manages the worker processes
#-------------------------------------------------------------------------------
has pool => (
    is  => 'lazy',
    isa => InstanceOf['Coro::ProcessPool'],
);

sub _build_pool {
    my $self = shift;

    INFO 'Starting worker with %s pool processes', ($self->workers || 'default');

    my $pool = Coro::ProcessPool->new(
        ($self->workers      ? (max_procs => $self->workers)      : ()),
        ($self->max_requests ? (max_reqs  => $self->max_requests) : ()),
    );

    $self->_set_workers($pool->{max_procs}) unless $self->workers;

    return $pool;
}

#-------------------------------------------------------------------------------
# Unique key to identify the worker with the manager
#-------------------------------------------------------------------------------
has key => (
    is      => 'lazy',
    isa     => Str,
    default => sub { Data::UUID->new->create_str },
);

#-------------------------------------------------------------------------------
# Total capacity of the worker, equating to the number of worker processes
# available.
#-------------------------------------------------------------------------------
has capacity => (
    is  => 'lazy',
    isa => Int,
);

sub _build_capacity { $_[0]->pool->{max_procs} }

#-------------------------------------------------------------------------------
# Set to true once the worker has registered with the manager. Set to false if
# the connection is lost or the worker is not managed.
#-------------------------------------------------------------------------------
has is_registered => (
    is       => 'rwp',
    isa      => Bool,
    default  => 0,
    init_arg => undef,
);

#-------------------------------------------------------------------------------
# When the worker has registered with the manager, this stores the address of
# the Argon::Client being used by the manager to send tasks to this worker.
#-------------------------------------------------------------------------------
has manager_client_addr => (
    is        => 'rwp',
    isa       => Str,
    init_arg  => undef,
    clearer   => 'clear_manager_client_addr',
);

#-------------------------------------------------------------------------------
# Shut down the process pool when the server stops
#-------------------------------------------------------------------------------
around stop => sub {
    my $orig = shift;
    my $self = shift;
    $self->pool->shutdown;
    $self->$orig(@_);
};

#-------------------------------------------------------------------------------
# Initialize the worker, configure responders. Start registration loop if this
# is a managed worker.
#-------------------------------------------------------------------------------
after init => sub {
    my $self = shift;
    $self->respond_to($CMD_QUEUE, K('cmd_queue', $self));
    $self->respond_to($CMD_PING,  K('cmd_ping',  $self));

    if ($self->is_managed) {
        INFO 'Starting worker node in managed mode with %d processes', $self->capacity;
        async_pool { $self->register_loop };
    } else {
        INFO 'Starting worker node in standalone mode with %d processes', $self->capacity;
    }
};

#-------------------------------------------------------------------------------
# Called by Argon::Service when a client is disconnected. If this is a managed
# worker and the client being disconnected is the manager, reset manager
# tracking attributes so the registration monitor will attempt to reconnect.
#-------------------------------------------------------------------------------
sub client_disconnected {
    my ($self, $addr) = @_;
    DEBUG 'Worker: client %s disconnected', $addr;

    return unless $self->is_managed;
    return unless $self->is_registered;

    if ($addr eq $self->manager_client_addr) {
        WARN 'Lost connection to manager';
        $self->clear_manager_client_addr;
        $self->_set_is_registered(0);
    }
}

#-------------------------------------------------------------------------------
# Called by Argon::Service when new client is connected
#-------------------------------------------------------------------------------
sub client_connected {
    my ($self, $addr) = @_;
    DEBUG 'Worker: client %s connected', $addr;
}

#-------------------------------------------------------------------------------
# Perform single registration attempt with the manager.
#-------------------------------------------------------------------------------
sub register {
    my $self = shift;
    croak 'Cannot register in standalone mode' unless $self->is_managed;
    INFO 'Attempting registration with manager (%s)', $self->manager;

    $self->_set_is_registered(0);

    # Connect to manager
    my ($mgr_host, $mgr_port) = split ':', $self->manager;
    my $stream = eval { Argon::Stream->connect($mgr_host, $mgr_port) };

    if ($@) {
        ERROR 'Error connecting to manager: %s', $@;
        return 0;
    } else {
        DEBUG 'Connected to manager; sending registration message';

        # Send registration message
        my $msg = Argon::Message->new(
            cmd     => $CMD_REGISTER,
            key     => $self->key,
            payload => {
                host     => $self->host,
                port     => $self->port,
                capacity => $self->capacity,
            },
        );

        $stream->write($msg);

        # Manager will connect as a client here before returning a reply
        my $reply = $stream->read;

        # Evaluate results
        if ($reply->cmd == $CMD_ACK) {
            INFO 'Registered with manager (%s from %s)', $self->manager, $reply->payload->{client_addr};
            $self->_set_is_registered(1);
            $self->_set_manager_client_addr($reply->payload->{client_addr});
            return 1;
        } else {
            ERROR 'Error registering with manager (%s): %s', $self->manager, $reply->payload;
            croak sprintf('Error registering with manager (%s): %s', $self->manager, $reply->payload);
        }
    }
}

#-------------------------------------------------------------------------------
# Timer that checks whether a managed worker is connected and reconnects as
# needed. The time between attempts increases logarithmically until a
# connection is made, at which point it is reset.
#-------------------------------------------------------------------------------
sub register_loop {
    my $self  = shift;
    my $sleep = $Argon::POLL_INTERVAL;

    while (1) {
        DEBUG 'Checking registration with manager';

        # Attempt to register until manager connects back
        if ($self->is_registered) {
            DEBUG 'Already registered';
            Coro::AnyEvent::sleep $sleep;
        } else {
            if ($self->register) {
                DEBUG 'Registration successful';
                # Reset sleep timer after successful registration.
                $sleep = $Argon::POLL_INTERVAL;
                Coro::AnyEvent::sleep $sleep;
            } else {
                DEBUG 'Failed to register; will try again in %f seconds', $sleep;
                Coro::AnyEvent::sleep $sleep;
                $sleep += log(max(2, $sleep)) / log(10);
            }
        }
    }
}

#-------------------------------------------------------------------------------
# Handler for CMD_PING
#-------------------------------------------------------------------------------
sub cmd_ping {
    my ($self, $msg, $addr) = @_;
    return $msg->reply(cmd => $CMD_ACK);
}

#-------------------------------------------------------------------------------
# Handler for CMD_QUEUE. Shunts msgs to the process pool and returns the
# results.
#-------------------------------------------------------------------------------
sub cmd_queue {
    my ($self, $msg, $addr) = @_;

    # Ignore non-manager connections in managed mode.
    if ($self->is_managed && ($msg->key ne $self->key)) {
        return $msg->reply(
            cmd     => $CMD_ERROR,
            payload => 'Cannot accept tasks from arbitrary sources in managed mode.',
        );
    }

    my $result = eval { $self->pool->process(@{$msg->payload}) };
    return $@ ? $msg->reply(cmd => $CMD_ERROR,    payload => $@)
              : $msg->reply(cmd => $CMD_COMPLETE, payload => $result);
}

1;
