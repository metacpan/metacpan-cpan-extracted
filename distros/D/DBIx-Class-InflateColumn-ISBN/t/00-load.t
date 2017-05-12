#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Class::InflateColumn::ISBN' );
}

diag( "Testing DBIx::Class::InflateColumn::ISBN $DBIx::Class::InflateColumn::ISBN::VERSION, Perl $], $^X" );
