#!perl

use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64 decode_base64);

use_ok('Crypt::PBE::PBKDF2');

my %pbkdf2_test = (
    'hmac_sha1' => [ 'boi+i61+rp2eEKoGEiQDT+1I0D8=', '6e88be8bad7eae9d9e10aa061224034fed48d03f' ],
    'hmac_sha224' =>
        [ '07zzIP2RiQjq/KpGD69A4gH2UI1Obz2cHAq9MA==', 'd3bcf320fd918908eafcaa460faf40e201f6508d4e6f3d9c1c0abd30' ],
    'hmac_sha256' => [
        'YywoEuRtRgQQK6dhjp1tfS+BKPYma0oDJk0qBGC33LM=',
        '632c2812e46d4604102ba7618e9d6d7d2f8128f6266b4a03264d2a0460b7dcb3'
    ],
    'hmac_sha384' => [
        'O9N+IjaUHUp3sbW3FMb5E/q7awhBptfYZWuZ1hHpAP4G7bk7W4Ce+qlni2Nc5RPg',
        '3bd37e2236941d4a77b1b5b714c6f913fabb6b0841a6d7d8656b99d611e900fe06edb93b5b809efaa9678b635ce513e0'
    ],
    'hmac_sha512' => [
        'r+bFUweFtsxrHGRTOEcxvV7kMu5Un9QvtmlXea2KHFv1neacSPd078QAfVKY+QM8AkHVq2kwXntk7O642DTP7A==',
        'afe6c5530785b6cc6b1c6453384731bd5ee432ee549fd42fb6695779ad8a1c5bf59de69c48f774efc4007d5298f9033c0241d5ab69305e7b64eceeb8d834cfec'
    ],
);

for my $hmac ( keys %pbkdf2_test ) {

    cmp_ok(
        pbkdf2( prf => $hmac, password => 'password', salt => 'salt', count => 1_000 ),
        'eq',
        decode_base64 $pbkdf2_test{$hmac}[0],
        "PBKDF2 with $hmac"
    );

    cmp_ok(
        pbkdf2_base64( prf => $hmac, password => 'password', salt => 'salt', count => 1_000 ),
        'eq',
        $pbkdf2_test{$hmac}[0],
        "PBKDF2 with $hmac-hmac in Base64"
    );

    cmp_ok(
        pbkdf2_hex( prf => $hmac, password => 'password', salt => 'salt', count => 1_000 ),
        'eq',
        $pbkdf2_test{$hmac}[1],
        "PBKDF2 with $hmac-hmac in HEX"
    );

}

done_testing();
