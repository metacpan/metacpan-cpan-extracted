#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Asm::Preproc' ) || print "Bail out!
";
}

diag( "Testing Asm::Preproc $Asm::Preproc::VERSION, Perl $], $^X" );
