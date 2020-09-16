#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'C'    => 5,
    'C[U]' => 5,
    'N'    => 4,
    'Cl'   => 2,
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

    'S'                          => 3,
    'S[O]'                       => 3,
    'S([O])([O])'                => 3,
    'S([O])([O])([O])'           => 5,
    'S([O])([O])([O])([O])'      => 5,
    'S([O])([O])([O])([O])([O])' => 7,

    'O([O])'           => 3,
    'O([O])([O])'      => 3,
    'O([O])([O])([O])' => 4,

    'CC'  => 8,
    'C-C' => 8,
    'C=C' => 6,
    'C#C' => 4,
    'C$C' => 2,

    'C1=CC=CC=C1' => 12,
    'c1ccccc1'    => 12,

    'c1cncnc1'    => 10,
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_ );
    is( $graph->vertices, $cases{$_} );
}
