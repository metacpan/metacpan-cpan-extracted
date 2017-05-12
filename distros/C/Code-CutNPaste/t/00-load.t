#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Code::CutNPaste' ) || print "Bail out!\n";
}

diag( "Testing Code::CutNPaste $Code::CutNPaste::VERSION, Perl $], $^X" );
