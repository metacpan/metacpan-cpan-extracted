#!/usr/bin/env perl
use strict;
use warnings;
use POSIX ();
use Data::HashMap::Shared::SI;   # string key -> int64 counter

# Write-heavy counters across many processes. Sharding spreads keys over N
# independent maps with independent locks, so writers touching different keys
# rarely contend on the same lock. incr_by stays atomic -- no lost updates.

my $prefix   = "/tmp/dhms_sharded_ctr_$$";
my $shards   = 8;
my $counters = Data::HashMap::Shared::SI->new_sharded($prefix, $shards, 100_000);

my $workers    = 8;
my $per_worker = 50_000;
my @keys = map { "metric.$_" } 1 .. 16;

my @pids;
for my $w (1 .. $workers) {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $c = Data::HashMap::Shared::SI->new_sharded($prefix, $shards, 100_000);
        srand($w * 104729 + $$);
        shm_si_incr_by $c, $keys[int rand @keys], 1 for 1 .. $per_worker;
        POSIX::_exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

my $total = 0;
$total += $counters->get($_) // 0 for @keys;
printf "%d workers x %d incrs over %d sharded keys => total %d (expected %d)\n",
    $workers, $per_worker, scalar @keys, $total, $workers * $per_worker;

unlink glob "$prefix.*";   # remove all shard backing files
