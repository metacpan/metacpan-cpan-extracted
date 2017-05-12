#!perl

use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

BEGIN {
    use_ok ('Crypt::GpgME');
}

my $version;

lives_ok (sub {
        $version = Crypt::GpgME->check_version;
}, 'check_version without arguments');

is ($version, Crypt::GpgME->GPGME_VERSION, 'version looks sane');

lives_ok (sub {
        $version = Crypt::GpgME->check_version( Crypt::GpgME->GPGME_VERSION );
}, 'check_version with current version number');

is ($version, Crypt::GpgME->GPGME_VERSION, 'version matches');

throws_ok (sub {
        $version = Crypt::GpgME->check_version( '10.' . Crypt::GpgME->GPGME_VERSION );
}, qr/version requirement is not met/, 'check_version with future version');
