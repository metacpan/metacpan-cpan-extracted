package Argon::Manager;

use Moo;
use MooX::HandlesVia;
use Types::Standard qw(-types);
use Const::Fast;
use Coro;
use Coro::AnyEvent;
use Coro::PrioChannel;
use Coro::Semaphore;
use Guard qw(scope_guard);
use Argon::Client;
use Argon::Tracker;
use Argon::MessageTracker;
use Argon qw(K :logging :commands);

#-------------------------------------------------------------------------------
# Error constants
#-------------------------------------------------------------------------------
const our $ERR_NO_WORKERS  => 'There are no registered workers.';
const our $ERR_NO_CAPACITY => 'Unable to process request. System is at max capacity.';
const our $ERR_PROC_FAIL   => 'An error occurred routing the request.';
const our $ERR_NOT_FOUND   => 'The message ID was not found.';

extends 'Argon::Dispatcher';

#-------------------------------------------------------------------------------
# Max number of unassigned tasks. Once this number is hit, tasks are rejected.
#-------------------------------------------------------------------------------
has queue_size => (
    is  => 'ro',
    isa => Maybe[Int],
);

#-------------------------------------------------------------------------------
# Priority queue for unassigned messages.
#-------------------------------------------------------------------------------
has queue => (
    is       => 'lazy',
    isa      => InstanceOf['Coro::PrioChannel'],
    init_arg => undef,
    handles  => {
      queue_put => 'put',
      queue_get => 'get',
      queue_len => 'size',
    }
);

sub _build_queue {
    my $self = shift;
    return Coro::PrioChannel->new($self->queue_size);
}

#-------------------------------------------------------------------------------
# Keeps track of message state and results.
#-------------------------------------------------------------------------------
has msg_tracker => (
    is       => 'ro',
    isa      => InstanceOf['Argon::MessageTracker'],
    init_arg => undef,
    default  => sub { Argon::MessageTracker->new() },
);

#-------------------------------------------------------------------------------
# Stores Argon::Clients for each worker. Maps them to the worker's unique key.
#-------------------------------------------------------------------------------
has workers => (
    is          => 'ro',
    isa         => Map[Str,InstanceOf['Argon::Client']],
    init_arg    => undef,
    default     => sub {{}},
    handles_via => 'Hash',
    handles     => {
        set_worker  => 'set',
        get_worker  => 'get',
        del_worker  => 'delete',
        has_worker  => 'exists',
        all_workers => 'keys',
        num_workers => 'count',
    }
);

#-------------------------------------------------------------------------------
# Stores statistics about each worker for better routing of tasks.
#-------------------------------------------------------------------------------
has tracking => (
    is          => 'ro',
    isa         => Map[Str,InstanceOf['Argon::Tracker']],
    init_arg    => undef,
    default     => sub {{}},
    handles_via => 'Hash',
    handles     => {
        set_tracking => 'set',
        get_tracking => 'get',
        del_tracking => 'delete',
    }
);

#-------------------------------------------------------------------------------
# Tracks the current capacity of the system.
#-------------------------------------------------------------------------------
has sem_capacity => (
    is       => 'ro',
    isa      => InstanceOf['Coro::Semaphore'],
    init_arg => undef,
    default  => sub { Coro::Semaphore->new(0) },
    handles  => {
        current_capacity => 'count',
    }
);

#-------------------------------------------------------------------------------
# Total capacity of the system. Subroutines inc_capacity and dec_capacity allow
# adjustment of this value.
#-------------------------------------------------------------------------------
has capacity => (
    is       => 'ro',
    isa      => Int,
    init_arg => undef,
    default  => 0,
);

sub inc_capacity {
    my ($self, $amount) = @_;
    $amount ||= 1;
    $self->{capacity} += $amount;
}

sub dec_capacity {
    my ($self, $amount) = @_;
    $amount ||= 1;
    $self->{capacity} -= $amount;
}

#-------------------------------------------------------------------------------
# Timer loop that routes tasks to workers as messages become available from the
# queue and as workers have capacity to handle tasks.
#-------------------------------------------------------------------------------
has watcher => (
    is       => 'lazy',
    isa      => InstanceOf['Coro'],
    init_arg => undef,
);

