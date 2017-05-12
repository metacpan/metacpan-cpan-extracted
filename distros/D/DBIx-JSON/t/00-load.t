#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::JSON' );
}

diag( "Testing DBIx::JSON $DBIx::JSON::VERSION, Perl $], $^X" );
