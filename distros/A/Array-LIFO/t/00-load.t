#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok 'Array::LIFO';
}

diag("Testing Array::LIFO $Array::LIFO::VERSION, Perl $], $^X");

done_testing();
