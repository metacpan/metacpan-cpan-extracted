use strict;
use warnings;
use Test::More tests => 22;
use MIME::Base64 qw/encode_base64 decode_base64/;

BEGIN { use_ok('Crypt::OpenSSL::AES') };

# key = substr(sha512_256_hex(rand(1000)), 0, ($ks/4));
my %key = (
        "128" => "d6fcdc0c8cd66ff82facaa084859e23f",
        "192" => "8b3335b0fca17501af9ac76624d7dc23cc687069107a31dc",
        "256" => "39f6cdc3fb383fdfe4705d36943334dad6bb5c60df7c34db34089d023e77677e",
        );

# iv  = substr(sha512_256_hex(rand(1000)), 0, 32);
my %iv = (
        #"128" => "9fbb0ee6245939e50aaa3b4659634a9c02800ed9a11d70a194655be6be3e0e43",
        "128" => "9fbb0ee6245939e50aaa3b4659634a9c",
        #"192" => "e8a980144f35e292888282401fa7353ab6806d6d385a9d90830b10be4bd52ffb",
        "192" => "e8a980144f35e292888282401fa7353a",
        #"256" => "be77fd70d0a2cf929389171bb75be1ee4637e67a5c77fda07c1a7892c8755f84",
        "256" => "be77fd70d0a2cf929389171bb75be1ee",
        );

# Following data was encrypted with Crypt::Mode::CBC
my %encrypted = (
        "128" => [
                    "R3Oa7KLd/fxaNehfRGCX5Q==", # no padding
                    "R3Oa7KLd/fxaNehfRGCX5QMgX9Gzs7JyGIo62NsXeJk=",
                    ],
        "192" => [
                    "49Q1xtaySiebjZz3zAQ+3A==", # no padding
                    "49Q1xtaySiebjZz3zAQ+3CnbIdZpCpCJscAvsHiWwI4=",
                    ],
        "256" => [
                    "03LaWrnpgKYXvxbgp8YoBg==", #no padding
                    "03LaWrnpgKYXvxbgp8YoBjSidwJGLMaV1uKc7X8uy7c=",
                    ],
                );

my @keysize = ("128", "192", "256");
foreach my $ks (@keysize) {
    foreach my $padding (0..1) {
        {
            my $msg = $padding ? "Padding" : "No Padding";
            my $coa = Crypt::OpenSSL::AES->new(pack("H*", $key{$ks}),
                                        {
                                        cipher  => "AES-$ks-CBC",
                                        padding => $padding,
                                        iv      => pack("H*", $iv{$ks}),
                                        });

            my $ciphertext = $coa->encrypt("Hello World. 123");
            ok($ciphertext eq decode_base64($encrypted{$ks}[$padding]), "Crypt::OpenSSL::AES ($ks $msg) - Created expected ciphertext");

            my $plaintext = $coa->decrypt(decode_base64($encrypted{$ks}[$padding]));
            ok($plaintext eq "Hello World. 123", "Crypt::Mode::CBC ($ks $msg) - Decrypted with Crypt::OpenSSL::AES");
        }
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
done_testing;
