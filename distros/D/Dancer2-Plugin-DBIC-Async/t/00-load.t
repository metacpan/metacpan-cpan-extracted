#!/usr/bin/env perl

use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok('Dancer2::Plugin::DBIC::Async') || print "Bail out!\n";
}

diag( "Testing Dancer2::Plugin:DBIC::Async $Dancer2::Plugin::DBIC::Async::VERSION, Perl $], $^X" );
