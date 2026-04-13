#!/usr/bin/env perl
# Rate limiter using a semaphore with timed acquire
#
# Allows N concurrent operations across all processes.
# Workers that exceed the limit block until a slot opens
# or timeout (to avoid unbounded queuing).
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $max_concurrent = 3;   # max 3 concurrent "API calls"
my $nworkers       = 8;
my $calls_per      = 10;
my $call_time_us   = 50_000;  # 50ms per "API call"
my $acquire_timeout = 0.5;    # give up after 500ms

my $sem = Data::Sync::Shared::Semaphore->new(undef, $max_concurrent);

my @pids;
my $t0 = time;

for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $ok = 0;
        my $dropped = 0;
        for (1..$calls_per) {
            if ($sem->acquire($acquire_timeout)) {
                usleep($call_time_us);
                $sem->release;
                $ok++;
            } else {
                $dropped++;
            }
        }
        printf "  worker %d: %d ok, %d dropped\n", $w, $ok, $dropped;
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;

printf "\nrate limiter: %d workers x %d calls, max %d concurrent, %.3fs\n",
    $nworkers, $calls_per, $max_concurrent, time - $t0;
my $s = $sem->stats;
printf "acquires: %d, timeouts: %d, final: %d/%d\n",
    $s->{acquires}, $s->{timeouts}, $sem->value, $max_concurrent;
