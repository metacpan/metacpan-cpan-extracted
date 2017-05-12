#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'DateTimeX::Format' );
	use_ok( 'DateTimeX::Format::CustomPattern' );
}

diag( "Testing DateTimeX::Format $DateTimeX::Format::VERSION, Perl $], $^X" );
