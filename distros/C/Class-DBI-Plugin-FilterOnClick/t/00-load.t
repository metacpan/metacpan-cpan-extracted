#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::DBI::Plugin::FilterOnClick' );
}

diag( "Testing Class::DBI::Plugin::FilterOnClick $Class::DBI::Plugin::FilterOnClick::VERSION, Perl $], $^X" );
