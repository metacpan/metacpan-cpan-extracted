
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_secretbox = Crypt::NaCl::Sodium->secretbox();
my $msg = "How do you do?";

ok($crypto_secretbox->$_ > 0, "$_ > 0")
    for qw( NONCEBYTES MACBYTES KEYBYTES  );

for ( 1 .. 2 ) {
    my ($nonce, $key, $secret, $decrypted, $mac);

    $nonce = $crypto_secretbox->nonce();
    ok($nonce, "nonce generated");

    $key = $crypto_secretbox->keygen();
    ok($key, "key generated");

    $secret = $crypto_secretbox->encrypt( $msg, $nonce, $key );
    ok($secret, "secret generated");

    $decrypted = $crypto_secretbox->decrypt( $secret, $nonce, $key );
    ok($decrypted, "message decrypted");
    is($decrypted, $msg, "...and decrypted correctly");

    # detached mode
    ($mac, $secret) = $crypto_secretbox->encrypt( $msg, $nonce, $key );
    ok($mac, "mac generated");
    ok($secret, "secret generated");

    $decrypted = $crypto_secretbox->decrypt_detached( $mac, $secret, $nonce, $key );
    ok($decrypted, "message decrypted");
    is($decrypted, $msg, "...and decrypted correctly");
}

done_testing();

