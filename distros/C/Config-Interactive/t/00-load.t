#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Config::Interactive' );
}

diag( "Testing Config::Interactive $Config::Interactive::VERSION, Perl $], $^X" );
