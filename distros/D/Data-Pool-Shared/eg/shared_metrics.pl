#!/usr/bin/env perl
# Shared metrics: workers atomically update counters, parent reads them

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::Pool::Shared;

my $nworkers = shift || 4;
my $pool = Data::Pool::Shared::I64->new(undef, 8);

# pre-allocate metric slots
my $requests   = $pool->alloc_set(0);
my $errors     = $pool->alloc_set(0);
my $latency_us = $pool->alloc_set(0);

printf "metrics: requests=slot[%d] errors=slot[%d] latency=slot[%d]\n",
    $requests, $errors, $latency_us;
printf "starting %d workers...\n\n", $nworkers;

my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..200) {
            $pool->add($requests, 1);
            $pool->add($errors, 1) if rand() < 0.05;
            $pool->add($latency_us, int(rand(5000)) + 100);
            select(undef, undef, undef, 0.005);
        }
        _exit(0);
    }
    push @pids, $pid;
}

# live dashboard
for (1..8) {
    sleep 0.5;
    my $req = $pool->get($requests);
    my $err = $pool->get($errors);
    my $lat = $pool->get($latency_us);
    printf "  reqs=%-6d errs=%-4d err%%=%.1f%% avg_lat=%.0fus\n",
        $req, $err,
        $req > 0 ? 100.0 * $err / $req : 0,
        $req > 0 ? $lat / $req : 0;
}

waitpid($_, 0) for @pids;

printf "\nfinal:\n";
printf "  requests:    %d\n", $pool->get($requests);
printf "  errors:      %d\n", $pool->get($errors);
printf "  avg latency: %.0f us\n",
    $pool->get($latency_us) / ($pool->get($requests) || 1);

$pool->free($_) for $requests, $errors, $latency_us;
