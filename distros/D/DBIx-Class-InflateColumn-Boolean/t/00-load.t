#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Class::InflateColumn::Boolean' );
}

diag( "Testing DBIx::Class::InflateColumn::Boolean $DBIx::Class::InflateColumn::Boolean::VERSION, Perl $], $^X" );
