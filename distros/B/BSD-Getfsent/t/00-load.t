#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('BSD::Getfsent');
}

diag("Testing BSD::Getfsent $BSD::Getfsent::VERSION, Perl $], $^X");
