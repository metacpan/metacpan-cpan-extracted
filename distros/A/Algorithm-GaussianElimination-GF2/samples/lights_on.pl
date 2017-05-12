#!/usr/bin/perl

#
# See http://perlmonks.org/?node_id=940327
#
# To solve that problem there run this script as:
#
#     $ lights_on.pl 189
#

use strict;
use warnings;

use Algorithm::GaussianElimination::GF2;

use 5.010;

(@ARGV >= 1 and @ARGV <= 2) or die "Usage:\n  $0 len [width]\n\n";

my ($len, $w) = @ARGV;

unless (defined $w) {
    $w = int sqrt($len);
    $w++ unless $w * $w == $len;
}

my $a = Algorithm::GaussianElimination::GF2->new;

for my $ix (0..$len-1) {
    my $eq = $a->new_equation;

    $eq->b(1);
    $eq->a($ix, 1);
    my $up = $ix - $w;
    $eq->a($up, 1) if $up >= 0;
    my $down = $ix + $w;
    $eq->a($down, 1) if $down < $len;
    my $left = $ix - 1;
    $eq->a($left, 1) if $left % $w + 1 != $w;
    my $right = $ix + 1;
    $eq->a($right, 1) if $right % $w and $right < $len;
}

my ($sol, @base0) = $a->solve;

if ($sol) {
    my @sol = @$sol;
    while (@sol) {
        my @row = splice @sol, 0, $w;
        say "@row";
    }

    for my $sol0 (@base0) {
        say "sol0:";
        my @sol0 = @$sol0;
        while (@sol0) {
            my @row = splice @sol0, 0, $w;
            say "@row";
        }
    }
}
else {
    say "no solution found"
}

