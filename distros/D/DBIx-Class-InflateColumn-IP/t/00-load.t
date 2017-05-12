#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Class::InflateColumn::IP' );
}

diag( "Testing DBIx::Class::InflateColumn::IP $DBIx::Class::InflateColumn::IP::VERSION, Perl $], $^X" );
