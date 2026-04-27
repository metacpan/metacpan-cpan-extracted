use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Sync::Shared;

# ============================================================
# Semaphore: acquire_n / try_acquire_n
# ============================================================

{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 10);

    ok $sem->try_acquire_n(3), 'try_acquire_n(3) succeeds';
    is $sem->value, 7, 'value 7 after acquire 3';

    ok $sem->try_acquire_n(7), 'try_acquire_n(7) succeeds';
    is $sem->value, 0, 'value 0';

    ok !$sem->try_acquire_n(1), 'try_acquire_n(1) fails at 0';

    $sem->release(5);
    ok !$sem->try_acquire_n(6), 'try_acquire_n(6) fails with only 5';
    ok $sem->try_acquire_n(5), 'try_acquire_n(5) succeeds exactly';

    # try_acquire_n(0) always succeeds (no-op)
    ok $sem->try_acquire_n(0), 'try_acquire_n(0) always succeeds';

    $sem->release(10);
}

# acquire_n with timeout
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 5);
    $sem->drain;

    my $t0 = time;
    ok !$sem->acquire_n(3, 0.1), 'acquire_n timeout returns false';
    cmp_ok time - $t0, '<', 30, 'acquire_n returned (not hung)';

    # acquire_n succeeds when enough permits
    $sem->release(5);
    ok $sem->acquire_n(3), 'blocking acquire_n succeeds';
    is $sem->value, 2, 'value 2 after acquire_n(3)';
}

# ============================================================
# Semaphore: initial value
# ============================================================

{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 10, 3);
    is $sem->value, 3, 'initial value 3';
    is $sem->max, 10, 'max still 10';

    ok $sem->try_acquire, 'can acquire from initial';
    is $sem->value, 2, 'value 2';

    # Start at 0
    my $sem0 = Data::Sync::Shared::Semaphore->new(undef, 5, 0);
    is $sem0->value, 0, 'initial value 0';
    ok !$sem0->try_acquire, 'cannot acquire at 0';
    $sem0->release;
    is $sem0->value, 1, 'release works from 0';
}

# initial > max should croak
{
    eval { Data::Sync::Shared::Semaphore->new(undef, 3, 5) };
    like $@, qr/initial.*max/i, 'initial > max croaks';
}

# ============================================================
# Semaphore: acquire_guard
# ============================================================

{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 5);
    {
        my $g = $sem->acquire_guard;
        is $sem->value, 4, 'acquire_guard took 1';
    }
    is $sem->value, 5, 'guard released on scope exit';

    {
        my $g = $sem->acquire_guard(3);
        is $sem->value, 2, 'acquire_guard(3) took 3';
    }
    is $sem->value, 5, 'guard released 3';
}

# ============================================================
# RWLock: timed rdlock/wrlock
# ============================================================

{
    my $rw = Data::Sync::Shared::RWLock->new(undef);

    # rdlock_timed succeeds when free
    ok $rw->rdlock_timed(1.0), 'rdlock_timed succeeds';
    $rw->rdunlock;

    # wrlock_timed succeeds when free
    ok $rw->wrlock_timed(1.0), 'wrlock_timed succeeds';

    # rdlock_timed fails when writer holds
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $got = $rw->rdlock_timed(0.1) ? 1 : 0;
        $rw->rdunlock if $got;
        _exit($got);
    }
    waitpid($pid, 0);
    is $? >> 8, 0, 'child rdlock_timed fails when writer holds';
    $rw->wrunlock;

    # wrlock with timeout in method call
    $rw->rdlock;
    $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $got = $rw->wrlock_timed(0.1) ? 1 : 0;
        $rw->wrunlock if $got;
        _exit($got);
    }
    waitpid($pid, 0);
    is $? >> 8, 0, 'child wrlock_timed fails when reader holds';
    $rw->rdunlock;
}

# ============================================================
# RWLock: rdlock_guard / wrlock_guard
# ============================================================

