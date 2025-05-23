#!/usr/bin/perl

use strict;
use warnings;

use Chemistry::OpenSMILES qw( mirror );
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo qw( chirality_to_pseudograph );
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use Data::Dumper;
use Test::More;

my @cases = (
    [ 'N[C@](Br)(O)C', 'N[C@](Br)(O)C', 'C[C@](O)(Br)N' ],
    [ 'Br[C@](O)(N)C', 'Br[C@](O)(N)C', 'C[C@](N)(O)Br' ],
    [ 'O[C@](Br)(C)N', 'O[C@](Br)(C)N', 'N[C@](C)(Br)O' ],
    [ 'Br[C@](C)(O)N', 'Br[C@](C)(O)N', 'N[C@](O)(C)Br' ],
    [ 'C[C@](Br)(N)O', 'C[C@](Br)(N)O', 'O[C@](N)(Br)C' ],
    [ 'Br[C@](N)(C)O', 'Br[C@](N)(C)O', 'O[C@](C)(N)Br' ],
    [ 'C[C@@](Br)(O)N', 'C[C@@](Br)(O)N', 'N[C@@](O)(Br)C' ],
    [ 'Br[C@@](N)(O)C', 'Br[C@@](N)(O)C', 'C[C@@](O)(N)Br' ],
    [ '[C@@](C)(Br)(O)N', '[C@@](C)(Br)(O)N', 'N[C@@](O)(Br)C' ],
    [ '[C@@](Br)(N)(O)C', '[C@@](Br)(N)(O)C', 'C[C@@](O)(N)Br' ],
    [ 'C1OCC[C@]1(Cl)Br', 'C1OCC[C@]1(Cl)Br', 'Br[C@@]1(Cl)CCOC1' ],
);

eval 'use Graph::Nauty qw( are_isomorphic )';
my $has_Graph_Nauty = !$@;

plan tests => 2 * @cases + $has_Graph_Nauty * 3 * @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0], { raw => 1 } );

    $result = write_SMILES( \@moieties, { raw => 1 } );
    is $result, $case->[1];

    $result = write_SMILES( \@moieties, { raw => 1, order_sub => \&reverse_order } );
    is $result, $case->[2];

    next unless $has_Graph_Nauty;

    # Ensuring the SMILES representations describe isomorphic graphs
    my @graphs = map { $parser->parse( $_ ) } @$case, $case->[0];
    mirror $graphs[3];
    for (@graphs) {
        chirality_to_pseudograph( $_ );
    }
    ok  are_isomorphic( $graphs[0], $graphs[1], \&depict );
    ok  are_isomorphic( $graphs[1], $graphs[2], \&depict );
    ok !are_isomorphic( $graphs[0], $graphs[3], \&depict );
}

sub depict
{
    my( $vertex ) = @_;

    if( ref $vertex eq 'HASH' && exists $vertex->{symbol} ) {
        $vertex = { %$vertex };
        delete $vertex->{chirality};
        return write_SMILES( $vertex );
    }

    return Dumper $vertex;
}

sub reverse_order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$b}{number} <=>
                        $vertices->{$a}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}
