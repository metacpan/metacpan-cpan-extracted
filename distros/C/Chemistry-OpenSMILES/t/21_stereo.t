#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw( is_cis_trans_bond );
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo qw(
    chirality_to_pseudograph
    cis_trans_to_pseudoedges
    mark_all_double_bonds
);
use Test::More;

my @cases = (
    [ 'C/C=C/C', 12, 15, 12, 11, 4 ],
    [ 'F/N=C(/F)\F', 5, 4, 5, 4, 0 ],
);

plan tests => 5 * @cases + 2;

my $parser = Chemistry::OpenSMILES::Parser->new;
my $moiety;

( $moiety ) = $parser->parse( 'N[C@](Br)(O)C' );
chirality_to_pseudograph( $moiety );

is( $moiety->vertices, 23 );
is( $moiety->edges, 70 );

for my $case (@cases) {
    my( $smiles,
        $vertices_with_pseudo, $edges_with_pseudo,
        $vertices_when_marked, $edges_when_marked,
        $cis_trans_bonds ) = @$case;
    my( $moiety ) = $parser->parse( $smiles );

    # copy() makes a shallow copy without edge attributes, thus they
    # have to be added later:
    my $copy = $moiety->copy;
    for my $bond ($moiety->edges) {
        next unless $moiety->has_edge_attribute( @$bond, 'bond' );
        $copy->set_edge_attribute( @$bond,
                                   'bond',
                                   $moiety->get_edge_attribute( @$bond, 'bond' ) );
    }
    cis_trans_to_pseudoedges( $copy );

    is( $copy->vertices, $vertices_with_pseudo );
    is( $copy->edges, $edges_with_pseudo );

    # Drop cis/trans markers from the input graph and mark them
    # anew.
    for my $bond ($moiety->edges) {
        next unless is_cis_trans_bond( $moiety, @$bond );
        $moiety->delete_edge_attribute( @$bond, 'bond' );
    }
    mark_all_double_bonds( $moiety,
                           sub {
                                if( $copy->has_edge( $_[0], $_[3] ) &&
                                    $copy->has_edge_attribute( $_[0], $_[3], 'pseudo' ) ) {
                                    return $copy->get_edge_attribute( $_[0], $_[3], 'pseudo' );
                                }
                           } );

    is( $moiety->vertices, $vertices_when_marked );
    is( $moiety->edges, $edges_when_marked );

    is( scalar( grep { is_cis_trans_bond( $moiety, @$_ ) } $moiety->edges ),
        $cis_trans_bonds );
}

# The following test must not throw any warnings

( $moiety ) = $parser->parse( 'C=C=C=C' );

# copy() makes a shallow copy without edge attributes, thus they
# have to be added later:
my $copy = $moiety->copy;
for my $bond ($moiety->edges) {
    next unless $moiety->has_edge_attribute( @$bond, 'bond' );
    $copy->set_edge_attribute( @$bond,
                               'bond',
                               $moiety->get_edge_attribute( @$bond, 'bond' ) );
}

cis_trans_to_pseudoedges( $copy );

# Drop cis/trans markers from the input graph and mark them
# anew.
for my $bond ($moiety->edges) {
    next unless is_cis_trans_bond( $moiety, @$bond );
    $moiety->delete_edge_attribute( @$bond, 'bond' );
}

mark_all_double_bonds( $moiety, [] );
