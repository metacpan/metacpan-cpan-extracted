#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::RSA::Blind' ) || print "Bail out!\n";
}

diag( "Testing Crypt::RSA::Blind $Crypt::RSA::Blind::VERSION, Perl $], $^X" );
