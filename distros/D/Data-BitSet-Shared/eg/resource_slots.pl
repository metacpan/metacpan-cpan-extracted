#!/usr/bin/env perl
# Resource slot allocator: atomically claim/release numbered slots
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::BitSet::Shared;
$| = 1;

my $nslots   = 32;
my $nworkers = 6;

my $slots = Data::BitSet::Shared->new(undef, $nslots);

my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die;
    if ($pid == 0) {
        # claim a slot via first_clear + set (test-and-set pattern)
        my $slot;
        for (1..100) {
            my $candidate = $slots->first_clear;
            last unless defined $candidate;
            my $old = $slots->set($candidate);
            if ($old == 0) {  # we won the race
                $slot = $candidate;
                last;
            }
        }
        if (defined $slot) {
            printf "worker %d claimed slot %d\n", $w, $slot;
            select(undef, undef, undef, 0.05);  # use the slot
            $slots->clear($slot);
            printf "worker %d released slot %d\n", $w, $slot;
        } else {
            printf "worker %d: no slot available\n", $w;
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;
printf "\nfinal: %d slots in use\n", $slots->count;
