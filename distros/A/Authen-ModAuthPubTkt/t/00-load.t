#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Authen::ModAuthPubTkt' ) || print "Bail out!
";
}

diag( "Testing Authen::ModAuthPubTkt $Authen::ModAuthPubTkt::VERSION, Perl $], $^X" );
