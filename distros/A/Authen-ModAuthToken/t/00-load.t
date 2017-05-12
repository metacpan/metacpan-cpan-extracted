#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Authen::ModAuthToken' ) || print "Bail out!
";
}

diag( "Testing Authen::ModAuthToken $Authen::ModAuthToken::VERSION, Perl $], $^X" );
