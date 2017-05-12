#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Config::Simple::Inherit' );
}

diag( "Testing Config::Simple::Inherit $Config::Simple::Inherit::VERSION, Perl $], $^X" );
