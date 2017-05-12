#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1275;

require Algorithm::GaussianElimination::GF2;

for my $n (1 .. 50) {
    my $age = Algorithm::GaussianElimination::GF2->new;

    for my $i (1..$n) {
        $age->new_equation(map((0.5 > rand), 0..$n));
    }
    my $sol = $age->solve;
    if (defined $sol) {
        for my $eq (@{$age->{eqs}}) {
            unless (ok($eq->test_solution(@$sol))) {
                my @a = $eq->as;
                my $b = $eq->b;
                diag "eq : @a | $b |\nsol: @$sol\n\n";
            }
        }
    }
    else {
        ok(1) for (1..$n);
    }
}
