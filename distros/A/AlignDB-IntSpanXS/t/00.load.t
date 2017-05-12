#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('AlignDB::IntSpanXS');
}

diag("Testing AlignDB::IntSpanXS $AlignDB::IntSpanXS::VERSION");
