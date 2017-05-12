#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Config::Singleton' );
}

diag( "Testing Config::Singleton $Config::Singleton::VERSION, Perl $], $^X" );
