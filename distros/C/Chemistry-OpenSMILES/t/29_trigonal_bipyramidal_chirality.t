#!/usr/bin/perl

use strict;
use warnings;

use Algorithm::Combinatorics qw( permutations );
use Chemistry::OpenSMILES::Writer;
use Test::More;

my @order_permutations = permutations( [ 0..4 ] );

plan tests => @order_permutations * 20;

for my $permutation (@order_permutations) {
    for (1..20) {
        my $chirality = Chemistry::OpenSMILES::Writer::_trigonal_bipyramidal_chirality( @$permutation, '@TB' . $_ );
        my @reverse_permutation = reverse_permutation( @$permutation );
        is Chemistry::OpenSMILES::Writer::_trigonal_bipyramidal_chirality( @reverse_permutation, $chirality ),
           '@TB' . $_;
    }
}

sub reverse_permutation
{
    my @order = @_;
    return sort { $order[$a] <=> $order[$b] } 0..$#order;
}
