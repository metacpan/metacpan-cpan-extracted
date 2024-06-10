use strict;
use warnings;
use Test::More tests => 16;
use MIME::Base64 qw/encode_base64 decode_base64/;
use Crypt::OpenSSL::Guess qw/openssl_version/;

my ($major, $minor, $patch) = openssl_version();

BEGIN { use_ok('Crypt::OpenSSL::AES') };

SKIP: {
        skip "OFB Cipher unsupported - OpenSSL $major$minor", 15 if $major le '0.9' && $minor le '7';

# key = substr(sha512_256_hex(rand(1000)), 0, ($ks/4));
my %key = (
          '192' => '7914df496a6947287f46ffd199a25201f551d7accf585109',
          '128' => '71e99e2d41197db3589ae32207085cab',
          '256' => 'fb31744d4b4600884d77285eab191a3fd739809a53f89851b6e193bca410be8f'
        );

# iv  = substr(sha512_256_hex(rand(1000)), 0, 32);
my %iv = (
          '192' => 'cc7f457865ceac2be41bd9e71d84ade1',
          '128' => 'dd25fc892e4ee3067d8db17601149d1e',
          '256' => '023883d66e703d4228c0e9b9676c1730'
        );

# Following data was encrypted with Crypt::Mode::OFB
my %encrypted = (
          '128' => 'ia0etNMLZyi3vrB63j78yg==',
          '192' => 'TjxZfG3M4AEW1c/T/6b7cg==',
          '256' => 'n26Aq1D6k+cH255ZFApj/w==',
        );

my @keysize = ("128", "192", "256");
foreach my $ks (@keysize) {
    {
        my $coa = Crypt::OpenSSL::AES->new(pack("H*", $key{$ks}),
                                        {
                                        cipher  => "AES-$ks-OFB",
                                        iv      => pack("H*", $iv{$ks}),
                                        });

        my $ciphertext = $coa->encrypt("Hello World. 123");
        ok($ciphertext eq decode_base64($encrypted{$ks}), "Crypt::OpenSSL::AES ($ks) - Created expected ciphertext");

        my $plaintext = $coa->decrypt(decode_base64($encrypted{$ks}));

        ok($plaintext eq "Hello World. 123", "Crypt::Mode::OFB ($ks) - Decrypted with Crypt::OpenSSL::AES");
    }
}

foreach my $ks (@keysize) {
    my $padding = 1;
    my $msg = $padding ? "Padding" : "No Padding";
    foreach my $iks (@keysize) {
        next if ($ks eq $iks);
        my $coa;
        eval {
            $coa = Crypt::OpenSSL::AES->new(pack("H*", $key{$ks}),
                                    {
                                        cipher  => "AES-$iks-ECB",
                                        padding => $padding,
                                    });
        };
        like($@, qr/unsupported cipher for this keysize/, "Mismatch of keysize ($ks) and cipher ($iks)");
    }
    foreach my $iks (@keysize) {
        next if ($ks ne $iks);
        my $coa;
        eval {
            $coa = Crypt::OpenSSL::AES->new(pack("H*", $key{$ks}),
                                    {
                                        cipher  => "AES-$iks-ECB",
                                        padding => $padding,
                                    });
        };
        like($@, qr//, "Match of keysize ($ks) and cipher ($iks)");
    }
}
}
done_testing;
