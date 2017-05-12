#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::MoCo::Pageset' );
}

diag( "Testing DBIx::MoCo::Pageset $DBIx::MoCo::Pageset::VERSION, Perl $], $^X" );
