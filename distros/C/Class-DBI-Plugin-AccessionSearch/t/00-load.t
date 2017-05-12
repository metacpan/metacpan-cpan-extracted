#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::DBI::Plugin::AccessionSearch' );
}

diag( "Testing Class::DBI::Plugin::AccessionSearch $Class::DBI::Plugin::AccessionSearch::VERSION, Perl $], $^X" );
