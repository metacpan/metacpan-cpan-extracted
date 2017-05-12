#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Config::Apt::Sources' );
}

diag( "Testing Config::Apt::Sources $Config::Apt::Sources::VERSION, Perl $], $^X" );
