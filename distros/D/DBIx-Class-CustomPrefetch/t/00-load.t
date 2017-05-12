#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Class::CustomPrefetch' );
}

diag( "Testing DBIx::Class::CustomPrefetch $DBIx::Class::CustomPrefetch::VERSION, Perl $], $^X" );
