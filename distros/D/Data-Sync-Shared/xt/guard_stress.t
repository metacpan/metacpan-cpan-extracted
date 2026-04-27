use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::Sync::Shared;

my $CYCLES  = $ENV{STRESS_CYCLES} || 10_000;
my $WORKERS = $ENV{STRESS_WORKERS} || 4;

# ============================================================
# 1. Semaphore acquire_guard: rapid create/destroy
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 10);
    for (1..$CYCLES) {
        my $g = $sem->acquire_guard;
    }
    is $sem->value, 10, "sem guard: value intact after $CYCLES cycles";
}

# ============================================================
# 2. Semaphore acquire_guard(N): multi-permit guard cycles
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 100);
    for (1..$CYCLES) {
        my $g = $sem->acquire_guard(3);
    }
    is $sem->value, 100, "sem guard(3): value intact after $CYCLES cycles";
}

# ============================================================
# 3. Semaphore guard under fork contention
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 4);
    my $per = int($CYCLES / $WORKERS);

    my @pids;
    for (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..$per) {
                my $g = $sem->acquire_guard;
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for (@pids) { waitpid($_, 0); $ok = 0 if $? }

    ok $ok, "sem guard fork: $WORKERS workers x $per cycles";
    is $sem->value, 4, "sem guard fork: value == max after contention";
}

# ============================================================
# 4. RWLock rdlock_guard: rapid create/destroy
# ============================================================
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    for (1..$CYCLES) {
        my $g = $rw->rdlock_guard;
    }
    my $s = $rw->stats;
    is $s->{state}, 'unlocked', "rdlock_guard: unlocked after $CYCLES cycles";
}

# ============================================================
# 5. RWLock wrlock_guard: rapid create/destroy
# ============================================================
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    for (1..$CYCLES) {
        my $g = $rw->wrlock_guard;
    }
    my $s = $rw->stats;
    is $s->{state}, 'unlocked', "wrlock_guard: unlocked after $CYCLES cycles";
}

# ============================================================
# 6. RWLock guard under fork contention (mixed rd/wr)
# ============================================================
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    my $per = int($CYCLES / $WORKERS);

    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for my $i (1..$per) {
                if ($i % 5 == 0) {
                    my $g = $rw->wrlock_guard;
                } else {
                    my $g = $rw->rdlock_guard;
                }
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for (@pids) { waitpid($_, 0); $ok = 0 if $? }

    ok $ok, "rwlock guard fork: $WORKERS workers x $per mixed cycles";
    my $s = $rw->stats;
    is $s->{state}, 'unlocked', "rwlock guard fork: unlocked after contention";
}

# ============================================================
# 7. Condvar lock_guard: rapid create/destroy
# ============================================================
{
    my $cv = Data::Sync::Shared::Condvar->new(undef);
    for (1..$CYCLES) {
        my $g = $cv->lock_guard;
    }
    ok 1, "condvar lock_guard: survived $CYCLES cycles";
    # verify not deadlocked
    $cv->lock;
    $cv->unlock;
    ok 1, "condvar lock_guard: lock still acquirable";
}

# ============================================================
# 8. Guard exception safety: die inside guarded scope
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 5);
    for (1..1000) {
        eval {
            my $g = $sem->acquire_guard;
            die "boom" if $_ % 3 == 0;
        };
    }
    is $sem->value, 5, "sem guard exception: value intact after 1000 die cycles";

    my $rw = Data::Sync::Shared::RWLock->new(undef);
    for (1..1000) {
        eval {
            my $g = $rw->wrlock_guard;
            die "boom" if $_ % 3 == 0;
        };
    }
    my $s = $rw->stats;
    is $s->{state}, 'unlocked', "rwlock guard exception: unlocked after 1000 die cycles";
}

# ============================================================
# 9. Nested guards
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 10);
    {
        my $g1 = $sem->acquire_guard(3);
        is $sem->value, 7, 'nested guard: outer took 3';
        {
            my $g2 = $sem->acquire_guard(2);
            is $sem->value, 5, 'nested guard: inner took 2';
        }
        is $sem->value, 7, 'nested guard: inner released 2';
    }
    is $sem->value, 10, 'nested guard: outer released 3';
}

done_testing;
