#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::ECDSA::Blind' ) || print "Bail out!
";
}

diag( "Testing Crypt::ECDSA::Blind $Crypt::ECDSA::Blind::VERSION, Perl $], $^X" );
