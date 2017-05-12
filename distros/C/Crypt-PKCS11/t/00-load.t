#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Crypt::PKCS11' ) || print "Bail out!\n";
    new_ok( 'Crypt::PKCS11' ) || print "Bail out!\n";
}

diag( "Testing Crypt::PKCS11 $Crypt::PKCS11::VERSION, Perl $], $^X" );
