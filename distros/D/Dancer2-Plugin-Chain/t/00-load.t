#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('Dancer2::Plugin::Chain')         || print "Bail out!\n";
    use_ok('Dancer2::Plugin::Chain::Router') || print "Bail out!\n";
}

diag("Testing Dancer2::Plugin::Chain $Dancer2::Plugin::Chain::VERSION, Perl $], $^X");
