#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::DBI::MockDBD' );
}

diag( "Testing Class::DBI::MockDBD $Class::DBI::MockDBD::VERSION, Perl $], $^X" );
