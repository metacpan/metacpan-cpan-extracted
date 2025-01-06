#!/usr/bin/perl

use strict;
use warnings;

use Chemistry::OpenSMILES::Writer;
use Test::More;

my @cases = (
    [ qw( 0 1 2 3 4 @TB1 @TB1 ) ],
    [ qw( 0 1 3 2 4 @TB1 @TB2 ) ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my $result = pop @$case;
    is Chemistry::OpenSMILES::Writer::_trigonal_bipyramidal_chirality( @$case ), $result;
}
