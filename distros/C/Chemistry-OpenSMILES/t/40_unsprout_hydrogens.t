#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'C', '[CH4]', 'C' ],
    [ '[CH4]', '[CH4]', 'C' ],
    [ 'C([H])([H])([H])[H]', '[CH4]', 'C' ],
    [ '[C]([H])([H])([H])[H]', '[CH4]', 'C' ],

    [ 'C=C', '[CH2]=[CH2]', 'C=C' ],
    [ 'C=1=C=C=C=1', 'C=1=C=C=C=1', 'C=1=C=C=C=1' ],

    [ 'F[C@](Br)(Cl)[H]', 'F[C@H](Br)Cl', 'F[C@H](Br)Cl' ],
    [ 'F[C@](Br)([H])Cl', 'F[C@@H](Br)Cl', 'F[C@@H](Br)Cl' ],
    [ 'F[C@H](Br)Cl', 'F[C@H](Br)Cl', 'F[C@H](Br)Cl' ],

    [ 'Cl/C=C/Cl', 'Cl/[CH]=[CH]/Cl', 'Cl/C=C/Cl' ],
    [ 'Cl/C=C(/Cl)\[H]', 'Cl/[CH]=[CH]/Cl', 'Cl/C=C/Cl' ],

    [ '[H]C([H])([H])[H]', '[CH4]', 'C' ],
    [ '[H][C@](F)(Br)Cl', '[C@H](F)(Br)Cl', '[C@H](F)(Br)Cl' ],

    [ '[H][H]', '[H][H]', '[H][H]' ],
    [ '[O][H][O]', '[O][H][O]', '[O][H][O]' ],
    [ '[H]1CCCC1', '[H]1[CH2][CH2][CH2][CH2]1', '[H]1CCCC1' ],

    [ '[C@](C)(C)(O)([H])', '[C@@H]([CH3])([CH3])[OH]', '[C@@H](C)(C)O' ],
    [ '[C@](C)(F)(O)([H])', '[C@@H]([CH3])(F)[OH]', '[C@@H](C)(F)O' ],
);

plan tests => 2 * scalar @cases;

my $parser = Chemistry::OpenSMILES::Parser->new;

for my $case (@cases) {
    my @moieties = $parser->parse( $case->[0] );

    is write_SMILES( \@moieties, { remove_implicit_hydrogens => '' } ), $case->[1];
    is write_SMILES( \@moieties ), $case->[2];
}
