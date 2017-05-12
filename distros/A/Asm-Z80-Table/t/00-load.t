#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Asm::Z80::Table' ) || print "Bail out!
";
}

diag( "Testing Asm::Z80::Table $Asm::Z80::Table::VERSION, Perl $], $^X" );
