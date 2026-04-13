package Data::Sync::Shared;
use strict;
use warnings;
our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Data::Sync::Shared', $VERSION);

# Guard objects — auto-release on scope exit

package Data::Sync::Shared::RWLock::Guard {
    sub DESTROY {
        my $self = shift;
        $self->[0]->${\$self->[1]} if $self->[0];
    }
}

sub Data::Sync::Shared::RWLock::rdlock_guard {
    my $self = shift;
    $self->rdlock(@_);
    bless [$self, 'rdunlock'], 'Data::Sync::Shared::RWLock::Guard';
}

sub Data::Sync::Shared::RWLock::wrlock_guard {
    my $self = shift;
    $self->wrlock(@_);
    bless [$self, 'wrunlock'], 'Data::Sync::Shared::RWLock::Guard';
}

package Data::Sync::Shared::Condvar::Guard {
    sub DESTROY {
        my $self = shift;
        $self->[0]->unlock if $self->[0];
    }
}

sub Data::Sync::Shared::Condvar::lock_guard {
    my $self = shift;
    $self->lock;
    bless [$self], 'Data::Sync::Shared::Condvar::Guard';
}

# Condvar wait_while — loop until predicate returns false

sub Data::Sync::Shared::Condvar::wait_while {
    my ($self, $pred, $timeout) = @_;
    $timeout //= -1;
    return $pred->() ? 0 : 1 if $timeout == 0;
    my $deadline;
    if ($timeout > 0) {
        require Time::HiRes;
        $deadline = Time::HiRes::time() + $timeout;
    }
    while ($pred->()) {
        if (defined $deadline) {
            require Time::HiRes;
            my $remaining = $deadline - Time::HiRes::time();
            return 0 if $remaining <= 0;
            $self->wait($remaining) or return 0;
        } else {
            $self->wait;
        }
    }
    return 1;
}

# Semaphore guard

