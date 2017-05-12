#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::BottomsUp' );
}

diag( "Testing Acme::BottomsUp $Acme::BottomsUp::VERSION, Perl $], $^X" );
