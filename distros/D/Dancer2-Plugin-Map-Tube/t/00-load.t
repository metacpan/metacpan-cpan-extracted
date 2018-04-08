#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok('Dancer2::Plugin::Map::Tube')        || print "Bail out!\n";
    use_ok('Dancer2::Plugin::Map::Tube::API')   || print "Bail out!\n";
    use_ok('Dancer2::Plugin::Map::Tube::Error') || print "Bail out!\n";
}

diag("Testing Dancer2::Plugin::Map::Tube $Dancer2::Plugin::Map::Tube::VERSION, Perl $], $^X");
