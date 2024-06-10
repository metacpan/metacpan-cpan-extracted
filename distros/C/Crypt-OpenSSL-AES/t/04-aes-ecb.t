use strict;
use warnings;
use Test::More tests => 24;
use MIME::Base64 qw/encode_base64 decode_base64/;
use Crypt::OpenSSL::Guess qw(openssl_version);

my ($major, $minor, $patch) = openssl_version();

BEGIN { use_ok('Crypt::OpenSSL::AES') };

my $key = pack("C*",0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33,0x30,0x31,0x32,0x33);

my $plaintext = pack("C*",0x41,0x42,0x43,0x44,0x41,0x42,0x43,0x44,0x41,0x42,0x43,0x44,0x41,0x42,0x43,0x44);

my $expected_enc = pack("C*", 0x9b, 0xc3, 0x7f, 0x1b, 0x92, 0x93, 0xcc, 0xf9, 0x6b, 0x64, 0x00, 0xae, 0xa3, 0xc8, 0x85, 0xbb);

my $c = Crypt::OpenSSL::AES->new($key,
                                    {
                                    cipher  => 'AES-256-ECB',
                                    });

my $encrypted = $c->encrypt($plaintext);

ok($encrypted eq $expected_enc, "Encrypted Successfully AES-256-ECB");

ok($c->decrypt($encrypted) eq $plaintext, "Decrypted Successfully using AES-256-ECB");

# key = substr(sha512_256_hex(rand(1000)), 0, ($ks/4));
my %key = (
          '128' => '8d32b59de8e79ed343858d067f446a89',
          '192' => 'a402478c218652c27003de54d91eeedcfcd1891c263e3530',
          '256' => '1797465b474b7a1891710e98e02d0b5327cb5f42cd724d0f56a00f5dda221838'
        );

# Following data was encrypted with Crypt::Mode::EBC
my %encrypted = (
        "128" => [
                    'yGcevNJm3KI6M34mMwhloQ==', # no padding
                    'yGcevNJm3KI6M34mMwhlofoy2k32Knkw13jQMDU9Y9k=',
                    ],
        "192" => [
                     'mEhEAPCmUkZUkz+OObkttw==', # no padding
                     'mEhEAPCmUkZUkz+OObkttxzCBxH23DsQd5vvXt2wopw=',
                    ],
        "256" => [
                    'dJYwi1VENBvFC8Bjx6kqiw==', #no padding
                    'dJYwi1VENBvFC8Bjx6kqi0/YSB9m6lOpUCPZL8IcKoo=',
                    ],
                );

my @keysize = ("128", "192", "256");

foreach my $ks (@keysize) {
    foreach my $padding (0..1) {
SKIP: {
        skip "Padding unsupported - OpenSSL $major$minor", 2 if $padding == 1 && $major le '0.9' && $minor le '7';
        my $msg = $padding ? "Padding" : "No Padding";

            my $coa = Crypt::OpenSSL::AES->new(pack("H*", $key{$ks}),
                                        {
                                        cipher  => "AES-$ks-ECB",
                                        padding => $padding,
                                        });

            my $ciphertext = $coa->encrypt("Hello World. 123");
            ok($ciphertext eq decode_base64($encrypted{$ks}[$padding]), "Crypt::OpenSSL::AES ($ks $msg) - Created expected ciphertext");

            $plaintext = $coa->decrypt(decode_base64($encrypted{$ks}[$padding]));
            ok($plaintext eq "Hello World. 123", "Crypt::Mode::ECB ($ks $msg) - Decrypted with Crypt::OpenSSL::AES");
    }
    }
}
foreach my $ks (@keysize) {
    my $padding = 1;
    my $msg = $padding ? "Padding" : "No Padding";
    foreach my $iks (@keysize) {
        next if ($ks eq $iks);
SKIP: {
        skip "Padding unsupported - OpenSSL $major$minor", 1 if $major le '0.9' && $minor le '7';
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
    }
    foreach my $iks (@keysize) {
        next if ($ks ne $iks);
SKIP: {
        skip "Padding unsupported - OpenSSL $major$minor", 1 if $major le '0.9' && $minor le '7';
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
