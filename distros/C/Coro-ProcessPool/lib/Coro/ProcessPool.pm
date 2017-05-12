package Coro::ProcessPool;

=head1 NAME

Coro::ProcessPool - an asynchronous process pool

=head1 SYNOPSIS

    use Coro::ProcessPool;
    use Coro;

    my $pool = Coro::ProcessPool->new(
        max_procs => 4,
        max_reqs  => 100,
        include   => ['/path/to/my/task/classes', '/path/to/other/packages'],
    );

    my $double = sub { $_[0] * 2 };

    #-----------------------------------------------------------------------
    # Process in sequence
    #-----------------------------------------------------------------------
    my %result;
    foreach my $i (1 .. 1000) {
        $result{$i} = $pool->process($double, [$i]);
    }

    #-----------------------------------------------------------------------
    # Process as a batch
    #-----------------------------------------------------------------------
    my @results = $pool->map($double, 1 .. 1000);

    #-----------------------------------------------------------------------
    # Defer waiting for result
    #-----------------------------------------------------------------------
    my %deferred = map { $_ => $pool->defer($double, [$_]) } 1 .. 1000);
    foreach my $i (keys %deferred) {
        print "$i = " . $deferred{$i}->() . "\n";
    }

    #-----------------------------------------------------------------------
    # Use a "task class", implementing 'new' and 'run'
    #-----------------------------------------------------------------------
    my $result = $pool->process('Task::Doubler', 21);

    #-----------------------------------------------------------------------
    # Pipelines (work queues)
    #-----------------------------------------------------------------------
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

    $pool->shutdown;

=head1 DESCRIPTION

Processes tasks using a pool of external Perl processes.

=cut

use Moo;
use Types::Standard qw(-types);
use Carp;
use AnyEvent;
use Guard;
use Coro;
use Coro::AnyEvent qw(sleep);
use Coro::Channel;
use Coro::ProcessPool::Process;
use Coro::ProcessPool::Util;
use Coro::Semaphore;
require Coro::ProcessPool::Pipeline;

our $VERSION = '0.26';

if ($^O eq 'MSWin32') {
    die 'MSWin32 is not supported';
}

=head1 ATTRIBUTES

=head2 max_procs

The maximum number of processes to run within the process pool. Defaults
to the number of CPUs on the ssytem.

=cut

has max_procs => (
    is      => 'ro',
    isa     => Int,
    default => sub { Coro::ProcessPool::Util::cpu_count() },
);

=head2 max_reqs

The maximum number of tasks a worker process may run before being terminated
and replaced with a fresh process. This is useful for tasks that might leak
memory over time.

=cut

has max_reqs => (
    is      => 'ro',
    isa     => Int,
    default => sub { 0 },
);

=head2 include

An optional array ref of directory paths to prepend to the set of directories
the worker process will use to find Perl packages.

=cut

has include => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
);

=head1 PRIVATE ATTRIBUTES

=head2 procs_lock

Semaphore used to control access to the worker processes. Starts incremented
to the number of processes (C<max_procs>).

=cut

has procs_lock => (
    is  => 'lazy',
    isa => InstanceOf['Coro::Semaphore'],
);

sub _build_procs_lock {
    my $self = shift;
    return Coro::Semaphore->new($self->max_procs);
}

=head2 num_procs

Running total of processes that are currently running.

=cut

has num_procs => (
    is      => 'rw',
    isa     => Int,
    default => sub { 0 },
);

=head2 procs

Array holding the L<Coro::ProcessPool::Process> objects.

=cut

has procs => (
    is      => 'ro',
    isa     => ArrayRef[InstanceOf['Coro::ProcessPool::Process']],
    default => sub { [] },
);

=head2 all_procs

=cut

has all_procs => (
    is      => 'ro',
    isa     => HashRef[InstanceOf['Coro::ProcessPool::Process']],
    default => sub { {} },
);

=head2 is_running

Boolean which signals to the instance that the C<shutdown> method has been
called.

=cut

