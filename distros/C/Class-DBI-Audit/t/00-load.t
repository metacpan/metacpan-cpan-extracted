#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::DBI::Audit' );
}

diag( "Testing Class::DBI::Audit $Class::DBI::Audit::VERSION, Perl $], $^X" );
