#!/usr/bin/perl -w
use strict;
#The following program solves the knapsack problem for a list of weights
#(14, 5, 2, 11, 3, 8) and capacity 30.

    use Algorithm::Knapsack;
    my @weights = (14, 5, 2, 11, 3, 8);
    my $knapsack = Algorithm::Knapsack->new(
        capacity => 30,
        weights  => \@weights,
    );
    $knapsack->compute();
    foreach my $solution ($knapsack->solutions()) {
        print join(',', map { $weights[$_] } @{$solution}), "\n";
    }


