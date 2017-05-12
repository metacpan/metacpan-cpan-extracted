#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Chooser' );
}

diag( "Testing Chooser $Chooser::VERSION, Perl $], $^X" );
