#!/usr/bin/env perl
# Multi-stage pipeline combining Pool + Queue + Sync
#
# Architecture:
#   Producer → [Queue: job IDs] → Workers → [Queue: result IDs] → Collector
#   Pool stores the actual work items and results (fixed-size, no alloc in hot path)
#   Barrier synchronizes startup
#
# Requires: Data::Queue::Shared, Data::Sync::Shared (siblings)

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use lib "$FindBin::Bin/../../Data-Queue-Shared/blib/lib",
        "$FindBin::Bin/../../Data-Queue-Shared/blib/arch";
use lib "$FindBin::Bin/../../Data-Sync-Shared/blib/lib",
        "$FindBin::Bin/../../Data-Sync-Shared/blib/arch";

use POSIX qw(_exit);
use Time::HiRes qw(time);

$| = 1;
eval { require Data::Pool::Shared;  1 } or die "Data::Pool::Shared required\n";
eval { require Data::Queue::Shared; 1 } or die "Data::Queue::Shared required (sibling module)\n";
eval { require Data::Sync::Shared;  1 } or die "Data::Sync::Shared required (sibling module)\n";

my $NJOBS    = shift || 200;
my $NWORKERS = shift || 4;

# Pool: holds job data (Str: input text) and results (I64: computed hash)
my $jobs_pool    = Data::Pool::Shared::Str->new(undef, $NJOBS + 16, 128);
my $results_pool = Data::Pool::Shared::I64->new(undef, $NJOBS + 16);

# Queues: distribute job slot IDs and collect result slot IDs
my $job_q    = Data::Queue::Shared::Int->new(undef, $NJOBS + 16);
my $result_q = Data::Queue::Shared::Int->new(undef, $NJOBS + 16);

# Barrier: all workers + producer + collector start together
my $barrier = Data::Sync::Shared::Barrier->new(undef, $NWORKERS + 2);

printf "pipeline: %d jobs, %d workers\n", $NJOBS, $NWORKERS;
printf "  pool(jobs)=%d slots, pool(results)=%d slots\n",
    $jobs_pool->capacity, $results_pool->capacity;

my @pids;

# --- Workers: read job ID from queue, process, put result ID in result queue ---
for my $w (1 .. $NWORKERS) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        use integer;
        $barrier->wait;
        while (1) {
            my $job_slot = $job_q->pop_wait(2.0);
            last unless defined $job_slot;
            last if $job_slot == -1;  # poison pill

            my $input = $jobs_pool->get($job_slot);
            $jobs_pool->free($job_slot);

            # "process": compute a hash of the input
            my $hash = 0;
            $hash = $hash * 31 + ord($_) for split //, $input;

            # store result in results pool
            my $res_slot = $results_pool->alloc;
            $results_pool->set($res_slot, $hash);

            $result_q->push($res_slot);
        }
        _exit(0);
    }
    push @pids, $pid;
}

# --- Producer: create jobs in pool, push slot IDs to queue ---
my $producer = fork // die "fork: $!";
if ($producer == 0) {
    $barrier->wait;
    for my $i (1 .. $NJOBS) {
        my $slot = $jobs_pool->alloc;
        $jobs_pool->set($slot, sprintf("job-%04d-data-%s", $i, "x" x 64));
        $job_q->push($slot);
    }
    # poison pills
    $job_q->push(-1) for 1 .. $NWORKERS;
    _exit(0);
}
push @pids, $producer;

# --- Collector: gather results ---
$barrier->wait;
my $t0 = time;
my @results;
for (1 .. $NJOBS) {
    my $res_slot = $result_q->pop_wait(5.0);
    last unless defined $res_slot;
    push @results, $results_pool->get($res_slot);
    $results_pool->free($res_slot);
}
my $dt = time - $t0;

waitpid($_, 0) for @pids;

printf "collected %d results in %.3fs (%.0f jobs/s)\n",
    scalar @results, $dt, @results / ($dt || 0.001);
printf "sample hashes: %s\n", join(' ', map { sprintf("%x", $_) } @results[0..4]);
printf "pools: jobs_used=%d results_used=%d\n",
    $jobs_pool->used, $results_pool->used;
