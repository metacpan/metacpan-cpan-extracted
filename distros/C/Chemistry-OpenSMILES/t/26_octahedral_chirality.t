#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo qw( chirality_to_pseudograph );
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use List::Util qw( first );
use Test::More;

my @cases = (
    [ 'C[Co@](F)(Cl)(Br)(I)S',     [ qw( C Co F Cl Br I S ) ], 'C([Co@OH1](F)(Cl)(Br)(I)(S([H])))([H])([H])([H])'  ],
    [ 'C[Co@](F)(Cl)(Br)(I)S',     [ qw( F Co S I C Cl Br ) ], 'F([Co@OH2](S([H]))(I)(C([H])([H])([H]))(Cl)(Br))'  ],
    [ 'S[Co@OH5](F)(I)(Cl)(C)Br',  [ qw( Br Co C S Cl F I ) ], 'Br([Co@OH9](C([H])([H])([H]))(S([H]))(Cl)(F)(I))'  ],
    [ 'Br[Co@OH12](Cl)(I)(F)(S)C', [ qw( Cl Co C Br F I S ) ], 'Cl([Co@OH15](C([H])([H])([H]))(Br)(F)(I)(S([H])))' ],
    [ 'Cl[Co@OH19](C)(I)(F)(S)Br', [ qw( I Co Cl Br F S C ) ], 'I([Co@OH27](Cl)(Br)(F)(S([H]))(C([H])([H])([H])))' ],
);

eval 'use Graph::Nauty qw( are_isomorphic )';
my $has_Graph_Nauty = !$@;

plan tests => @cases + $has_Graph_Nauty * @cases;

for my $case (@cases) {
    my( $input, $order, $output ) = @$case;

    my $parser;
    my @moieties;
    my $result;

    my $order_sub = sub {
        my $vertices = shift;
        for my $symbol (@$order) {
            my $vertex = first { $_->{symbol} eq $symbol } values %$vertices;
            return $vertex if $vertex;
        }
        my( $vertex ) = values %$vertices;
        return $vertex;
    };

    $parser = Chemistry::OpenSMILES::Parser->new;
    my( $input_moiety ) = $parser->parse( $input );

    $result = write_SMILES( [ $input_moiety ], { order_sub => $order_sub } );
    is $result, $output, $input;

    next unless $has_Graph_Nauty;

    my( $output_moiety ) = $parser->parse( $output );
    for ( $input_moiety, $output_moiety ) {
        chirality_to_pseudograph( $_ );
    }
    ok are_isomorphic( $input_moiety, $output_moiety, \&depict );
}

sub depict
{
    my( $vertex ) = @_;

    return '' unless exists $vertex->{symbol};

    $vertex = { %$vertex };
    delete $vertex->{chirality};
    return write_SMILES( $vertex );
}
