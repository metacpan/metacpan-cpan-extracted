#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::Shared::II;

# Anonymous shared map (no filesystem presence) for in-memory aggregation
# across forked workers. Parent forks N children; each increments a
# shared counter. Parent reads the final sum.

my $stats = Data::HashMap::Shared::II->new(undef, 1024);  # anonymous

my $N = 8;
my $PER = 1000;
my @pids;
for my $w (1..$N) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # Child inherits the anonymous mmap automatically
        shm_ii_incr_by $stats, 0, 1 for 1..$PER;     # global counter
        shm_ii_incr_by $stats, $w, $PER;             # per-worker counter
        exit;
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;

my $total = shm_ii_get $stats, 0;
printf "global total: %d (expected %d)\n", $total, $N * $PER;
for my $w (1..$N) {
    my $c = shm_ii_get $stats, $w;
    printf "  worker %d: %d\n", $w, $c // 0;
}
