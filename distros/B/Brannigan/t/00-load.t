#!/usr/bin/env perl

use lib './lib';
use warnings;
use strict;

use Test2::V0;

BEGIN {
    use ok 'Brannigan';
}

diag("Testing Brannigan $Brannigan::VERSION, Perl $], $^X");

done_testing();
