#!/usr/bin/env perl
# Single-process benchmark: add, rank, range_by_rank (top-N), pop_min.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::SortedSet::Shared;

my $N = 1_000_000;
my $z = Data::SortedSet::Shared->new(undef, $N);

my $t = time;
$z->add($_, rand()) for 1 .. $N;
printf "add:                %.2fM/s\n", $N / (time - $t) / 1e6;

$t = time;
$z->rank(int(rand($N)) + 1) for 1 .. 100_000;
printf "rank:                %.0f/s\n", 100_000 / (time - $t);

$t = time;
$z->rev_range_by_rank(0, 99) for 1 .. 10_000;      # top 100
printf "rev_range_by_rank(100): %.0f/s\n", 10_000 / (time - $t);

$t = time;
my $n = 0;
while ($n < $N) { my @x = $z->pop_min; last unless @x; $n++ }
printf "pop_min:            %.2fM/s\n", $N / (time - $t) / 1e6;
