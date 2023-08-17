#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw( is_ring_atom is_ring_bond );
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'CN1C=NC2=C1C(=O)N(C(=O)N2C)C' => { atoms => 9, bonds => 10 },
);

plan tests => 4 * scalar keys %cases;

for my $case (sort keys %cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my( $molecule ) = $parser->parse( $case );

    is scalar( grep { is_ring_atom( $molecule, $_ ) } $molecule->vertices ),
       $cases{$case}->{atoms};
    is scalar( grep { is_ring_bond( $molecule, @$_ ) } $molecule->edges ),
       $cases{$case}->{bonds};

    is scalar( grep { is_ring_atom( $molecule, $_, -1 ) } $molecule->vertices ),
       $cases{$case}->{atoms};
    is scalar( grep { is_ring_bond( $molecule, @$_, -1 ) } $molecule->edges ),
       $cases{$case}->{bonds};
}
