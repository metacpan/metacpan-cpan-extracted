#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CSS::Packer' );
}

diag( "Testing CSS::Packer $CSS::Packer::VERSION, Perl $], $^X" );
