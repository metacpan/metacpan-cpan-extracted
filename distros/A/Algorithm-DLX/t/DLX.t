#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

use List::Util  qw( any );
use Data::Dump  qw( pp );

use Algorithm::DLX;

my $tests = [
    {
        columns => [1, 2, 3, 4, 5, 6],
        rows => {
            rowA => [0, 3],
            rowB => [1, 2, 4],
            rowC => [0, 4, 5],
            rowD => [1, 3],
            rowE => [2, 5],
            rowF => [0, 2],
        }, 
        answers => [],
        message => "No solution returns correct"
    },
    {
        columns => [1],
        rows => {
            rowA => [0],
        },
        answers => [["rowA"]],
        message => "Single column and row returns correct"
    },
    {
        columns => [1, 2, 3, 4, 5, 6],
        rows => {
            rowA => [0, 3],
            rowB => [1, 2, 4],
            rowC => [0, 4, 5],
            rowD => [1, 3],
            rowE => [2, 5],
            rowF => [0, 2],
        }, 
        answers => [
        ],
        message => "No solution Returns Correct"
    },
    {
        columns => [1, 2, 3, 4, 5, 6, 7],
        rows => {
            rowA => [0, 3, 6],
            rowB => [0, 3],
            rowC => [3, 4, 6],
            rowD => [2, 4, 5],
            rowE => [1, 2, 5, 6],
            rowF => [1, 6],
        }, 
        answers => [
            ["rowB", "rowD", "rowF"]
        ],
        message => "Single solution Returns Correct"
    },
    {
        columns => [1, 2, 3, 4, 5, 6, 7],
        rows => {
            rowA => [0, 3, 4],
            rowB => [0, 3],
            rowC => [3, 4, 6],
            rowD => [2, 4, 5],
            rowE => [1, 2, 5, 6],
            rowF => [1, 6],
        }, 
        answers => [
            ["rowA", "rowE"],
            ["rowB", "rowD", "rowF"],
        ],
        message => "Multiple solution returns correct"
    },
];

for my $test (@$tests) {
    # Create a new DLX solver instance
    my $dlx = Algorithm::DLX->new();
 
    # Define columns for the exact cover problem
    my @cols;
    for my $col (@{$test->{columns}}) {
        push @cols, $dlx->add_column($col);
    }

    # Define rows for the exact cover problem
    while ((my ($row_name, $col_subset) = each %{$test->{rows}})) {
        my @subset = map { $cols[$_] } @$col_subset;
        $dlx->add_row($row_name, @subset);
    }

    # Solve the exact cover problem
    my $solutions = $dlx->solve();
    my $subsolution_check = 1;
    for  my $solution (@$solutions) {
        $subsolution_check = 0 unless any { @$solution eq @$_ } @{$test->{answers}};
    }

    is $subsolution_check, 1, $test->{message};
}
