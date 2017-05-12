#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Class::PhoneticSearch' );
}

diag( "Testing DBIx::Class::PhoneticSearch $DBIx::Class::PhoneticSearch::VERSION, Perl $], $^X" );
