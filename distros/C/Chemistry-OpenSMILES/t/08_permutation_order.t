#!/usr/bin/perl

use strict;
use warnings;

use Chemistry::OpenSMILES::Writer;
use Test::More;

my $cases = 20;

plan tests => $cases;

for (1..$cases) {
    my @order = 0..3;
    for (0..9) {
        if( rand() < 0.5 ) {
            @order = ( @order[1..2], $order[0], $order[3] );
        } else {
            @order = ( $order[0], @order[2..3], $order[1] );
        }
    }
    # is( join( '', @order ), '0123' );
    is( join( '', Chemistry::OpenSMILES::Writer::_permutation_order( @order ) ),
        '0123' );
}
