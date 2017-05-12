#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Contextual::Call' );
}

diag( "Testing Contextual::Call $Contextual::Call::VERSION, Perl $], $^X" );
