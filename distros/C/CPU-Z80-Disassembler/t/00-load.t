#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CPU::Z80::Disassembler' ) || print "Bail out!
";
}

diag( "Testing CPU::Z80::Disassembler $CPU::Z80::Disassembler::VERSION, Perl $], $^X" );
