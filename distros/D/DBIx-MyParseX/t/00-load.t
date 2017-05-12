#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'DBIx::MyParseX' );
	use_ok( 'DBIx::MyParseX::Item' );
	use_ok( 'DBIx::MyParseX::Query' );
}

diag( "Testing DBIx::MyParseX $DBIx::MyParseX::VERSION, Perl $], $^X" );
