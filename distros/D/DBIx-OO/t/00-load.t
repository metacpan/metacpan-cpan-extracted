#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'DBIx::OO' );
        use_ok( 'DBIx::OO::Tree' );
}

diag( "Testing DBIx::OO $DBIx::OO::VERSION, Perl $], $^X" );