sub _build_watcher {
    my $self = shift;
    return async { $self->process_pending while $self->is_running };
}

#-------------------------------------------------------------------------------
# Set to true when running
#-------------------------------------------------------------------------------
has is_running => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

#-------------------------------------------------------------------------------
# If set, this code ref is called when the Manager is started and has at least
# one registered worker. This is mostly useful when writing something that must
# return after the manager has started and is ready to accept tasks (like a
# test - see t/08-client.t).
#-------------------------------------------------------------------------------
has on_ready => (
    is      => 'ro',
    isa     => CodeRef,
);

#-------------------------------------------------------------------------------
# True if there is available capacity for handling tasks or if the queue is not
# at its maximum value.
#-------------------------------------------------------------------------------
sub has_capacity {
    my $self = shift;
    return if $self->current_capacity == 0;
    return if $self->queue_size && $self->queue_len >= $self->queue_size;
    return 1;
}

#-------------------------------------------------------------------------------
# Configures dispatcher and watcher thread when Argon::Service is started.
#-------------------------------------------------------------------------------
after init => sub {
    my $self = shift;
    $self->is_running(1);

    # Register handlers
    $self->respond_to($CMD_REGISTER, K('cmd_register', $self));
    $self->respond_to($CMD_QUEUE,    K('cmd_queue',    $self));
    $self->respond_to($CMD_COLLECT,  K('cmd_collect',  $self));
    $self->respond_to($CMD_STATUS,   K('cmd_status',   $self));

    # Start services
    $self->watcher;
};

#-------------------------------------------------------------------------------
# Turns of is_running when shutting down so that service threads know to stop.
#-------------------------------------------------------------------------------
before shutdown => sub {
    my $self = shift;
    $self->is_running(0);
};

#-------------------------------------------------------------------------------
# Deregisters a worker by key name and removes its capacity from the pool. Also
# destroys its tracking data.
#-------------------------------------------------------------------------------
sub deregister {
    my ($self, $worker) = @_;
    if ($self->has_worker($worker)) {
        my $lost_capacity = $self->get_tracking($worker)->workers;
        $self->dec_capacity($lost_capacity);
        $self->sem_capacity->adjust(-$lost_capacity);
        $self->del_worker($worker);
        $self->del_tracking($worker);
        WARN 'Lost connection to worker "%s"', $worker;
        DEBUG 'Capacity at %d', $self->capacity;
    }
}

#-------------------------------------------------------------------------------
# Starts a monitor thread which continuously sends CMD_PING messages to
# $worker. Started when a worker is registered.
#-------------------------------------------------------------------------------
sub start_monitor {
    my ($self, $worker) = @_;
    my $client = $self->get_worker($worker);

    async_pool {
        scope_guard { $self->deregister($worker) };

        while ($self->has_worker($worker)) {
            DEBUG 'Sending ping';
            my $msg = Argon::Message->new(cmd => $CMD_PING);
            my $reply = $client->send($msg) or last;

            if ($reply->cmd == $CMD_ACK) {
                Coro::AnyEvent::sleep $Argon::POLL_INTERVAL;
            } else {
                WARN 'Worker monitor detected a problem: %s', $reply->payload;
                $self->deregister($worker);
            }
        }
    };
}

#-------------------------------------------------------------------------------
# Blocks until both a worker and message are available. Once both are acquired,
# sends the task to the worker and posts the results.
#-------------------------------------------------------------------------------
sub process_pending {
    my $self = shift;

    # Get the next message
    my $msg = $self->queue_get;

    # Acquire capacity slot
    $self->sem_capacity->down;

    async_pool {
        my $msg = shift;

        # Release capacity slot once complete
        scope_guard { $self->sem_capacity->up };

        # Get the next available worker
        my $cmp = sub { $self->get_tracking($_[0])->est_proc_time };
        my @workers =
            sort { $cmp->($a) <=> $cmp->($b) }
            grep { $self->get_tracking($_)->capacity > 0 }
            $self->all_workers;

        my $worker = $workers[0];

        # Execute with tracking
        $self->get_tracking($worker)->start_request($msg->id);

        scope_guard {
            # If the worker connection was lost while the request was
            # outstanding, the tracker may be missing, so completing
            # the request must account for this appropriately.
            $self->get_tracking($worker)->end_request($msg->id)
                if $self->has_worker($worker);
        };

        # Assign the task
        $msg->{key} = $worker;

        # queue this is hanging sometimes and causing delays in responses
        my $reply = eval { $self->get_worker($worker)->send($msg) };

        if ($@) {
            WARN 'Worker error (%s) - disconnecting: %s', $worker, $@;
            $self->deregister($worker);
            $reply = $msg->reply(cmd => $CMD_ERROR, payload => "$ERR_PROC_FAIL. Error message: $@");
        }

        $self->msg_tracker->complete_message($reply);
    } $msg;
}

