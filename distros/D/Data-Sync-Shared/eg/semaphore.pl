#!/usr/bin/env perl
# Cross-process resource limiter using a shared semaphore
#
# 8 workers compete for 3 permits. Each worker acquires a permit,
# holds it briefly (simulating resource use), then releases.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $max_permits = 3;
my $nworkers    = 8;
my $work_per    = 20;

my $sem = Data::Sync::Shared::Semaphore->new(undef, $max_permits);

my @pids;
my $t0 = time;

for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..$work_per) {
            $sem->acquire;          # block until permit available
            usleep(100);            # simulate holding a resource
            $sem->release;
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;
my $elapsed = time - $t0;

printf "semaphore: %d permits, %d workers x %d ops\n",
    $max_permits, $nworkers, $work_per;
printf "final value: %d (expected %d)\n", $sem->value, $max_permits;
printf "elapsed: %.3fs\n", $elapsed;

my $s = $sem->stats;
printf "acquires: %d, releases: %d, waits: %d\n",
    $s->{acquires}, $s->{releases}, $s->{waits};
