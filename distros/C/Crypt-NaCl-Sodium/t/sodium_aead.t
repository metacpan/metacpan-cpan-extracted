
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(:utils);


my $key = join('', map { chr($_) }
    0x42, 0x90, 0xbc, 0xb1, 0x54, 0x17, 0x35, 0x31, 0xf3, 0x14, 0xaf,
    0x57, 0xf3, 0xbe, 0x3b, 0x50, 0x06, 0xda, 0x37, 0x1e, 0xce, 0x27,
    0x2a, 0xfa, 0x1b, 0x5d, 0xbd, 0xd1, 0x10, 0x0a, 0x10, 0x07
);

my $nonce = join('', map { chr($_) }
    0xcd, 0x7c, 0xf6, 0x7b, 0xe3, 0x9c, 0x79, 0x4a
);

my $ad = join('', map { chr($_) }
    0x87, 0xe2, 0x29, 0xd4, 0x50, 0x08, 0x45, 0xa0, 0x79, 0xc0
);


my $msg = join('', map { chr($_) }
    0x86, 0xd0, 0x99, 0x74, 0x84, 0x0b, 0xde, 0xd2, 0xa5, 0xca
);

my $expected_hex = join('', map { sprintf("%02x", $_) }
     0xe3,0xe4,0x46,0xf7,0xed,0xe9,0xa1,0x9b
    ,0x62,0xa4,0x67,0x7d,0xab,0xf4,0xe3,0xd2
    ,0x4b,0x87,0x6b,0xb2,0x84,0x75,0x38,0x96
    ,0xe1,0xd6
);

my $expected_no_ad_hex = join('', map { sprintf("%02x", $_) }
     0xe3,0xe4,0x46,0xf7,0xed,0xe9,0xa1,0x9b
    ,0x62,0xa4,0x69,0xe7,0x78,0x9b,0xcd,0x95
    ,0x4e,0x65,0x8e,0xd3,0x84,0x23,0xe2,0x31
    ,0x61,0xdc
);

my $crypto_aead = Crypt::NaCl::Sodium->aead();

my $secret = $crypto_aead->encrypt( $msg, $ad, $nonce, $key );
my $secret_hex = bin2hex($secret);
my $s_secret = "$secret"; # from byteslocker

is( length($secret), length($msg) + $crypto_aead->ABYTES(),
    "Encrypted message is of correct length");
is($secret_hex, $expected_hex, "...and correctly encrypted: $secret_hex");

my $decrypted = $crypto_aead->decrypt( $secret, $ad, $nonce, $key );

is( length($decrypted), length($msg),
    "Decrypted message is of correct length");
is($decrypted, $msg, "... and was correctly decrypted");

for my $i ( 0 .. length($secret) - 1 ) {
    my $c = ord(substr($s_secret, $i, 1));
    $c ^= ( $i + 1 );
    substr($s_secret, $i, 1, chr($c));

    eval {
        my $decrypted = $crypto_aead->decrypt( $s_secret, $ad, $nonce, $key );
    };

    like($@, qr/Message forged/, "Message cannot be forged (change at position: $i)");

    $c ^= ( $i + 1 );
    substr($s_secret, $i, 1, chr($c));
}

my $secret_no_ad = $crypto_aead->encrypt( $msg, '', $nonce, $key );
my $secret_no_ad_hex = bin2hex($secret_no_ad);

is( length($secret_no_ad), length($msg) + $crypto_aead->ABYTES(),
    "Encrypted message without additional data is of correct length");
is($secret_no_ad_hex, $expected_no_ad_hex, "...and correctly encrypted: $secret_no_ad_hex");

my $decrypted_no_ad = $crypto_aead->decrypt( $secret_no_ad, '', $nonce, $key );

is( length($decrypted_no_ad), length($msg),
    "Decrypted message without additional data is of correct length");
is($decrypted_no_ad, $msg, "... and was correctly decrypted");

ok($crypto_aead->KEYBYTES() > 0, "KEYBYTES > 0");
ok($crypto_aead->NPUBBYTES() > 0, "NPUBBYTES > 0");
ok($crypto_aead->ABYTES() > 0, "ABYTES > 0");


done_testing();

__END__
