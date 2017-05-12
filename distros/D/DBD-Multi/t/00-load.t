#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBD::Multi' );
}

diag( "Testing DBD::Multi $DBD::Multi::VERSION, Perl $], $^X" );
