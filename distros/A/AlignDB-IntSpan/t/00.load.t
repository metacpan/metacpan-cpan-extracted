#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('AlignDB::IntSpan');
}

diag("Testing AlignDB::IntSpan $AlignDB::IntSpan::VERSION");
