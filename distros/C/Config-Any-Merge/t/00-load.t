#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Config::Any::Merge' );
}

diag( "Testing Config::Any::Merge $Config::Any::Merge::VERSION, Perl $], $^X" );
