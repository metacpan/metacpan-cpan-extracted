#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Asm::X86' );
}

diag( "Testing Asm::X86 $Asm::X86::VERSION, Perl $], $^X" );
