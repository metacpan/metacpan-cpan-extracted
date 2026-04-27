use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Sync::Shared;

my $WORKERS = $ENV{STRESS_WORKERS} || 6;
my $OPS     = $ENV{STRESS_OPS}     || 10_000;

diag "acquire_n stress: $WORKERS workers x $OPS ops";

# ============================================================
# 1. Fixed-N acquire/release: final value must equal max
# ============================================================
{
    my $max = 100;
    my $sem = Data::Sync::Shared::Semaphore->new(undef, $max);
    my $per = int($OPS / $WORKERS);

    my $t0 = time;
    my @pids;
    for my $w (1..$WORKERS) {
        my $n = ($w % 4) + 1;  # 1..4 permits per worker
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..$per) {
                $sem->acquire_n($n);
                $sem->release($n);
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for (@pids) { waitpid($_, 0); $ok = 0 if $? }

    ok $ok, "fixed-N: all workers completed";
    is $sem->value, $max, "fixed-N: final value == $max";
    diag sprintf "fixed-N: %.3fs", time - $t0;
}

# ============================================================
# 2. try_acquire_n contention: atomic all-or-nothing
# ============================================================
{
    my $max = 20;
    my $sem = Data::Sync::Shared::Semaphore->new(undef, $max);
    my $per = int($OPS / $WORKERS);

    my $t0 = time;
    my @pids;
    for my $w (1..$WORKERS) {
        my $n = ($w % 3) + 2;  # 2..4
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $acquired = 0;
            for (1..$per) {
                if ($sem->try_acquire_n($n)) {
                    $acquired++;
                    $sem->release($n);
                }
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for (@pids) { waitpid($_, 0); $ok = 0 if $? }

    ok $ok, "try_acquire_n: all workers completed";
    is $sem->value, $max, "try_acquire_n: final value == $max";
    diag sprintf "try_acquire_n: %.3fs", time - $t0;
}

# ============================================================
# 3. Mixed acquire/acquire_n: no value corruption
# ============================================================
{
    my $max = 50;
    my $sem = Data::Sync::Shared::Semaphore->new(undef, $max);
    my $per = int($OPS / $WORKERS);

    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for my $i (1..$per) {
                if ($i % 3 == 0) {
                    my $n = ($i % 5) + 1;
                    $sem->acquire_n($n);
                    $sem->release($n);
                } else {
                    $sem->acquire;
                    $sem->release;
                }
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for (@pids) { waitpid($_, 0); $ok = 0 if $? }

    ok $ok, "mixed acquire: all workers completed";
    is $sem->value, $max, "mixed acquire: final value == $max";
}

# ============================================================
# 4. drain + release_n: bulk operations under contention
# ============================================================
{
    my $max = 1000;
    my $sem = Data::Sync::Shared::Semaphore->new(undef, $max);
    my $per = int($OPS / $WORKERS);

    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..$per) {
                my $got = $sem->drain;
                $sem->release($got) if $got;
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for (@pids) { waitpid($_, 0); $ok = 0 if $? }

    ok $ok, "drain+release: all workers completed";
    is $sem->value, $max, "drain+release: final value == $max";
}

# ============================================================
# 5. Guard-based acquire_n: exception during hold
# ============================================================
{
    my $max = 30;
    my $sem = Data::Sync::Shared::Semaphore->new(undef, $max);

    my @pids;
    for my $w (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for my $i (1..500) {
                eval {
                    my $g = $sem->acquire_guard(($w % 3) + 1);
                    die "boom" if $i % 7 == 0;
                };
            }
            _exit(0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for (@pids) { waitpid($_, 0); $ok = 0 if $? }

    ok $ok, "guard acquire_n + exception: all workers completed";
    is $sem->value, $max, "guard acquire_n + exception: value == $max";
}

done_testing;
