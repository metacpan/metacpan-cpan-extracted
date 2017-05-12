#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::NamedBinding' );
}

diag( "Testing DBIx::NamedBinding $DBIx::NamedBinding::VERSION, Perl $], $^X" );
