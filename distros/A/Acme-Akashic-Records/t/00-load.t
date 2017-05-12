#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Akashic::Records' ) || print "Bail out!
";
}

diag( "Testing Acme::Akashic::Records $Acme::Akashic::Records::VERSION, Perl $], $^X" );
