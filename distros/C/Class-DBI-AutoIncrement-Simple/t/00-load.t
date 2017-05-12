#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::DBI::AutoIncrement::Simple' );
}

diag( "Testing Class::DBI::AutoIncrement::Simple $Class::DBI::AutoIncrement::Simple::VERSION, Perl $], $^X" );
