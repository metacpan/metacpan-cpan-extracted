#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Dictionary' );
}

diag( "Testing DBIx::Dictionary $DBIx::Dictionary::VERSION, Perl $], $^X" );
