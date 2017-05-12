#!perl

use Test::More tests => 3;

use Crypt::PKCS11;

BEGIN {
    is( Crypt::PKCS11::XS::SvUOK(1), 1, 'SvUOK(1)' );
    isnt( Crypt::PKCS11::XS::SvUOK(-1), 1, 'SvUOK(-1)' );
    is( Crypt::PKCS11::XS::SvUOK('1'), 0, 'SvUOK("1")' );
}
