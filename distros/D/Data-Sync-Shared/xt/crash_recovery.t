use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);
use POSIX qw(_exit);
use IO::Pipe;

use Data::Sync::Shared;

# ============================================================
# 1. RWLock: writer crashes while holding wrlock
#
# Child acquires wrlock, parent kills it, then parent acquires.
# Recovery should happen within ~2s (LOCK_TIMEOUT_SEC).
# ============================================================
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        $rw->wrlock;
        print $pipe "locked\n";
        $pipe->close;
        sleep(60);  # hold forever — parent will kill us
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;  # wait until child holds the lock
    $pipe->close;

    kill 9, $pid;
    waitpid($pid, 0);
    diag "child $pid killed while holding wrlock";

    my $t0 = time;
    $rw->wrlock;
    my $dt = time - $t0;
    $rw->wrunlock;

    my $s = $rw->stats;
    diag sprintf "dt=%.2fs recoveries=%d", $dt, $s->{recoveries};

    ok $dt >= 1.5 && $dt < 5, sprintf('rwlock writer recovery in %.2fs', $dt);
    ok $s->{recoveries} >= 1, 'rwlock recovery counter incremented';
}

# ============================================================
# 2. RWLock: multiple crash/recovery cycles
# ============================================================
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);

    for my $round (1..3) {
        my $pipe = IO::Pipe->new;
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $pipe->writer;
            $rw->wrlock;
            print $pipe "locked\n";
            $pipe->close;
            sleep(60);
            _exit(0);
        }
        $pipe->reader;
        <$pipe>;
        $pipe->close;

        kill 9, $pid;
        waitpid($pid, 0);

        my $t0 = time;
        $rw->wrlock;
        my $dt = time - $t0;
        $rw->wrunlock;

        ok $dt < 5, sprintf("round %d: wrlock recovery in %.2fs", $round, $dt);
    }

    my $s = $rw->stats;
    ok $s->{recoveries} >= 3, "multi-crash: at least 3 recoveries";
    diag sprintf "total recoveries: %d", $s->{recoveries};
}

# ============================================================
# 3. Once: initializer crashes without calling done()
# ============================================================
{
    my $once = Data::Sync::Shared::Once->new(undef);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        $once->enter;
        print $pipe "entered\n";
        $pipe->close;
        # Die without calling done()
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;
    waitpid($pid, 0);

    diag "child $pid exited without calling done()";

    my $t0 = time;
    my $got = $once->enter(5);
    my $dt = time - $t0;

    ok $got, 'once: parent became new initializer after child crash';
    ok $dt < 3, sprintf('once: stale detection in %.3fs', $dt);
    $once->done;

    my $s = $once->stats;
    ok $s->{recoveries} >= 1, 'once: recovery counter incremented';
    ok $s->{is_done}, 'once: is_done after recovery + done';
}

# ============================================================
# 4. Condvar: mutex holder crashes
#
# Child locks condvar mutex, dies. Parent should recover
# and be able to lock.
# ============================================================
{
    my $cv = Data::Sync::Shared::Condvar->new(undef);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        $cv->lock;
        print $pipe "locked\n";
        $pipe->close;
        sleep(60);  # hold forever
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;

    kill 9, $pid;
    waitpid($pid, 0);
    diag "child $pid killed while holding condvar mutex";

    my $t0 = time;
    $cv->lock;
    my $dt = time - $t0;
    $cv->unlock;

    my $s = $cv->stats;
    diag sprintf "dt=%.2fs recoveries=%d", $dt, $s->{recoveries};

    ok $dt >= 1.5 && $dt < 5, sprintf('condvar mutex recovery in %.2fs', $dt);
    ok $s->{recoveries} >= 1, 'condvar recovery counter incremented';
}

# ============================================================
# 5. Semaphore: no mutex, no stale recovery needed
#
# CAS-based, so a dead process just means unreleased permits.
# Verify the semaphore remains functional.
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 3);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $sem->acquire;  # take one permit, die without release
        _exit(0);
    }
    waitpid($pid, 0);

    # Parent: 2 permits should remain
    is $sem->value, 2, 'sem: 2 permits after child took 1 and died';

    # Still fully functional
    ok $sem->try_acquire, 'sem: parent can still acquire';
    $sem->release;

    # Refill the leaked permit manually
    $sem->release;
    is $sem->value, 3, 'sem: back to full after manual release';
}

done_testing;
