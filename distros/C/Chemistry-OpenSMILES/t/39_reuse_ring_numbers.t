#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my @cases = (
    # These are synthetic SMILES as they are easier to compare
    [ 'O1OOOOC12OOOOO2', 'O1OOOOC12OOOOO2', 'O1OOOOC11OOOOO1' ],
    [ 'O1OOOOC1=C1OOOOO1', 'O1OOOOC1=C1OOOOO1', 'O1OOOOC1=C1OOOOO1' ],
    [ 'O1OOOOC1=C2OOOOO2', 'O1OOOOC1=C1OOOOO1', 'O1OOOOC1=C1OOOOO1' ],
);

plan tests => 2 * scalar @cases;

for my $case (@cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( $case->[0] );

    my $not_reused = write_SMILES( \@moieties, { immediately_reuse_ring_numbers => '' } );
    is $not_reused, $case->[1];

    my $reused = write_SMILES( \@moieties );
    is $reused, $case->[2];
}
