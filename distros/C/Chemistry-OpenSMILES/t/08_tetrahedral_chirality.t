#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Writer;
use Test::More;

my @cases = (
    [ 0, 1, 2, 3,  '@',  '@' ],
    [ 0, 1, 2, 3, '@@', '@@' ],
    [ 1, 0, 2, 3,  '@', '@@' ],
    [ 1, 0, 2, 3, '@@',  '@' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    is( tc( $case->[4], @{$case}[0..3] ), $case->[5] );
}

sub tc { &Chemistry::OpenSMILES::Writer::_tetrahedral_chirality }
