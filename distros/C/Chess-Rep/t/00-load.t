#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Chess::Rep' );
}

diag( "Testing Chess::Rep $Chess::Rep::VERSION, Perl $], $^X" );
