#!/usr/bin/env perl
# Contention benchmark: vary pool size to measure futex blocking effects

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use POSIX qw(_exit);
use Data::Pool::Shared;

my $WORKERS = shift || 8;
my $OPS     = shift || 100_000;

printf "Pool contention: %d workers x %d alloc/free ops each\n\n", $WORKERS, $OPS;
printf "  %-12s %12s %10s %10s %10s\n",
    "capacity", "ops/s", "waits", "timeouts", "elapsed";
printf "  %s\n", "-" x 60;

for my $cap (2, 4, 8, 16, 32, 64, 128, 256, 1024, 4096) {
    my $pool = Data::Pool::Shared::I64->new(undef, $cap);

    my $t0 = time;
    my @pids;
    for (1..$WORKERS) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..$OPS) {
                my $s = $pool->alloc(2.0);
                next unless defined $s;
                $pool->set($s, $$);
                $pool->free($s);
            }
            _exit(0);
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;
    my $dt = time - $t0;

    my $total = $WORKERS * $OPS;
    my $s = $pool->stats;
    printf "  cap=%-8d %12.0f %10d %10d %10.3fs\n",
        $cap, $total / $dt, $s->{waits}, $s->{timeouts}, $dt;
}

printf "\nBatch alloc/free_n comparison:\n\n";
printf "  %-14s %12s %12s\n", "batch size", "individual", "batched";
printf "  %s\n", "-" x 42;

my $BATCH_OPS = $OPS / 10;
for my $batch (1, 4, 16, 64) {
    my $pool = Data::Pool::Shared::I64->new(undef, 4096);

    # individual
    my $t0 = time;
    for (1..$BATCH_OPS) {
        my @s;
        push @s, $pool->alloc for 1..$batch;
        $pool->free($_) for @s;
    }
    my $dt_ind = time - $t0;

    $pool->reset;

    # batched
    $t0 = time;
    for (1..$BATCH_OPS) {
        my $s = $pool->alloc_n($batch);
        $pool->free_n($s);
    }
    my $dt_bat = time - $t0;

    printf "  batch=%-8d %10.0f/s %10.0f/s\n",
        $batch, $BATCH_OPS / $dt_ind, $BATCH_OPS / $dt_bat;
}
