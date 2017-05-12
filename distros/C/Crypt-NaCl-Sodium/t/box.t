
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(bin2hex);

my $crypto_box = Crypt::NaCl::Sodium->box();
my $msg = "How do you do?";

ok($crypto_box->$_ > 0, "$_ > 0")
    for qw( PUBLICKEYBYTES SECRETKEYBYTES NONCEBYTES MACBYTES SEEDBYTES
    BEFORENMBYTES  );

for ( 1 .. 2 ) {
    my ($nonce, $nonce_hex, $a_pkey, $a_skey, $b_pkey, $b_skey, $a_pkey_hex,
        $a_skey_hex, $b_pkey_hex, $b_skey_hex, $secret, $decrypted, $mac,
        $mac_hex);

    $nonce = $crypto_box->nonce();
    ok($nonce, "nonce generated");
    $nonce_hex = bin2hex($nonce);

    my $seed = $crypto_box->seed();
    ok($seed, "seed generated");
    for ( 1 .. 2 ) {
        my ($pkey, $skey) = $crypto_box->keypair($seed);
        ok($pkey, "pkey generated");
        ok($skey, "skey generated");
        my $pkey2 = $crypto_box->public_key($skey);
        is(bin2hex($pkey2), bin2hex($pkey), "pkey extracted from skey");
    }

    ($a_pkey, $a_skey) = $crypto_box->keypair();
    ok($a_pkey, "a_pkey generated");
    ok($a_skey, "a_skey generated");
    $a_pkey_hex = bin2hex($a_pkey);
    $a_skey_hex = bin2hex($a_skey);

    ($b_pkey, $b_skey) = $crypto_box->keypair();
    ok($b_pkey, "b_pkey generated");
    ok($b_skey, "b_skey generated");
    $b_pkey_hex = bin2hex($b_pkey);
    $b_skey_hex = bin2hex($b_skey);

    $secret = $crypto_box->encrypt( $msg, $nonce, $b_pkey, $a_skey );
    ok($secret, "secret generated");

    $decrypted = $crypto_box->decrypt( $secret, $nonce, $a_pkey, $b_skey );
    ok($decrypted, "message decrypted");
    is($decrypted, $msg, "...and decrypted correctly");

    # detached mode
    ($mac, $secret) = $crypto_box->encrypt( $msg, $nonce, $b_pkey, $a_skey );
    ok($mac, "mac generated");
    ok($secret, "secret generated");

    $decrypted = $crypto_box->decrypt_detached( $mac, $secret, $nonce, $a_pkey, $b_skey);
    ok($decrypted, "message decrypted");
    is($decrypted, $msg, "...and decrypted correctly");

    # precalculated
    my $a_precal_key = $crypto_box->beforenm( $b_pkey, $a_skey );
    my $b_precal_key = $crypto_box->beforenm( $a_pkey, $b_skey );
    ok($a_precal_key, "a_precal_key generated");
    ok($b_precal_key, "b_precal_key generated");

    $secret = $crypto_box->encrypt_afternm( $msg, $nonce, $a_precal_key );
    ok($secret, "secret generated");

    $decrypted = $crypto_box->decrypt_afternm( $secret, $nonce, $b_precal_key );
    ok($decrypted, "message decrypted");
    is($decrypted, $msg, "...and decrypted correctly");

    # detached mode
    ($mac, $secret) = $crypto_box->encrypt_afternm( $msg, $nonce, $a_precal_key );
    ok($mac, "mac generated");
    ok($secret, "secret generated");

    $decrypted = $crypto_box->decrypt_detached_afternm( $mac, $secret, $nonce, $b_precal_key );
    ok($decrypted, "message decrypted");
    is($decrypted, $msg, "...and decrypted correctly");
}

done_testing();

