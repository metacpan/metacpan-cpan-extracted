#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Class::Helper::ResultSet::CrossTab' );
}

diag( "Testing DBIx::Class::Helper::ResultSet::CrossTab, Perl $], $^X" );
