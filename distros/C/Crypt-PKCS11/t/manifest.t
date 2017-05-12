#!perl -T

use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;
ok_manifest({
    filter => [
        qr/\.git/,
        qr/\.gcov$/,
        qr/\.gcda$/,
        qr/\.gcno$/,
        qr/\/\.project$/,
        qr/\/\.includepath$/,
        qr/\.o$/,
        qr/\.old$/,
        qr/\/gen\//,
        qr/\/PKCS11\.bs$/,
        qr/\/pkcs11\.c$/,
        qr/\/pkcs11_struct.*\.c$/,
        qr/\/t\/token\.db$/,
        qr/\/cover_db/,
        qr/\/t\/no\.token$/,
        qr/\/t\/tokens\//,
    ]
});
