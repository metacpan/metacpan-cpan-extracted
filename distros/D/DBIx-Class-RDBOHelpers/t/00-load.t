#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Class::RDBOHelpers' );
}

diag( "Testing DBIx::Class::RDBOHelpers $DBIx::Class::RDBOHelpers::VERSION, Perl $], $^X" );
diag( "DBIx::Class VERSION=$DBIx::Class::VERSION" );
