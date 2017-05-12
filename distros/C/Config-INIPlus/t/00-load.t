#!perl -T

use Test::More tests => 1; 

BEGIN {
	use_ok( 'Config::INIPlus' );
}

diag( "Testing Config::INIPlus $Config::INIPlus::VERSION, Perl $], $^X" );

