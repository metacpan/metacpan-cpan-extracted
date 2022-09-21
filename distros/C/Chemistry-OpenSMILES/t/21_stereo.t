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

plan tests => 6;

my $parser = Chemistry::OpenSMILES::Parser->new;
my $moiety;

( $moiety ) = $parser->parse( 'N[C@](Br)(O)C' );
chirality_to_pseudograph( $moiety );

is( $moiety->vertices, 23 );
is( $moiety->edges, 70 );

( $moiety ) = $parser->parse( 'C/C=C/C' );

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

is( $copy->vertices, 12 );
is( $copy->edges, 15 );

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

is( $moiety->vertices, 12 );
is( $moiety->edges, 11 );
