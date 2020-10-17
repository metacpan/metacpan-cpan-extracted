#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

{
    # TEST
    like( scalar(`$^X -Ilib bin/intsum t/data/samples/simple.txt`),
        qr#\A925$#ms, "Simple test" );

    # TEST
    like(
        scalar(
`$^X -Ilib bin/intsum t/data/samples/simple.txt t/data/samples/bigints.txt`
        ),
        qr#\A400000000000000000000000000000000000000000000000925#ms,
        "Simple test"
    );
}

