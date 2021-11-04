#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    '[YbH12+3]' => 13,
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_, { max_hydrogen_count_digits => 2 } );
    is( $graph->vertices, $cases{$_} );
}
