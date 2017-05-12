package Coro::ProcessPool::Pipeline;

=head1 NAME

Coro::ProcessPool::Pipeline

=head1 SYNOPSIS

    my $pool = Coro::ProcesPool->new();
    my $pipe = $pool->pipeline;

    # Start producer thread to queue tasks
    my $producer = async {
        while (my $task = get_next_task()) {
            $pipe->queue('Some::TaskClass', $task);
        }

        # Let the pipeline know no more tasks are coming
        $pipe->shutdown;
    };

    # Collect the results of each task as they are received
    while (my $result = $pipe->next) {
        do_stuff_with($result);
    }

=head1 DESCRIPTION

Provides an iterative mechanism for feeding tasks into the process pool and
collecting results. A pool may have multiple pipelines.

=cut

use Moo;
use Types::Standard qw(-types);
use Carp;
use Coro;
use Coro::AnyEvent;
use Coro::Channel;

=head1 ATTRIBUTES

=head2 pool (required)

The L<Coro::ProcessPool> in which to queue tasks.

=cut

has pool => (
    is       => 'ro',
    isa      => InstanceOf['Coro::ProcessPool'],
    required => 1,
);

=head2 auto_shutdown (default: false)

When set to true, the pipeline will shut itself down as soon as the number of
pending tasks hits zero. At least one task must be sent for this to be
triggered.

=cut

has auto_shutdown => (
    is       => 'rw',
    isa      => Bool,
    default  => sub { 0 },
);

#-------------------------------------------------------------------------------
# Internal flag to signal that no more tasks should be accepted.
#-------------------------------------------------------------------------------
has shutting_down => (
    is       => 'rw',
    isa      => Bool,
    init_arg => undef,
    default  => sub { 0 },
);

#-------------------------------------------------------------------------------
# Internal flag to mark the pipeline has having been shut down.
#-------------------------------------------------------------------------------
has is_shutdown => (
    is       => 'rw',
    isa      => Bool,
    init_arg => undef,
    default  => sub { 0 },
);

#-------------------------------------------------------------------------------
# In tandem with shutting_down and auto_shutdown, determines when it is
# appropriate to automatically shutdown the queue.
#-------------------------------------------------------------------------------
has num_pending => (
    is       => 'rw',
    isa      => Int,
    init_arg => undef,
    default  => sub { 0 },
);

#-------------------------------------------------------------------------------
# Stores complete results and provides the 'next' method.
#-------------------------------------------------------------------------------
has complete => (
    is       => 'ro',
    isa      => InstanceOf['Coro::Channel'],
    init_arg => undef,
    default  => sub { Coro::Channel->new() },
);

=head1 METHODS

=head2 next

Cedes control until a previously queued task is complete and the result is
available.

=cut

sub next {
    my $self = shift;
    my $finished = $self->complete->get or return;
    my ($result, $error) = @$finished;
    if ($error) {
        croak $error;
    } else {
        return $result;
    }
}

=head2 queue($task, $args)

Queues a new task. Arguments are identical to L<Coro::ProcessPool::process> and
L<Coro::ProcessPool::defer>.

=cut

sub queue {
    my ($self, @args) = @_;
    croak 'pipeline is shut down' if $self->is_shutdown;
    croak 'pipeline is shutting down' if $self->shutting_down;

    unless ($self->pool->is_running) {
        unless ($self->is_shutdown || $self->shutting_down) {
            $self->shutdown;
        }

        croak 'pool is not running';
    }

    my $deferred = $self->pool->defer(@args);

    async_pool {
        my ($self, $deferred) = @_;
        my $result = eval { $deferred->() };

        $self->complete->put([$result, $@]);
        --$self->{num_pending};

        if ($self->num_pending == 0) {
            if ($self->shutting_down || $self->auto_shutdown) {
                $self->complete->shutdown;
                $self->is_shutdown(1);
                $self->shutting_down(0);
            }
        }
    } $self, $deferred;

    ++$self->{num_pending};
}

=head2 shutdown

Signals shutdown of the pipeline. A shutdown pipeline may not be reused.

=cut

sub shutdown {
    my $self = shift;
    $self->shutting_down(1);
}

1;
