#!perl 

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Magic::Pony' );
}

diag( "Testing Acme::Magic::Pony $Acme::Magic::Pony::VERSION, Perl $], $^X" );
