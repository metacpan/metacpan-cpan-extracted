#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use Test::More;

my @cases = qw(
    C       N      Cl     *
    [U]     [Pb]   [He]
    [CH4]   [ClH]
    [Cl-]   [Cu+2]
    [13CH4] [2H+]  [238U]
);

my %cases = (
    '[*]'     => '[*]',
    '[ClH1]'  => '[ClH]',
    '[Cu++]'  => '[Cu+2]',
    '[OH-1]'  => '[OH-]',
    '[OH1-]'  => '[OH-]',
    # '[C@TH1]' => '[C@TH1]', # These no longer make any sense even in raw parsing
    # '[C@TH2]' => '[C@TH2]', # These no longer make any sense even in raw parsing
    '[C]'     => '[C]',
    map { $_  => $_ } @cases,
);

plan tests => 2 * scalar keys %cases;

for (sort keys %cases) {
    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_, { raw => 1 } );

    is $graph->vertices, 1;
    is write_SMILES( $graph, { raw => 1 } ), $cases{$_};
}
