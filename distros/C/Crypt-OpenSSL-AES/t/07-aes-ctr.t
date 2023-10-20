use strict;
use warnings;
use Test::More tests => 7;
use MIME::Base64 qw/encode_base64 decode_base64/;

use Crypt::OpenSSL::Guess qw/openssl_version/;

my ($major, $minor, $patch) = openssl_version();

BEGIN { use_ok('Crypt::OpenSSL::AES') };

SKIP: {
    skip "AES CTR is not supported before OpenSSL 1.0.1", 6 if($major lt "1.0");
    skip "AES CTR is not supported before OpenSSL 1.0.1", 6 if($major le "1.0" && $minor lt "1");

    # key = substr(sha512_256_hex(rand(1000)), 0, ($ks/4));
    my %key = (
          '192' => 'fa46de67ab6f1bb5a9af97452babdb294e49457171e3903e',
          '256' => 'd4b0bc6a9b2d4fa30565e5b16795d278e4b7111c45f6932e98cd5f69cf6bc636',
          '128' => '77c36b08f4d9093d0fe7c4c1c757b1d3',
        );

    # iv  = substr(sha512_256_hex(rand(1000)), 0, 32);
    my %iv = (
          '128' => '409c5c7c71c14bb5e29f175ec37749af',
          '256' => 'a25195197720b34630258d6de83f2a56',
          '192' => 'bd0e782c29a791720ac1bcca2f346f1c',
        );

    # Following data was encrypted with Crypt::Mode::CTR
    my %encrypted = (
          '256' => 'YoZDbH4wa1GphVpYKu6VfA==',
          '192' => '2BVvGDc3WBKbemaf7ftDvQ==',
          '128' => 'ezLSxC6bIjjFZNR4wRoEpg==',
        );

    my @keysize = ("128", "192", "256");
    foreach my $ks (@keysize)
    {
        my $coa = Crypt::OpenSSL::AES->new(pack("H*", $key{$ks}),
                                        {
                                        cipher  => "AES-$ks-CTR",
                                        iv      => pack("H*", $iv{$ks}),
                                        });

        my $ciphertext = $coa->encrypt("Hello World. 123");
        ok($ciphertext eq decode_base64($encrypted{$ks}), "Crypt::OpenSSL::AES ($ks) - Created expected ciphertext");

        my $plaintext = $coa->decrypt(decode_base64($encrypted{$ks}));
        ok($plaintext eq "Hello World. 123", "Crypt::Mode::CTR ($ks) - Decrypted with Crypt::OpenSSL::AES");
    }
}
done_testing;
