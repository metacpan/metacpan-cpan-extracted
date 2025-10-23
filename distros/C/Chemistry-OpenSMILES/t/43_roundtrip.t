#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use List::Util qw( first );
use Test::More;

my @cases = (
    [ qw( [O-]Cl(=O)=O [O-][Cl](=O)=O ) ],                                           # COD entry 1001127
    [ qw( O1C2CCCc3c2c(ccc3OC)c2ccccc2C1=O O1C2CCCc3c2[c](ccc3OC)[c]2ccccc2C1=O ) ], # COD entry 1100141
    [ qw( [C@H](C)(c1ccccc1)N(C(=O)C)[C@@H](CO)Cc1ccccc1 ) ],                        # COD entry 1100535
    [ qw( [C@@H]1(CCC[C@H](CCC)[NH2+]1)C ) ],                                        # COD entry 1501805 (partial)
    [ qw( [NH3]=O ) ],
);

plan tests => scalar @cases;

my $parser = Chemistry::OpenSMILES::Parser->new;

for my $case (@cases) {
    my( $input, $output ) = @$case;
    $output = $input unless $output;

    my( $moiety ) = $parser->parse( $input );
    my $result = write_SMILES( [ $moiety ], { explicit_aromatic_bonds => '',
                                              remove_implicit_hydrogens => 1,
                                              unsprout_hydrogens => 1 } );
    is $result, $output, $input;
}