sub Data::Sync::Shared::Semaphore::acquire_guard {
    my ($self, $n, $timeout) = @_;
    $n //= 1;
    if ($n == 1) {
        $self->acquire($timeout // -1) or return undef;
    } else {
        $self->acquire_n($n, $timeout // -1) or return undef;
    }
    bless [$self, $n], 'Data::Sync::Shared::Semaphore::Guard';
}

package Data::Sync::Shared::Semaphore::Guard {
    sub DESTROY {
        my $self = shift;
        $self->[0]->release($self->[1]);
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Data::Sync::Shared - Shared-memory synchronization primitives for Linux

=head1 SYNOPSIS

    use Data::Sync::Shared;

    # Semaphore — bounded counter for resource limiting
    my $sem = Data::Sync::Shared::Semaphore->new('/tmp/sem.shm', 4);
    $sem->acquire;            # block until available
    $sem->acquire(1.5);       # with timeout
    $sem->try_acquire;        # non-blocking
    $sem->acquire_n(3);       # acquire N permits atomically
    $sem->release;
    $sem->release(2);         # release N permits
    my $n = $sem->drain;      # acquire all, return count
    {
        my $g = $sem->acquire_guard;   # auto-release on scope exit
    }

    # Barrier — N processes rendezvous
    my $bar = Data::Sync::Shared::Barrier->new('/tmp/bar.shm', 3);
    my $leader = $bar->wait;       # block until all 3 arrive
    my $leader = $bar->wait(5.0);  # with timeout (-1=timeout)

    # RWLock — reader-writer lock
    my $rw = Data::Sync::Shared::RWLock->new('/tmp/rw.shm');
    $rw->rdlock;  $rw->rdunlock;
    $rw->wrlock;  $rw->wrunlock;
    $rw->try_rdlock;  $rw->try_wrlock;
    $rw->downgrade;                # wrlock -> rdlock atomically
    {
        my $g = $rw->wrlock_guard;  # auto-release on scope exit
    }

    # Condvar — condition variable with built-in mutex
    my $cv = Data::Sync::Shared::Condvar->new('/tmp/cv.shm');
    $cv->lock;
    $cv->try_lock;       # non-blocking
    $cv->wait;           # atomically unlock + wait + re-lock
    $cv->wait(2.0);      # with timeout
    $cv->signal;         # wake one waiter
    $cv->broadcast;      # wake all waiters
    $cv->wait_while(sub { !$ready }, 5.0);  # predicate loop
    $cv->unlock;

    # Once — one-time initialization gate
    my $once = Data::Sync::Shared::Once->new('/tmp/once.shm');
    if ($once->enter) {          # or enter($timeout)
        do_init();
        $once->done;
    }

    # All primitives support anonymous (fork-inherited) mode:
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 4);

    # And memfd mode (fd-passable):
    my $sem = Data::Sync::Shared::Semaphore->new_memfd("my_sem", 4);
    my $fd = $sem->memfd;

=head1 DESCRIPTION

Data::Sync::Shared provides five cross-process synchronization primitives
stored in file-backed shared memory (C<mmap(MAP_SHARED)>), using Linux
futex for efficient blocking.

B<Linux-only>. Requires 64-bit Perl.

=head2 Primitives

=over

=item L<Data::Sync::Shared::Semaphore> - bounded counter

CAS-based counting semaphore. C<acquire> decrements (blocks at 0),
C<release> increments (capped at max). Useful for cross-process resource
limiting (connection pools, worker slots).

=item L<Data::Sync::Shared::Barrier> - rendezvous point

N processes call C<wait>; all block until the last one arrives, then all
proceed. Returns true for one "leader" process. Generation counter tracks
how many times the barrier has tripped.

=item L<Data::Sync::Shared::RWLock> - reader-writer lock

Multiple concurrent readers or one exclusive writer. Readers use
C<rdlock>/C<rdunlock>, writers use C<wrlock>/C<wrunlock>. Non-blocking
C<try_rdlock>/C<try_wrlock> variants available.

=item L<Data::Sync::Shared::Condvar> - condition variable

Includes a built-in mutex. C<lock>/C<unlock> protect the predicate.
C<wait> atomically releases the mutex and sleeps; on wakeup it
re-acquires the mutex. C<signal> wakes one waiter, C<broadcast> wakes all.

=item L<Data::Sync::Shared::Once> - one-time init gate

C<enter> returns true for exactly one process (the initializer); all
others block until C<done> is called. If the initializer dies, waiters
detect the stale PID and a new initializer is elected.

=back

=head2 Features

=over

=item * File-backed mmap for cross-process sharing

=item * Futex-based blocking (no busy-spin, no pthread)

=item * PID-based stale lock recovery (dead process detection)

=item * Anonymous and memfd modes

=item * Timeouts on all blocking operations

=item * eventfd integration for event-loop wakeup

=back

=head2 Crash Safety

All primitives encode the holder's PID in the lock word. If a process
dies while holding a lock, other processes detect the stale lock within
2 seconds via C<kill(pid, 0)> and automatically recover.

=head2 Security

The shared memory region (mmap) is writable by all processes that open
it. A malicious process with write access to the backing file or memfd
can corrupt header fields (lock words, counters, parameters) and cause
other processes to deadlock, spin, or behave incorrectly. Do not share
backing files with untrusted processes. Use anonymous mode or memfd
with restricted fd passing for isolation.

=head2 Guard Objects

All locking primitives provide scope-based guards that auto-release
on scope exit (including exceptions):

    {
        my $g = $rw->rdlock_guard;
        # ... read operations ...
    }  # rdunlock called automatically

    {
        my $g = $sem->acquire_guard(3);  # acquire 3 permits
        # ... use resource ...
    }  # release(3) called automatically

    {
        my $g = $cv->lock_guard;
        $cv->wait_while(sub { !$ready }, 5.0);
    }  # unlock called automatically

=head1 PRIMITIVES

=head2 Data::Sync::Shared::Semaphore

=head3 Constructors

    my $sem = Data::Sync::Shared::Semaphore->new($path, $max);
    my $sem = Data::Sync::Shared::Semaphore->new($path, $max, $initial);
    my $sem = Data::Sync::Shared::Semaphore->new(undef, $max);
    my $sem = Data::Sync::Shared::Semaphore->new_memfd($name, $max);
    my $sem = Data::Sync::Shared::Semaphore->new_memfd($name, $max, $initial);
    my $sem = Data::Sync::Shared::Semaphore->new_from_fd($fd);

C<$max> is the maximum permit count. C<$initial> defaults to C<$max>
(fully available); set to 0 to start with no available permits.

=head3 Operations

    my $ok  = $sem->acquire;              # block until available (infinite)
    my $ok  = $sem->acquire($timeout);    # block with timeout (seconds)
    my $ok  = $sem->try_acquire;          # non-blocking, false if unavailable
    my $ok  = $sem->acquire_n($n);        # acquire N permits atomically
    my $ok  = $sem->acquire_n($n, $timeout);
    my $ok  = $sem->try_acquire_n($n);    # non-blocking N-permit acquire
    $sem->release;                        # release one permit
    $sem->release($n);                    # release N permits (clamped at max)
    my $n   = $sem->drain;               # acquire all available, return count
    my $val = $sem->value;                # current available count
    my $max = $sem->max;                  # maximum permits

=head3 Guard

    my $g = $sem->acquire_guard;          # acquire 1, release on scope exit
    my $g = $sem->acquire_guard($n);      # acquire N
    my $g = $sem->acquire_guard($n, $timeout);  # with timeout, undef on fail

=head2 Data::Sync::Shared::Barrier

=head3 Constructors

    my $bar = Data::Sync::Shared::Barrier->new($path, $parties);
    my $bar = Data::Sync::Shared::Barrier->new(undef, $parties);
    my $bar = Data::Sync::Shared::Barrier->new_memfd($name, $parties);
    my $bar = Data::Sync::Shared::Barrier->new_from_fd($fd);

C<$parties> must be >= 2.

=head3 Operations

    my $r = $bar->wait;           # block until all parties arrive
    my $r = $bar->wait($timeout); # with timeout

Returns: 1 = leader (last to arrive), 0 = non-leader, -1 = timeout.
On timeout, the barrier is broken (reset to 0 arrived, generation
bumped) and all other waiting parties are released.

    my $gen = $bar->generation;    # how many times barrier has tripped
    my $n   = $bar->arrived;       # currently arrived count
    my $n   = $bar->parties;       # party count
    $bar->reset;                   # force-reset barrier state

=head2 Data::Sync::Shared::RWLock

=head3 Constructors

    my $rw = Data::Sync::Shared::RWLock->new($path);
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    my $rw = Data::Sync::Shared::RWLock->new_memfd($name);
    my $rw = Data::Sync::Shared::RWLock->new_from_fd($fd);

=head3 Operations

    $rw->rdlock;                   # block until read lock acquired
    $rw->rdlock($timeout);         # with timeout (croaks on timeout)
    $rw->wrlock;                   # block until write lock acquired
    $rw->wrlock($timeout);         # with timeout (croaks on timeout)
    my $ok = $rw->try_rdlock;      # non-blocking
    my $ok = $rw->try_wrlock;      # non-blocking
    my $ok = $rw->rdlock_timed($timeout);  # returns false on timeout
    my $ok = $rw->wrlock_timed($timeout);  # returns false on timeout
    $rw->rdunlock;
    $rw->wrunlock;
    $rw->downgrade;                # convert wrlock to rdlock atomically

=head3 Guards

    my $g = $rw->rdlock_guard;             # rdunlock on scope exit
    my $g = $rw->rdlock_guard($timeout);   # with timeout (croaks on fail)
    my $g = $rw->wrlock_guard;
    my $g = $rw->wrlock_guard($timeout);

=head2 Data::Sync::Shared::Condvar

=head3 Constructors

    my $cv = Data::Sync::Shared::Condvar->new($path);
    my $cv = Data::Sync::Shared::Condvar->new(undef);
    my $cv = Data::Sync::Shared::Condvar->new_memfd($name);
    my $cv = Data::Sync::Shared::Condvar->new_from_fd($fd);

=head3 Operations

    $cv->lock;                     # acquire built-in mutex
    $cv->unlock;                   # release built-in mutex
    my $ok = $cv->try_lock;        # non-blocking

    my $ok = $cv->wait;            # unlock, wait for signal, re-lock
    my $ok = $cv->wait($timeout);  # with timeout
    $cv->signal;                   # wake one waiter
    $cv->broadcast;                # wake all waiters

    my $ok = $cv->wait_while(\&pred);           # loop until pred returns false
    my $ok = $cv->wait_while(\&pred, $timeout); # with timeout

C<wait> must be called while holding the mutex. Returns 1 on
signal/broadcast, 0 on timeout. The mutex is always re-acquired
before C<wait> returns.

C<wait_while> calls C<wait> in a loop until the predicate coderef
returns false. Returns 1 if predicate became false, 0 on timeout.

=head3 Guard

    my $g = $cv->lock_guard;       # unlock on scope exit

=head2 Data::Sync::Shared::Once

=head3 Constructors

    my $once = Data::Sync::Shared::Once->new($path);
    my $once = Data::Sync::Shared::Once->new(undef);
    my $once = Data::Sync::Shared::Once->new_memfd($name);
    my $once = Data::Sync::Shared::Once->new_from_fd($fd);

=head3 Operations

    my $init = $once->enter;             # try + wait, infinite
    my $init = $once->enter($timeout);   # with timeout
    $once->done;                         # mark initialization complete
    my $ok  = $once->is_done;            # check without blocking
    $once->reset;                        # reset to uninitialized state

C<enter> returns true for exactly one process (the initializer).
All others block until C<done> is called, then return false.
If the initializer dies, stale PID detection elects a new one.

=head2 Common Methods

All primitives support:

    my $p  = $obj->path;           # backing file path (undef if anon)
    my $fd = $obj->memfd;          # memfd fd (-1 if file-backed/anon)
    $obj->sync;                    # msync — flush to disk
    $obj->unlink;                  # remove backing file
    Class->unlink($path);          # class method form
    my $s  = $obj->stats;          # diagnostic hashref

Stats keys vary by type. All counters are approximate under concurrency.

B<Semaphore:> C<value>, C<max>, C<waiters>, C<mmap_size>, C<acquires>,
C<releases>, C<waits>, C<timeouts>, C<recoveries>.

B<Barrier:> C<parties>, C<arrived>, C<generation>, C<waiters>,
C<mmap_size>, C<waits>, C<releases>, C<timeouts>.

B<RWLock:> C<state> (C<"unlocked">, C<"read_locked">, C<"write_locked">),
C<readers>, C<waiters>, C<mmap_size>, C<acquires>, C<releases>,
C<recoveries>.

B<Condvar:> C<waiters>, C<signals>, C<mmap_size>, C<acquires>,
C<releases>, C<waits>, C<timeouts>, C<recoveries>.

B<Once:> C<state> (C<"init">, C<"running">, C<"done">), C<is_done>,
C<waiters>, C<mmap_size>, C<acquires>, C<releases>, C<waits>,
C<timeouts>, C<recoveries>.

=head3 eventfd Integration

    my $fd = $obj->eventfd;        # create eventfd, returns fd
    $obj->eventfd_set($fd);        # use existing fd (e.g. from fork)
    my $fd = $obj->fileno;         # current eventfd (-1 if none)
    $obj->notify;                  # signal eventfd
    my $n  = $obj->eventfd_consume;  # drain notification counter

Notification is opt-in. Use with L<EV> or other event loops.

=head1 SEE ALSO

L<Data::Buffer::Shared> - typed shared array

L<Data::HashMap::Shared> - concurrent hash table

L<Data::Queue::Shared> - FIFO queue

L<Data::PubSub::Shared> - publish-subscribe ring

L<Data::ReqRep::Shared> - request-reply

L<Data::Pool::Shared> - fixed-size object pool

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Log::Shared> - append-only log (WAL)

L<Data::Heap::Shared> - priority queue

L<Data::Graph::Shared> - directed weighted graph

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
