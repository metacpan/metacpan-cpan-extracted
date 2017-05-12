#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Alien::GvaScript' );
}

diag( "Testing Alien::GvaScript $Alien::GvaScript::VERSION, Perl $], $^X" );
