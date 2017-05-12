#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AMPR::Rip44' ) || print "Bail out!
";
}

diag( "Testing AMPR::Rip44 $AMPR::Rip44::VERSION, Perl $], $^X" );
