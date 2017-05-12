#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::DBI::SQL::Transformer::Quotify' );
}

diag( "Testing Class::DBI::SQL::Transformer::Quotify $Class::DBI::SQL::Transformer::Quotify::VERSION, Perl $], $^X" );
