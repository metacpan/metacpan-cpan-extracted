#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES qw(clean_chiral_centers);
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw(write_SMILES);
use Test::More;

my %cases = (
    'C[C@H2]O'     => 1,
    'C[C@H]([H])O' => 1,
    'C[C@H]([S])O' => 0,
);

plan tests => 2 * scalar keys %cases;

for my $case (sort keys %cases) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( $case, { raw => 1 } );

    is scalar @moieties, 1;
    is scalar clean_chiral_centers( $moieties[0], sub { write_SMILES( $_[0], { raw => 1 } ) } ),
       $cases{$case};
}
