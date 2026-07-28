#!/usr/bin/perl
# Regression: a guard object inherited by fork() must NOT release the parent's
# lock when the child exits.
#
# The child gets its own copy of the blessed guard. On a normal exit Perl's
# global destruction runs that copy's DESTROY, which used to call
# rdunlock/wrunlock/unlock/release on a lock the PARENT still holds -- breaking
# mutual exclusion for every other process, or pushing a semaphore's count above
# what is really free. Each guard now records the PID that took the lock and
# releases only from that process.
#
# NOTE: the child must exit NORMALLY. POSIX::_exit skips global destruction, so
# the guard's DESTROY never runs and the test would pass vacuously.
use strict;
use warnings;
use Test::More;
use Config;
use Data::Sync::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# --- RWLock: a forked child must not drop the parent's write lock ---
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    my $g  = $rw->wrlock_guard;

    my $pid = fork // plan skip_all => "fork failed: $!";
    unless ($pid) { exit 0 }          # normal exit => global destruction
    waitpid($pid, 0);

    # A third process must still be unable to take the write lock.
    my $probe = fork // plan skip_all => "fork failed: $!";
    unless ($probe) { my $got = $rw->try_wrlock; exit($got ? 1 : 0) }
    waitpid($probe, 0);
    is $? >> 8, 0, 'RWLock: child exit does not release the parent write lock';
}

# --- Condvar: a forked child must not drop the parent's mutex ---
{
    my $cv = Data::Sync::Shared::Condvar->new(undef);
    my $g  = $cv->lock_guard;

    my $pid = fork // plan skip_all => "fork failed: $!";
    unless ($pid) { exit 0 }
    waitpid($pid, 0);

    my $probe = fork // plan skip_all => "fork failed: $!";
    unless ($probe) { my $got = $cv->try_lock; exit($got ? 1 : 0) }
    waitpid($probe, 0);
    is $? >> 8, 0, 'Condvar: child exit does not release the parent mutex';
}

# --- Semaphore: a forked child must not release permits it never acquired ---
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 4);
    {
        my $g = $sem->acquire_guard(2);      # parent holds 2 of 4

        my $pid = fork // plan skip_all => "fork failed: $!";
        unless ($pid) { exit 0 }
        waitpid($pid, 0);

        # 2 permits are held by the parent, so at most 2 remain available.
        my $probe = fork // plan skip_all => "fork failed: $!";
        unless ($probe) { my $n = $sem->drain; exit($n > 2 ? 1 : 0) }
        waitpid($probe, 0);
        is $? >> 8, 0, 'Semaphore: child exit does not over-release permits';
    }
}

done_testing;
