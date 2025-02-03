#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my @cases = (
    # OpenSMILES specification v1.0
    [ 'F/C=C=C=C/F', '4' ],
    [ 'F/C=C=C=C\F', '4' ],
    [ 'NC(Br)=[C@]=C(O)C', '3' ],
);

plan tests => 3 * scalar @cases;

for (@cases) {
    my( $smiles, $result ) = @$_;
    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $smiles );
    my $allenes = Chemistry::OpenSMILES::_allene_graph( $graph );
    is join( ',', map { scalar @$_ } $allenes->connected_components ), $result;

    my $end_edges = grep { $allenes->has_edge_attribute( @$_, 'allene' ) &&
                           $allenes->get_edge_attribute( @$_, 'allene' ) eq 'end' }
                         $allenes->edges;
    my $mid_edges = grep { $allenes->has_edge_attribute( @$_, 'allene' ) &&
                           $allenes->get_edge_attribute( @$_, 'allene' ) eq 'mid' }
                         $allenes->edges;

    is $end_edges, scalar $allenes->connected_components, 'end edges';
    is $mid_edges, 2 * (grep { @$_ % 2 } $allenes->connected_components), 'mid edges';
}
