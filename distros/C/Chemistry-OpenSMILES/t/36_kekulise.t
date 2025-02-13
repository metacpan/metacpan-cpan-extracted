#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw(is_single_bond);
use Chemistry::OpenSMILES::Aromaticity qw(kekulise);
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use List::Util qw(max);
use Test::More;

eval 'use Graph::Nauty qw(canonical_order)';
plan skip_all => 'no Graph::Nauty' if $@;

my $repeats = 10;

plan tests => 2 * $repeats;

for my $reverse (('', 1) x $repeats) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my( $moiety ) = $parser->parse( 'Cc1c(C)cccc1' );

    if( $reverse ) { # Reverse the atom order if requested
        my $max = max map { $_->{number} } $moiety->vertices;
        for my $atom ($moiety->vertices) {
            $atom->{number} = $max - $atom->{number};
        }
    }

    my @order = canonical_order( $moiety, \&write_SMILES );
    my %order;
    for my $i (0..$#order) {
        $order{$order[$i]} = $i;
    }

    my $order_sub = sub { $order{$_[0]} };
    kekulise( $moiety, $order_sub );

    ok is_single_bond( $moiety, grep { $moiety->degree($_) == 3 } $moiety->vertices );
}
