use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);

use Data::Sync::Shared;

my $OPS     = $ENV{STRESS_OPS}     || 50_000;
my $WORKERS = $ENV{STRESS_WORKERS} || 6;

diag "stress: $WORKERS workers x $OPS ops each";

# ============================================================
# 1. Semaphore: N workers acquire/release under contention
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 4);
    my $t0 = time;

    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..$OPS) {
                $sem->acquire;
                $sem->release;
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for my $pid (@pids) {
        waitpid($pid, 0);
        $ok = 0 if ($? >> 8) != 0;
    }

    ok $ok, "sem contention: all $WORKERS workers completed $OPS ops";
    is $sem->value, 4, 'sem contention: final value == max';

    my $s = $sem->stats;
    my $expected = $WORKERS * $OPS;
    is $s->{acquires}, $expected, "sem contention: acquires == $expected";
    is $s->{releases}, $expected, "sem contention: releases == $expected";
    diag sprintf "sem: %d ops in %.3fs (%.0f ops/s, waits=%d)",
        $expected, time - $t0, $expected / (time - $t0), $s->{waits};
}

# ============================================================
# 2. Semaphore: drain to 0, N workers release simultaneously
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 10000);
    # Drain all
    while ($sem->try_acquire) {}
    is $sem->value, 0, 'sem drain: started at 0';

    my $per = 1000;
    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $sem->release($per);
            _exit(0);
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;

    my $expected = $WORKERS * $per;
    is $sem->value, $expected, "sem release_n: value == $expected";
}

# ============================================================
# 3. RWLock: concurrent readers + writers, no data corruption
#
# Uses the rwlock to protect a file. Writers increment a counter,
# readers verify the value is monotonically increasing.
# ============================================================
{
    use File::Temp qw(tmpnam);
    my $datafile = tmpnam();
    open my $fh, '>', $datafile or die;
    print $fh "0\n";
    close $fh;

    my $rw = Data::Sync::Shared::RWLock->new(undef);
    my $nreaders = $WORKERS;
    my $nwriters = 2;
    my $write_ops = int($OPS / 10);
    my $read_ops = $OPS;

    my @pids;

    # Writers
    for my $w (1..$nwriters) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..$write_ops) {
                $rw->wrlock;
                open my $in, '<', $datafile or die;
                my $val = <$in>; chomp $val;
                close $in;
                open my $out, '>', $datafile or die;
                print $out $val + 1, "\n";
                close $out;
                $rw->wrunlock;
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    # Readers: check monotonicity
    for my $r (1..$nreaders) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $prev = -1;
            my $bad = 0;
            for (1..$read_ops) {
                $rw->rdlock;
                open my $in, '<', $datafile or die;
                my $val = <$in>; chomp $val;
                close $in;
                $rw->rdunlock;
                if ($val < $prev) { $bad++ }
                $prev = $val;
            }
            _exit($bad > 0 ? 1 : 0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for my $pid (@pids) {
        waitpid($pid, 0);
        $ok = 0 if ($? >> 8) != 0;
    }

    open my $in, '<', $datafile;
    my $final = <$in>; chomp $final;
    close $in;
    unlink $datafile;

    ok $ok, 'rwlock stress: no non-monotonic reads';
    is $final, $nwriters * $write_ops, "rwlock stress: final == expected";

    my $s = $rw->stats;
    diag sprintf "rwlock: acquires=%d releases=%d recoveries=%d",
        $s->{acquires}, $s->{releases}, $s->{recoveries};
}

# ============================================================
# 4. Barrier: N workers, many rounds — generation must be exact
# ============================================================
{
    my $rounds = int($OPS / 100);
    $rounds = 100 if $rounds < 100;
    my $parties = $WORKERS < 2 ? 2 : $WORKERS;
    my $bar = Data::Sync::Shared::Barrier->new(undef, $parties);

    my @pids;
    for my $w (1..$parties - 1) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..$rounds) {
                my $r = $bar->wait(10);
                _exit(99) if $r == -1;  # timeout = failure
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    # Parent is the last party
    for (1..$rounds) {
        my $r = $bar->wait(10);
        die "barrier timeout" if $r == -1;
    }

    my $ok = 1;
    for my $pid (@pids) {
        waitpid($pid, 0);
        $ok = 0 if ($? >> 8) != 0;
    }

    ok $ok, "barrier stress: $parties parties x $rounds rounds";
    is $bar->generation, $rounds, "barrier stress: generation == $rounds";
}

# ============================================================
# 5. Condvar: ping-pong signal/wait under pressure
# ============================================================
{
    my $cv1 = Data::Sync::Shared::Condvar->new(undef);
    my $cv2 = Data::Sync::Shared::Condvar->new(undef);
    my $n = int($OPS / 10);
    $n = 1000 if $n < 1000;

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..$n) {
            $cv1->lock;
            $cv1->wait(5);
            $cv1->unlock;

            $cv2->lock;
            $cv2->signal;
            $cv2->unlock;
        }
        _exit(0);
    }

    my $t0 = time;
    for (1..$n) {
        $cv1->lock;
        $cv1->signal;
        $cv1->unlock;

        $cv2->lock;
        $cv2->wait(5);
        $cv2->unlock;
    }

    waitpid($pid, 0);
    is $? >> 8, 0, "condvar ping-pong: $n roundtrips";
    diag sprintf "condvar: %d roundtrips in %.3fs", $n, time - $t0;
}

# ============================================================
# 6. Once: N workers race to enter, exactly 1 initializer
# ============================================================
{
    my $rounds = 500;
    my $failures = 0;

    for (1..$rounds) {
        my $once = Data::Sync::Shared::Once->new(undef);
        my $nprocs = $WORKERS < 2 ? 2 : $WORKERS;

        my @pids;
        for (1..$nprocs) {
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                my $got = $once->enter(2);
                if ($got) { $once->done }
                _exit($got ? 1 : 0);
            }
            push @pids, $pid;
        }

        my $init_count = 0;
        for my $pid (@pids) {
            waitpid($pid, 0);
            $init_count++ if ($? >> 8) == 1;
        }

        $failures++ if $init_count != 1;
    }

    is $failures, 0, "once race: exactly 1 initializer in all $rounds rounds";
}

done_testing;
