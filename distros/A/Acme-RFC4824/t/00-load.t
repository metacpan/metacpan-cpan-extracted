#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::RFC4824' );
}

diag( "Testing Acme::RFC4824 $Acme::RFC4824::VERSION, Perl $], $^X" );