{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    {
        my $g = $rw->rdlock_guard;
        my $s = $rw->stats;
        is $s->{state}, 'read_locked', 'rdlock_guard locks';
    }
    my $s = $rw->stats;
    is $s->{state}, 'unlocked', 'rdlock_guard unlocks on scope exit';

    {
        my $g = $rw->wrlock_guard;
        $s = $rw->stats;
        is $s->{state}, 'write_locked', 'wrlock_guard locks';
    }
    $s = $rw->stats;
    is $s->{state}, 'unlocked', 'wrlock_guard unlocks on scope exit';
}

# ============================================================
# Condvar: lock_guard
# ============================================================

{
    my $cv = Data::Sync::Shared::Condvar->new(undef);
    {
        my $g = $cv->lock_guard;
        ok 1, 'lock_guard acquired';
    }
    # If it didn't unlock, the next lock would deadlock
    $cv->lock;
    $cv->unlock;
    ok 1, 'lock_guard released on scope exit';
}

# ============================================================
# Condvar: wait_while
# ============================================================

{
    my $cv = Data::Sync::Shared::Condvar->new(undef);
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 100, 0);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        select(undef, undef, undef, 0.05);
        $sem->release(5);
        $cv->lock;
        $cv->signal;
        $cv->unlock;
        _exit(0);
    }

    $cv->lock;
    my $ok = $cv->wait_while(sub { $sem->value < 5 }, 5.0);
    $cv->unlock;
    ok $ok, 'wait_while returned true (predicate became false)';
    is $sem->value, 5, 'predicate condition met';
    waitpid($pid, 0);
}

# wait_while timeout
{
    my $cv = Data::Sync::Shared::Condvar->new(undef);
    $cv->lock;
    my $t0 = time;
    my $ok = $cv->wait_while(sub { 1 }, 0.1);
    ok !$ok, 'wait_while timeout returns false';
    ok time - $t0 < 2, 'wait_while did not hang';
    $cv->unlock;
}

# wait_while(0) non-blocking
{
    my $cv = Data::Sync::Shared::Condvar->new(undef);
    $cv->lock;
    my $t0 = time;
    my $ok = $cv->wait_while(sub { 1 }, 0);
    ok !$ok, 'wait_while(pred, 0) returns false immediately';
    ok time - $t0 < 0.1, 'wait_while(pred, 0) did not block';
    $cv->unlock;

    # predicate already false with timeout=0
    $cv->lock;
    $ok = $cv->wait_while(sub { 0 }, 0);
    ok $ok, 'wait_while(false_pred, 0) returns true';
    $cv->unlock;
}

# ============================================================
# Semaphore: file-backed initial value
# ============================================================

{
    my $path = tmpnam() . '.shm';
    my $sem = Data::Sync::Shared::Semaphore->new($path, 10, 3);
    is $sem->value, 3, 'file-backed: initial value 3';
    is $sem->max, 10, 'file-backed: max 10';
    unlink $path;
}

# ============================================================
# Guard failure paths
# ============================================================

# acquire_guard returns undef on timeout
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 1, 0);
    my $g = $sem->acquire_guard(1, 0);
    is $g, undef, 'acquire_guard returns undef on timeout';
    is $sem->value, 0, 'no permits leaked on failed guard';
}

# wrlock_guard with timeout croaks
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    $rw->rdlock;  # hold rdlock so wrlock will fail

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        eval { $rw->wrlock_guard(0.1) };
        _exit($@ =~ /timeout/ ? 0 : 1);
    }
    waitpid($pid, 0);
    is $? >> 8, 0, 'wrlock_guard with timeout croaks on failure';
    $rw->rdunlock;
}

# rdlock_guard with timeout croaks when writer holds
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    $rw->wrlock;

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        eval { $rw->rdlock_guard(0.1) };
        _exit($@ =~ /timeout/ ? 0 : 1);
    }
    waitpid($pid, 0);
    is $? >> 8, 0, 'rdlock_guard with timeout croaks on failure';
    $rw->wrunlock;
}

done_testing;
