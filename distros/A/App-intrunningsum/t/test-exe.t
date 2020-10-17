#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

{
    # TEST
    like(
        scalar(`$^X -Ilib bin/intrunningsum t/data/samples/simple.txt`),
        qr#\A24\r?\n25\r?\n925\r?\n?\z#ms,
        "Simple test"
    );
}