has is_running => (
    is      => 'rw',
    isa     => Bool,
    default => sub { 1 },
);

=head1 METHODS

=cut

sub DEMOLISH {
    my $self = shift;
    if ($self->is_running) {
        $self->shutdown;
    }
}

sub BUILD {
    my $self = shift;
    for (1 .. $self->max_procs) {
        unshift @{$self->procs}, $self->start_proc;
    }
}

sub start_proc {
    my $self = shift;
    my $proc = Coro::ProcessPool::Process->new(include => $self->include);
    my $pid  = $proc->pid;
    ++$self->{num_procs};
    $self->{all_procs}{$pid} = $proc;
    return $proc;
}

sub kill_proc {
    my ($self, $proc) = @_;
    my $pid  = $proc->pid;
    $proc->shutdown;
    --$self->{num_procs};
    delete $self->{all_procs}{$pid};
}

sub checkin_proc {
    my ($self, $proc) = @_;

    unless ($self->is_running) {
      $self->kill_proc($proc);
      return;
    }

    if (!$proc->is_running) {
        my $pid = $proc->pid;
        --$self->{num_procs};
        delete $self->{all_procs}{$pid};
        unshift @{$self->procs}, $self->start_proc;
    }
    elsif ($self->max_reqs && $proc->messages_sent >= $self->max_reqs) {
        $self->kill_proc($proc);
        unshift @{$self->procs}, $self->start_proc;
    }
    else {
        unshift @{$self->procs}, $proc;
    }
}

sub checkout_proc {
    my $self = shift;
    croak 'not running' unless $self->is_running;

    my $proc;

    # Start a new process if none are available and there are worker slots open
    if ($self->capacity == 0 && $self->num_procs < $self->max_procs) {
        $proc = $self->start_proc;
    } else {
        $proc = shift @{$self->procs};
    }

    return $proc;
}

=head2 capacity

Returns the number of free worker processes.

=cut

sub capacity {
    my $self = shift;
    return scalar(@{$self->procs});
}

=head2 shutdown

Shuts down all processes and resets state on the process pool. After calling
this method, the pool is effectively in a new state and may be used normally.

=cut

sub shutdown {
    my $self = shift;

    $self->is_running(0);
    $_->shutdown(5) foreach values %{$self->{all_procs}};

    $self->{procs}      = [];
    $self->{all_proces} = {};
    $self->{num_procs}  = 0;
    $self->{procs_lock} = Coro::Semaphore->new($self->max_procs);

    return;
}

=head2 process($f, $args)

Processes code ref C<$f> in a child process from the pool. If C<$args> is
provided, it is an array ref of arguments that will be passed to C<$f>. Returns
the result of calling $f->(@$args).

Alternately, C<$f> may be the name of a class implementing the methods C<new>
and C<run>, in which case the result is equivalent to calling
$f->new(@$args)->run(). Note that the include path for worker processes is
identical to that of the calling process.

This call will yield until the results become available. If all processes are
busy, this method will block until one becomes available. Processes are spawned
as needed, up to C<max_procs>, from this method. Also note that the use of
C<max_reqs> can cause this method to yield while a new process is spawned.

=cut

sub process {
    my ($self, $f, $args) = @_;
    my $guard = $self->procs_lock->guard;
    my $proc  = $self->checkout_proc;
    scope_guard { $self->checkin_proc($proc) };

    my $msgid = $proc->send($f, $args);
    return $proc->recv($msgid);
}

=head2 map($f, @args)

