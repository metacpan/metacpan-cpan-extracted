#!/usr/bin/env perl
# Guards: scope-based auto-release for all locking primitives
#
# Guards prevent resource leaks from exceptions and early returns.
# The lock is released when the guard goes out of scope — always.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

# ---- Semaphore guard ----
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 3);
    printf "sem: value=%d\n", $sem->value;

    {
        my $g = $sem->acquire_guard;
        printf "  inside guard: value=%d\n", $sem->value;
    }
    printf "  after guard:  value=%d\n", $sem->value;

    # Multi-permit guard
    {
        my $g = $sem->acquire_guard(2);
        printf "  guard(2): value=%d\n", $sem->value;
    }
    printf "  released:  value=%d\n\n", $sem->value;
}

# ---- RWLock guard ----
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);

    {
        my $g = $rw->rdlock_guard;
        printf "rw: rdlock_guard held, state=%s\n", $rw->stats->{state};
    }
    printf "rw: after rdlock_guard, state=%s\n", $rw->stats->{state};

    {
        my $g = $rw->wrlock_guard;
        printf "rw: wrlock_guard held, state=%s\n", $rw->stats->{state};
    }
    printf "rw: after wrlock_guard, state=%s\n\n", $rw->stats->{state};
}

# ---- Condvar guard ----
{
    my $cv = Data::Sync::Shared::Condvar->new(undef);

    {
        my $g = $cv->lock_guard;
        print "cv: lock_guard held\n";
    }
    # Prove it unlocked by locking again
    $cv->lock;
    $cv->unlock;
    print "cv: lock_guard released correctly\n\n";
}

# ---- Exception safety ----
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 5);

    for my $i (1..5) {
        eval {
            my $g = $sem->acquire_guard;
            die "oops on iteration $i" if $i % 2 == 0;
        };
    }
    printf "exception safety: value=%d (expected 5)\n\n", $sem->value;
}

# ---- Guard with timeout (returns undef on failure) ----
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 1, 0);
    my $g = $sem->acquire_guard(1, 0);  # non-blocking, should fail
    printf "guard timeout: got %s (expected undef)\n",
        defined $g ? 'guard' : 'undef';
}
