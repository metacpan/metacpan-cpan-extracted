#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Aromaticity qw( aromatise kekulise );
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use Test::More;

my @cases = (
    [ 'C1=CC=CC=C1',
      'c:1(:c(:c(:c(:c(:c:1([H]))([H]))([H]))([H]))([H]))([H])',
      'C=1(C(=C(C(=C(C=1([H]))([H]))([H]))([H]))([H]))([H])' ],

    [ 'C1=CC=CC=C1C1=CC=CC=C1',
      'c:1(:c(:c(:c(:c(:c:1(-c:1(:c(:c(:c(:c(:c:1([H]))([H]))([H]))([H]))([H]))))([H]))([H]))([H]))([H]))([H])',
      'C=1(C(=C(C(=C(C=1(C=1(C(=C(C(=C(C=1([H]))([H]))([H]))([H]))([H]))))([H]))([H]))([H]))([H]))([H])' ],
);

plan tests => 2 * scalar @cases;

for my $case (@cases) {
    my $result;

    my $parser = Chemistry::OpenSMILES::Parser->new;
    my( $moiety ) = $parser->parse( $case->[0] );

    aromatise( $moiety );
    $result = write_SMILES( [ $moiety ] );
    is $result, $case->[1];

    kekulise( $moiety );
    $result = write_SMILES( [ $moiety ] );
    is $result, $case->[2];
}
