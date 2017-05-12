#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Authen::Class::HtAuth' );
}

diag( "Testing Authen::Class::HtAuth $Authen::Class::HtAuth::VERSION, Perl $], $^X" );
