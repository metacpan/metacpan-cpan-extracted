#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Controller::AllowDisable' );
}

diag( "Testing Catalyst::Controller::AllowDisable $Catalyst::Controller::AllowDisable::VERSION, Perl $], $^X" );
