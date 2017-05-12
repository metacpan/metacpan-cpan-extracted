#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Authen::Simple::Twitter' );
}

diag( "Testing Authen::Simple::Twitter $Authen::Simple::Twitter::VERSION, Perl $], $^X" );
