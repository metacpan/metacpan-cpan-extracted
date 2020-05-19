#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'C'    => 1,
    'N'    => 1,
    'Cl'   => 1,
    '[U]'  => 1,
    '[Pb]' => 1,
    '[He]' => 1,
    '[*]'  => 1,
    '[CH4]'   => 5,
    '[ClH]'   => 2,
    '[ClH1]'  => 2,
    '[Cl-]'   => 1,
    '[OH1-]'  => 2,
    '[OH-1]'  => 2,
    '[Cu+2]'  => 1,
    '[Cu++]'  => 1,
    '[13CH4]' => 5,
    '[2H+]'   => 1,
    '[238U]'  => 1,
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_ );
    is( $graph->vertices, $cases{$_} );
}
