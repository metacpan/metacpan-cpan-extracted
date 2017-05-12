
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(bin2hex);


my $crypto_sign = Crypt::NaCl::Sodium->sign();
my $msg = "How do you do?";

for ( 1 .. 2 ) {
    my ($pkey, $skey, $pkey_hex, $skey_hex, $sealed, $opened, $mac,
        $mac_hex);

    my $seed = $crypto_sign->seed();
    ok($seed, "seed generated");

    for ( 1 .. 2 ) {
        my ($pkey, $skey) = $crypto_sign->keypair($seed);
        ok($pkey, "pkey generated from seed");
        ok($skey, "skey generated from seed");
        my $pkey2 = $crypto_sign->public_key($skey);
        ok($pkey2, "pkey generated from skey");
        is(bin2hex($pkey), bin2hex($pkey2), "...and matched the generated one");
        my $seed2 = $crypto_sign->extract_seed($skey);
        ok($seed2, "seed extracted from skey");
        is(bin2hex($seed2), bin2hex($seed), "...and matched the generated one");
    }

    ($pkey, $skey) = $crypto_sign->keypair();
    ok($pkey, "pkey generated with random seed");
    ok($skey, "skey generated with random seed");

    $sealed = $crypto_sign->seal( $msg, $skey );
    ok($sealed, "sealed msg with skey");

    $opened = $crypto_sign->open( $sealed, $pkey );
    ok($opened, "opened msg with pkey");
    is($opened, $msg, "...and matches msg");

    # detached mode
    $mac = $crypto_sign->mac( $msg, $skey );
    ok($mac, "mac calculated for msg using skey");

    ok( $crypto_sign->verify( $mac , $msg, $pkey ),
        "sealed message verified using mac");
}

# convert
my $seed = join('', map { chr($_) }
    0x42, 0x11, 0x51, 0xa4, 0x59, 0xfa, 0xea, 0xde, 0x3d, 0x24, 0x71,
    0x15, 0xf9, 0x4a, 0xed, 0xae, 0x42, 0x31, 0x81, 0x24, 0x09, 0x5a,
    0xfa, 0xbe, 0x4d, 0x14, 0x51, 0xa5, 0x59, 0xfa, 0xed, 0xee
);
my ($pkey, $skey) = $crypto_sign->keypair($seed);
my ($pkey_curve25519, $skey_curve25519) = $crypto_sign->to_curve25519_keypair($pkey, $skey);
my ($pkey_curve25519_hex, $skey_curve25519_hex) = map { bin2hex($_) } $pkey_curve25519, $skey_curve25519;

is($pkey_curve25519_hex,
    "f1814f0e8ff1043d8a44d25babff3cedcae6c22c3edaa48f857ae70de2baae50",
    "ed25519 private key converted correctly to Curve25519 key: $pkey_curve25519_hex");
is($skey_curve25519_hex,
    "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de166",
    "ed25519 secret key converted correctly to Curve25519 key: $skey_curve25519_hex");

my $crypto_scalarmult = Crypt::NaCl::Sodium->scalarmult();
for ( 1 .. 500 ) {
    my ($pkey, $skey) = $crypto_sign->keypair();
    my ($pkey_curve25519, $skey_curve25519) = $crypto_sign->to_curve25519_keypair($pkey, $skey);
    my $curve25519_pkey = $crypto_scalarmult->base($skey_curve25519);
    is( $curve25519_pkey, $pkey_curve25519,
        "ed25519 to curve25519 conversion correct: ". bin2hex($curve25519_pkey));
}

done_testing();

