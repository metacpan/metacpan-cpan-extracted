#!perl

use 5.10.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::Routing' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Plugin::Routing $Dancer2::Plugin::Routing::VERSION, Perl $], $^X" );
