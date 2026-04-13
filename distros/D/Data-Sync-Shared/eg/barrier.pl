#!/usr/bin/env perl
# Barrier: phased parallel computation
#
# Workers proceed in lockstep phases. Each phase: compute locally,
# then wait at the barrier until all workers finish the phase.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $nworkers = 4;
my $nphases  = 5;

my $bar = Data::Sync::Shared::Barrier->new(undef, $nworkers);

my @pids;
my $t0 = time;

for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for my $phase (1..$nphases) {
            # Simulate per-phase work (varying by worker)
            usleep(100 * $w);
            my $leader = $bar->wait;
            printf "  [worker %d] phase %d done%s\n",
                $w, $phase, $leader ? " (leader)" : "";
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;
printf "all %d phases complete in %.3fs, generation=%d\n",
    $nphases, time - $t0, $bar->generation;
