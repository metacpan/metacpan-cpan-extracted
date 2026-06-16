#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw( can_be_aromatic_ring rings );
use Chemistry::OpenSMILES::Parser;
use List::Util qw( first sum );
use Test::More;

my %cases = (
    'c1cccc2ccccc12' => { aromatic => 2, total => 2, 0 => 1, 4 => 2 }
);

plan tests => sum map { scalar %$_ } values %cases;

for my $SMILES (sort keys %cases) {
    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse(  $SMILES );
    for my $key (sort keys %{$cases{$SMILES}}) {
        if(      $key eq 'aromatic' ) {
            my $aromatic_rings = grep { can_be_aromatic_ring( @$_ ) } rings $graph;
            is $aromatic_rings, $cases{$SMILES}->{$key}, "aromatic rings in $SMILES";
        } elsif( $key eq 'total' ) {
            is rings( $graph ), $cases{$SMILES}->{$key}, "total rings in $SMILES";
        } else {
            my $atom = first { $_->{number} == $key } $graph->vertices;
            is rings( $graph, $atom ), $cases{$SMILES}->{$key}, "rings at atom $key";
        }
    }
}
