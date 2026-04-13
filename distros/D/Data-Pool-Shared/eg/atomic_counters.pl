#!/usr/bin/env perl
# Atomic counters: multiple processes increment shared counters via add()

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Pool::Shared;
$| = 1;

my $nworkers = shift || 4;
my $iters    = shift || 100_000;

my $pool = Data::Pool::Shared::I64->new(undef, 4);

# allocate 4 counters
my @counters = map { $pool->alloc } 1..4;
$pool->set($_, 0) for @counters;

printf "%d workers x %d iterations on %d counters\n",
    $nworkers, $iters, scalar @counters;

my $t0 = time;
my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..$iters) {
            $pool->add($counters[$_ % 4], 1) for 0..3;
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;
my $elapsed = time - $t0;

my $expected = $nworkers * $iters;
my $total = 0;
for my $c (@counters) {
    my $v = $pool->get($c);
    printf "counter[%d] = %d (expected %d) %s\n",
        $c, $v, $expected, $v == $expected ? "ok" : "MISMATCH";
    $total += $v;
}

printf "\ntotal: %d ops in %.3fs (%.0f ops/s)\n",
    $total, $elapsed, $total / $elapsed;

$pool->free($_) for @counters;
