#!/usr/bin/env perl
# Shared histogram with batch atomic updates via add_slice
use strict;
use warnings;
use POSIX qw(_exit);
use Data::Buffer::Shared::I64;

my $nbins = 100;
my $nprocs = 4;
my $samples = 100_000;

my $hist = Data::Buffer::Shared::I64->new_anon($nbins);

my @pids;
for my $p (1..$nprocs) {
    my $pid = fork();
    if ($pid == 0) {
        srand($$);
        for (1..$samples) {
            # simulate: sample a value 0-99, increment that bin
            my $bin = int(rand($nbins));
            $hist->incr($bin);
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;

# print histogram
my $total = 0;
my @counts = $hist->slice(0, $nbins);
for my $i (0..$#counts) { $total += $counts[$i] }

printf "total samples: %d (expected %d)\n", $total, $nprocs * $samples;
printf "bins 0-9: %s\n", join(' ', map { sprintf "%6d", $_ } @counts[0..9]);
printf "mean per bin: %.1f\n", $total / $nbins;
