#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::EC_DSA' ) || print "Bail out!
";
}

diag( "Testing Crypt::EC_DSA $Crypt::EC_DSA::VERSION, Perl $], $^X" );
