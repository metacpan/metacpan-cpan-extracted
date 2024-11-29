#!/usr/bin/perl

use strict;
use warnings;

use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo qw( chirality_to_pseudograph );
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use Data::Dumper;
use Test::More;

my @cases = (
    [ 'N[C@SP1](Br)(O)C', 'N([C@SP1](Br)(O)(C))', 'C([C@SP1](O)(Br)(N))' ],
    [ 'N[C@SP2](Br)(O)C', 'N([C@SP2](Br)(O)(C))', 'C([C@SP2](O)(Br)(N))' ],
    [ 'N[C@SP3](Br)(O)C', 'N([C@SP3](Br)(O)(C))', 'C([C@SP3](O)(Br)(N))' ],
);

eval 'use Graph::Nauty qw( are_isomorphic )';
my $has_Graph_Nauty = !$@;

plan tests => 2 * @cases + $has_Graph_Nauty * 2 * @cases;

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
    my @graphs = map { $parser->parse( $_ ) } @$case;
    for (@graphs) {
        chirality_to_pseudograph( $_ );
    }
    ok are_isomorphic( $graphs[0], $graphs[1], \&depict );
    ok are_isomorphic( $graphs[1], $graphs[2], \&depict );
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
