#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use List::Util qw( first );
use Test::More;

my @cases = (
    # [ 'C[Co@](F)(Cl)(Br)(I)S',     [ qw( F Co S I C Cl Br ) ], 'F[Co@@](S)(I)(C)(Cl)Br'    ], # Not sure how to interpret this
    [ 'S[Co@OH5](F)(I)(Cl)(C)Br',  [ qw( Br Co C S Cl F I ) ], 'Br([Co@OH9](C((([H][H][H]))))(S([H]))(Cl)(F)(I))'  ],
    [ 'Br[Co@OH12](Cl)(I)(F)(S)C', [ qw( Cl Co C Br F I S ) ], 'Cl([Co@OH15](C((([H][H][H]))))(Br)(F)(I)(S([H])))' ],
    [ 'Cl[Co@OH19](C)(I)(F)(S)Br', [ qw( I Co Cl Br F S C ) ], 'I([Co@OH27](Cl)(Br)(F)(S([H]))(C((([H][H][H])))))' ],
);

plan skip_all => 'not yet implemented' unless $ENV{AUTHOR_TESTING};
plan tests => scalar @cases;

for my $case (@cases) {
    my $parser;
    my @moieties;
    my $result;

    my $order_sub = sub {
        my( $vertices ) = @_;
        for my $symbol (@{$case->[1]}) {
            my $vertex = first { $_->{symbol} eq $symbol } values %$vertices;
            return $vertex if $vertex;
        }
        return values %$vertices;
    };

    $parser = Chemistry::OpenSMILES::Parser->new;
    @moieties = $parser->parse( $case->[0] );

    $result = write_SMILES( \@moieties, $order_sub );
    is( $result, $case->[2] );
}
