#!perl -T
# vim:syntax=perl:tabstop=4:number:noexpandtab:

use Test::More tests => 1;

BEGIN {
	use_ok('CHI::Driver::MongoDB') || print "Bail out!";
}

diag( "Testing CHI::Driver::MongoDB  $CHI::Driver::MongoDB::VERSION, Perl $], $^X" );
