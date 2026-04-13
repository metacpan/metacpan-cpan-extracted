#!/usr/bin/env perl
# Backtracking solver: stack of (position, state) for maze/constraint problems
# Demonstrates Str stack for structured state snapshots
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Stack::Shared;
$| = 1;

# Simple N-Queens solver using shared stack for state
my $N = shift || 6;
my $stk = Data::Stack::Shared::Str->new(undef, 10000, 64);

# state = "col0,col1,...,colN" — queen positions per row
# push initial partial solutions (one queen per column in row 0)
for my $c (0..$N-1) {
    $stk->push("$c");
}

my $solutions = 0;
while (!$stk->is_empty) {
    my $state = $stk->pop;
    my @cols = split /,/, $state;
    my $row = scalar @cols;

    if ($row == $N) {
        $solutions++;
        printf "solution %d: [%s]\n", $solutions, $state if $solutions <= 3;
        next;
    }

    # try each column for next row
    COL: for my $c (0..$N-1) {
        # check conflicts with existing queens
        for my $r (0..$#cols) {
            next COL if $cols[$r] == $c;                    # same column
            next COL if abs($cols[$r] - $c) == $row - $r;   # diagonal
        }
        $stk->push("$state,$c");
    }
}

printf "\n%d-Queens: %d solutions found\n", $N, $solutions;
printf "stats: pushes=%d pops=%d\n", $stk->stats->{pushes}, $stk->stats->{pops};
