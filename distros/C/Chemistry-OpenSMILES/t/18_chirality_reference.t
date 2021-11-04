#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw( is_chiral );
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'C[C@@](Br)(O)N'         => 0,
    'Br[C@@](N)(O)C'         => 0,
    '[C@@](C)(Br)(O)N'       => 1,
    '[C@@](Br)(N)(O)C'       => 1,
    'FC1C[C@](Br)(Cl)CCC1'   => 2,
	'[C@]1(Br)(Cl)CCCC(F)C1' => 8,
    'C1.[C@]1(Br)(Cl)O'      => 0,
    'C(CCCC1)[C@]1(Br)(Cl)'  => 0,
    'C([C@](Br)(Cl)O)C'      => 0,
);

plan tests => 3 * scalar keys %cases;

for (sort keys %cases) {
    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_ );

    my( $chiral_center ) = grep { is_chiral $_ } $graph->vertices;
    ok( defined $chiral_center );
    ok( exists $chiral_center->{chirality_neighbours} );
    is( $chiral_center->{chirality_neighbours}[0]{number}, $cases{$_} );
}
