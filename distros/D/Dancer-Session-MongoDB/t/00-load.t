#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dancer::Session::MongoDB' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Session::MongoDB $Dancer::Session::MongoDB::VERSION, Perl $], $^X" );