#-------------------------------------------------------------------------------
# CMD_REGISTER handler. Registers a new worker.
#-------------------------------------------------------------------------------
sub cmd_register {
    my ($self, $msg) = @_;
    my $key      = $msg->key;
    my $host     = $msg->payload->{host};
    my $port     = $msg->payload->{port};
    my $capacity = $msg->payload->{capacity};

    # Create client
    my $client = Argon::Client->new(host => $host, port => $port);

    INFO 'Connecting to worker "%s"', $key;
    $client->connect;
    INFO 'Connected to worker "%s"', $key;

    # Create tracker
    my $tracker = Argon::Tracker->new(
        tracking => $Argon::TRACK_MESSAGES,
        workers  => $capacity,
    );

    # Store worker and worker tracking
    $self->set_worker($key, $client);
    $self->set_tracking($key, $tracker);

    # Increment capacity and release up to $capacity slots
    $self->inc_capacity($capacity);
    $self->sem_capacity->adjust($capacity);

    # Start monitor
    $self->start_monitor($key);

    DEBUG 'Capacity at %d', $self->capacity;

    # Signal that we're ready to receive requests to anyone that may be waiting
    if ($self->on_ready) {
        $self->on_ready->();
    }

    return $msg->reply(
        cmd     => $CMD_ACK,
        payload => { client_addr => $client->addr },
    );
}

#-------------------------------------------------------------------------------
# CMD_QUEUE handler. Queues a message and returns a CMD_ACK.
#-------------------------------------------------------------------------------
sub cmd_queue {
    my ($self, $msg, $addr) = @_;

    # Reject tasks when there are no workers
    return $msg->reply(cmd => $CMD_REJECTED, payload => $ERR_NO_WORKERS)
        if $self->num_workers == 0;

    # Reject tasks when there is no available capacity
    return $msg->reply(cmd => $CMD_REJECTED, payload => $ERR_NO_CAPACITY)
        unless $self->has_capacity;

    $self->msg_tracker->track_message($msg->id);
    $self->queue_put($msg);

    return $msg->reply(cmd => $CMD_ACK);
}

#-------------------------------------------------------------------------------
# CMD_COLLECT handler. Waits for the result of a previously CMD_QUEUE'd message
# to be posted and returns as a reply to the client.
#-------------------------------------------------------------------------------
sub cmd_collect {
    my ($self, $msg, $addr) = @_;

    my $msgid = $msg->payload;

    return $msg->reply(cmd => $CMD_ERROR, payload => $ERR_NOT_FOUND)
        unless $self->msg_tracker->is_tracked($msgid);

    my $result = $self->msg_tracker->collect_message($msgid);
    return $result->reply(id => $msgid);
}

#-------------------------------------------------------------------------------
# CMD_STATUS handler. Returns a hash of tracking and capacity data.
#-------------------------------------------------------------------------------
sub cmd_status {
    my ($self, $msg, $addr) = @_;
    my $msgid = $msg->payload;

    my $pending;
    foreach my $worker ($self->all_workers) {
        my $tracker = $self->get_tracking($worker);
        $pending->{$worker} = { map { $_ => $tracker->age($_) } $tracker->all_pending };
    }

    return $msg->reply(
        cmd     => $CMD_COMPLETE,
        payload => {
            workers          => $self->num_workers,
            total_capacity   => $self->capacity,
            current_capacity => $self->current_capacity,
            queue_length     => $self->queue_len,
            pending          => $pending,
        }
    );
}

1;
