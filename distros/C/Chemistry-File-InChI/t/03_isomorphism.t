#!/usr/bin/perl

use strict;
use warnings;

use Chemistry::File::InChI;
use Test::More;

eval 'use Chemistry::File::SMILES';
plan skip_all => 'no Chemistry::File::SMILES' if $@;
eval 'use SmilesScripts::Isomorphism qw(smi_compare)';
plan skip_all => 'no SmilesScripts::Isomorphism' if $@;

my @cases = (
    # Caffeine, from Wikipedia
    [ 'InChI=1S/C8H10N4O2/c1-10-4-9-6-5(10)7(13)12(3)8(14)11(6)2/h4H,1-3H3',
      'CN1C=NC2=C1C(=O)N(C(=O)N2C)C',
      'isomorphic modulo order'
    ],
    # Anthracene, from Wikipedia
    [ 'InChI=1S/C14H10/c1-2-6-12-10-14-8-4-3-7-13(14)9-11(12)5-1/h1-10H',
      'c1ccc2cc3ccccc3cc2c1',
      'isomorphic modulo aromaticity, order'
    ],
    # Monosodium glutamate, from Wikipedia
    [ 'InChI=1S/C5H9NO4.Na/c6-3(5(9)10)1-2-4(7)8;/h3H,1-2,6H2,(H,7,8)(H,9,10);/q;+1/p-1/t3-;/m0./s1',
      '[Na+].O=C([O-])[C@@H](N)CCC(=O)O',
      'isomorphic modulo H atoms, charge, order'
    ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my( $inchi, $smiles, $reason ) = @$case;
    my $mol = Chemistry::File::InChI->parse_string( $inchi );
    my $mol_smiles = $mol->sprintf('%s');
    is smi_compare( $smiles, $mol_smiles ), $reason, $mol_smiles;
}
