#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    [ 'C', 'C' ],
    [ 'C=C', 'C(=C)' ],
    [ 'C=1=C=C=C=1', 'C=1(=C(=C(=C=1)))' ],
    [ 'C#C.c1ccccc1', 'C(#C).c1(c(c(c(c(c1)))))' ],
    [ 'C1CC2CCCCC2CC1', 'C1(C(C2(C(C(C(C(C2(C(C1)))))))))' ],
    # A strange way to write fused rings:
    [ 'C1(CCCCC11)(CCCC1)', 'C12(C(C(C(C(C1(C(C(C(C2)))))))))', 'C12CCCCC1CCCC2' ],
    # Single bonds between two aromatic atoms must be explicitly represented:
    [ 'c1cc-ccc1', 'c1(c(c(-c(c(c1)))))' ],
    # Chirality information is preserved:
    [ 'N[C@](Br)(O)C', 'N([C@](Br)(O)(C))' ],
    [ 'N[C@@](Br)(O)C', 'N([C@@](Br)(O)(C))' ],
    # A regression test for previously incorrectly identified aromatic bond:
    [ 'c1(c(cccc1)F)C(=O)[O-]', 'c1(c(c(c(c(c1))))(F))(C(=O)([O-]))' ],
    # Cyclooctatetraene adapted from OpenSMILES v1.0 specification:
    [ 'C/1=C/C=C\C=C/C=C\1', 'C/1(=C(/C(=C(\C(=C(/C(=C\1)))))))' ],
    # A regression test for improperly recorded fact that 0 H atoms are present:
    [ '[C]#[O]', '[C](#[O])' ],
    # Regression cases for https://github.com/merkys/Chemistry-OpenSMILES/issues/11
    [ 'C(C.[Cu])', 'C(C).[Cu]', 'CC.[Cu]' ],
    [ 'C(C.[Cu])C', 'C(C)(C).[Cu]', 'C(C)C.[Cu]' ],
);

plan tests => 4 * @cases + grep { @$_ == 3 && $_->[2] =~ /:/ } @cases;

my $parser = Chemistry::OpenSMILES::Parser->new;

for my $case (@cases) {
    my @moieties;
    my $result;

    @moieties = $parser->parse( $case->[0], { raw => 1 } );
    $result = write_SMILES( \@moieties, { raw => 1, explicit_parentheses => 1 } );
    is $result, $case->[1];

    @moieties = $parser->parse( $result, { raw => 1 } );
    $result = write_SMILES( \@moieties, { raw => 1, explicit_parentheses => 1 } );
    is $result, $case->[1];

    my $output = @$case == 3 ? $case->[2] : $case->[0];
    @moieties = $parser->parse( $case->[0], { raw => 1 } );
    $result = write_SMILES( \@moieties, { raw => 1 } );
    is $result, $output;

    @moieties = $parser->parse( $result, { raw => 1 } );
    $result = write_SMILES( \@moieties, { raw => 1 } );
    is $result, $output;

    if( @$case == 3 && $case->[2] =~ /:/ ) {
        @moieties = $parser->parse( $case->[0], { raw => 1 } );
        $output =~ s/://g;
        $result = write_SMILES( \@moieties, { raw => 1, explicit_aromatic_bonds => 0 } );
        is $result, $output;
    }
}
