#!/usr/bin/env perl
# Rate limiter: each bit = one permit, workers claim via test-and-set
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::BitSet::Shared;
$| = 1;

my $max_concurrent = 8;
my $permits = Data::BitSet::Shared->new(undef, $max_concurrent);
my $nworkers = 12;

my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die;
    if ($pid == 0) {
        # try to claim a permit
        my $slot;
        for my $attempt (1..50) {
            my $candidate = $permits->first_clear;
            last unless defined $candidate;
            if ($permits->set($candidate) == 0) {
                $slot = $candidate;
                last;
            }
        }
        if (defined $slot) {
            printf "worker %2d: got permit %d\n", $w, $slot;
            select(undef, undef, undef, 0.02);
            $permits->clear($slot);
        } else {
            printf "worker %2d: no permit available\n", $w;
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;
printf "permits in use: %d\n", $permits->count;