Applies C<$f> to each value in C<@args> in turn and returns a list of the
results. Although the order in which each argument is processed is not
guaranteed, the results are guaranteed to be in the same order as C<@args>,
even if the result of calling C<$f> returns a list itself (in which case, the
results of that calcuation is flattened into the list returned by C<map>.

=cut

sub map {
    my ($self, $f, @args) = @_;
    my @deferred = map { $self->defer($f, [$_]) } @args;
    return map { $_->() } @deferred;
}

=head2 defer($f, $args)

Similar to L<./process>, but returns immediately. The return value is a code
reference that, when called, returns the results of calling C<$f->(@$args)>.

    my $deferred = $pool->defer($coderef, [ $x, $y, $z ]);
    my $result   = $deferred->();

=cut

sub defer {
    my $self = shift;
    my $cv   = AnyEvent->condvar;

    async_pool {
        my ($self, $cv, @args) = @_;
        my $result = eval { $self->process(@args) };
        $cv->croak($@) if $@;
        $cv->send($result);
    } $self, $cv, @_;

    return sub { $cv->recv };
}

=head2 pipeline

Returns a L<Coro::ProcessPool::Pipeline> object which can be used to pipe
requests through to the process pool. Results then come out the other end of
the pipe. It is up to the calling code to perform task account (for example, by
passing an id in as one of the arguments to the task class).

    my $pipe = $pool->pipeline;

    my $producer = async {
        foreach my $args (@tasks) {
            $pipe->queue('Some::Class', $args);
        }

        $pipe->shutdown;
    };

    while (my $result = $pipe->next) {
        ...
    }

All arguments to C<pipeline()> are passed transparently to the constructor of
L<Coro::ProcessPool::Pipeline>. There is no limit to the number of pipelines
which may be created for a pool.

If the pool is shutdown while the pipeline is active, any tasks pending in
L<Coro::ProcessPool::Pipeline::next> will fail and cause the next call to
C<next()> to croak.

=cut

sub pipeline {
    my $self = shift;
    return Coro::ProcessPool::Pipeline->new(pool => $self, @_);
}

=head1 A NOTE ABOUT IMPORTS AND CLOSURES

Code refs are serialized using L<Storable> to pass them to the worker
processes. Once deserialized in the pool process, these functions can no
longer see the stack as it is in the parent process. Therefore, imports and
variables external to the function are unavailable.

Something like this will not work:

    use Foo;
    my $foo = Foo->new();

    my $result = $pool->process(sub {
        return $foo->bar; # $foo not found
    });

Nor will this:

    use Foo;
    my $result = $pool->process(sub {
        my $foo = Foo->new; # Foo not found
        return $foo->bar;
    });

The correct way to do this is to import from within the function:

    my $result = $pool->process(sub {
        require Foo;
        my $foo = Foo->new();
        return $foo->bar;
    });

...or to pass in external variables that are needed by the function:

    use Foo;
    my $foo = Foo->new();

    my $result = $pool->process(sub { $_[0]->bar }, [ $foo ]);

=head2 Use versus require

The C<use> pragma is run a compile time, whereas C<require> is evaluated at
runtime. Because of this, the use of C<use> in code passed directly to the
C<process> method can fail because the C<use> statement has already been
evaluated when the calling code was compiled.

This will not work:

    $pool->process(sub {
        use Foo;
        my $foo = Foo->new();
    });

This will work:

    $pool->process(sub {
        require Foo;
        my $foo = Foo->new();
    });

If C<use> is necessary (for example, to import a method or transform the
calling code via import), it is recommended to move the code into its own
module, which can then be called in the anonymous routine:

    package Bar;

    use Foo;

    sub dostuff {
        ...
    }

Then, in your caller:

    $pool->process(sub {
        require Bar;
        Bar::dostuff();
    });

=head2 If it's a problem...

Use the task class method if the loading requirements are causing headaches:

    my $result = $pool->process('Task::Class', [@args]);

=head1 COMPATIBILITY

C<Coro::ProcessPool> will likely break on Win32 due to missing support for
non-blocking file descriptors (Win32 can only call C<select> and C<poll> on
actual network sockets). Without rewriting this as a network server, which
would impact performance and be really annoying, it is likely this module will
not support Win32 in the near future.

The following modules will get you started if you wish to explore a synchronous
process pool on Windows:

=over

=item L<Win32::Process>

=item L<Win32::IPC>

=item L<Win32::Pipe>

=back

=head1 AUTHOR

Jeff Ober <jeffober@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015, Jeff Ober.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
