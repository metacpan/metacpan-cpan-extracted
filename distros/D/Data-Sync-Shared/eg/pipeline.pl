#!/usr/bin/env perl
# Barrier-synchronized multi-stage pipeline
#
# 3 stages, each with N workers. All workers in a stage must finish
# before the next stage begins. Barriers enforce the stage boundaries.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $nworkers = 4;
my $nstages  = 3;

# One barrier per stage transition (nstages - 1 barriers)
my @barriers = map {
    Data::Sync::Shared::Barrier->new(undef, $nworkers)
} 1..($nstages - 1);

my @pids;
my $t0 = time;

for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for my $stage (1..$nstages) {
            # Do stage work (varying time by worker + stage)
            usleep(10_000 * $w + 5_000 * $stage);
            printf "  [t+%.3fs] worker %d finished stage %d\n",
                time - $t0, $w, $stage;

            # Wait at barrier before next stage (except last)
            if ($stage < $nstages) {
                my $leader = $barriers[$stage - 1]->wait(10);
                if ($leader) {
                    printf "  [t+%.3fs] === stage %d complete, starting stage %d ===\n",
                        time - $t0, $stage, $stage + 1;
                }
            }
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;
printf "\npipeline: %d workers x %d stages in %.3fs\n",
    $nworkers, $nstages, time - $t0;
