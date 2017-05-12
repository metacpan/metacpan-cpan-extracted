#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::CreatingCPANModules' );
}

diag( "Testing Acme::CreatingCPANModules $Acme::CreatingCPANModules::VERSION, Perl $], $^X" );
