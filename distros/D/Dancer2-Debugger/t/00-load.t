#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Debugger' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Debugger $Dancer2::Debugger::VERSION, Perl $], $^X" );
