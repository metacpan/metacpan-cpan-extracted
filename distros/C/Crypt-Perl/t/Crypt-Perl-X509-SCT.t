#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Crypt::Perl::X509::SCT;

my @ins = (
    key_id => pack('H*', 'ee4bbdb775ce60bae142691fabe19e66a30f7e5fb072d88300c47b897aa8fdcb' ),
    timestamp => 1525595688748, #May  6 08:34:48.748 2018 GMT
    hash_algorithm => 'sha256',
    signature_algorithm => 'ecdsa',
    signature => pack('H*', '3045022100ce5d57c1fa9326efccec455bb59536c421660c392d256bc8f21cb8763cd4444b02201408a12b443b77c8f7aaf39badbe560fd08e60c3784b5cb13248eff5ec4cd67e' ),
);

SKIP: {
    if (!Crypt::Perl::X509::SCT::_can_64_bit()) {
        skip 'This test requires a 64-bit perl.', 1;
    }

    my $out = Crypt::Perl::X509::SCT::encode(@ins);

    is(
        sprintf('%v.02x', $out),
        sprintf('%v.02x', pack('H*', '00ee4bbdb775ce60bae142691fabe19e66a30f7e5fb072d88300c47b897aa8fdcb000001633496cf2c0000040300473045022100ce5d57c1fa9326efccec455bb59536c421660c392d256bc8f21cb8763cd4444b02201408a12b443b77c8f7aaf39badbe560fd08e60c3784b5cb13248eff5ec4cd67e')),
        'expected encode',
    );
}

done_testing();
