use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use IO::Pipe;

use Data::Sync::Shared;

# RWLock dead-reader recovery: SIGKILL'd reader must not pin the
# reader-count and indefinitely starve writers (or peers wanting an
# exclusive lock). Recovery should happen within ~2-4s via the
# per-process reader-slot drain path.

# ============================================================
# 1. Single dead reader, anonymous mmap, parent recovers wrlock
# ============================================================
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        $rw->rdlock;
        print $pipe "rdlocked\n";
        $pipe->close;
        sleep 60;  # hold rdlock forever — parent will kill us
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;

    kill 9, $pid;
    waitpid $pid, 0;

    my $t0 = time;
    $rw->wrlock;
    my $dt = time - $t0;
    $rw->wrunlock;

    my $s = $rw->stats;
    diag sprintf "dt=%.2fs recoveries=%d", $dt, $s->{recoveries};

    ok $dt >= 1.5 && $dt < 6,
        sprintf('rwlock dead-reader recovery in %.2fs', $dt);
    ok $s->{recoveries} >= 1, 'dead-reader: recoveries counter incremented';
}

# ============================================================
# 2. Single dead reader, peer also wants rdlock (succeeds quickly)
# ============================================================
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $pipe->writer;
        $rw->rdlock;
        print $pipe "rdlocked\n";
        $pipe->close;
        sleep 60;
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;

    kill 9, $pid;
    waitpid $pid, 0;

    # Peer rdlock should succeed immediately — readers don't conflict.
    my $t0 = time;
    $rw->rdlock;
    my $dt = time - $t0;
    $rw->rdunlock;
    ok $dt < 1, sprintf('peer rdlock unaffected by dead reader (%.3fs)', $dt);
}

# ============================================================
# 3. Multiple dead readers; final wrlock recovers
# ============================================================
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);

    my @kids;
    for (1..3) {
        my $pipe = IO::Pipe->new;
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $pipe->writer;
            $rw->rdlock;
            print $pipe "rdlocked\n";
            $pipe->close;
            sleep 60;
            _exit(0);
        }
        $pipe->reader;
        <$pipe>;
        $pipe->close;
        push @kids, $pid;
    }
    kill 9, $_ for @kids;
    waitpid $_, 0 for @kids;

    my $t0 = time;
    $rw->wrlock;
    my $dt = time - $t0;
    $rw->wrunlock;
    ok $dt < 8,
        sprintf('rwlock recovery from 3 dead readers in %.2fs', $dt);
}

# ============================================================
# 4. Recovery is idempotent: wrlock again after recovery still works
# ============================================================
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    my $pid = fork // die;
    if ($pid == 0) {
        $rw->rdlock;
        sleep 60;
        _exit(0);
    }
    sleep 0.1;
    kill 9, $pid;
    waitpid $pid, 0;

    $rw->wrlock;  # may take up to ~5s
    $rw->wrunlock;

    # Second round
    my $t0 = time;
    $rw->wrlock;
    my $dt = time - $t0;
    $rw->wrunlock;
    ok $dt < 0.5, sprintf('post-recovery wrlock fast (%.3fs)', $dt);
}

# ============================================================
# 5. File-backed RWLock (separate processes, not just fork)
# ============================================================
{
    use File::Temp qw(tmpnam);
    my $path = tmpnam() . ".$$";
    my $rw = Data::Sync::Shared::RWLock->new($path);

    my $pipe = IO::Pipe->new;
    my $pid = fork // die;
    if ($pid == 0) {
        $pipe->writer;
        my $c = Data::Sync::Shared::RWLock->new($path);
        $c->rdlock;
        print $pipe "rdlocked\n";
        $pipe->close;
        sleep 60;
        _exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;

    kill 9, $pid;
    waitpid $pid, 0;

    my $t0 = time;
    $rw->wrlock;
    my $dt = time - $t0;
    $rw->wrunlock;
    ok $dt < 6, sprintf('file-backed RWLock dead-reader recovery in %.2fs', $dt);

    unlink $path;
}

done_testing;
