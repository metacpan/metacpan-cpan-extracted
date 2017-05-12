#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'AnyEvent::EditText' );
}

diag( "Testing AnyEvent::EditText $AnyEvent::EditText::VERSION, Perl $], $^X" );
