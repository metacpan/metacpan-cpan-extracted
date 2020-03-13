#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

{
    # TEST
    like(
        scalar(`$^X -Ilib bin/prefixintsumcol t/data/samples/simple.txt`),
        qr#\A24\t24\r?\n25\t1\r?\n925\t900\r?\n?\z#ms,
        "Simple test"
    );
}
