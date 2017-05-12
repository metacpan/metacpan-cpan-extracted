#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Authen::Simple::WebForm' );
}

diag( "Testing Authen::Simple::WebForm $Authen::Simple::WebForm::VERSION, Perl $], $^X" );
