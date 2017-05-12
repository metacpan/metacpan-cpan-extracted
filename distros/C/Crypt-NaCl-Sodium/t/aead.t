
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(bin2hex);

my $crypto_aead = Crypt::NaCl::Sodium->aead;
my $msg = "Delivered by Mr. Postman";
my @adatas = (
    "Parcel was dispatched",
    "",
);

ok($crypto_aead->$_ > 0, "$_ > 0") for qw( KEYBYTES NPUBBYTES ABYTES );

for my $extra ( @adatas ) {
    my ($nonce, $key, $secret, $decrypted, $mac);

    $nonce = $crypto_aead->nonce();
    ok($nonce, "nonce generated");

    $key = $crypto_aead->keygen();
    ok($key, "key generated");

    $secret = $crypto_aead->encrypt( $msg, $extra, $nonce, $key );
    ok($secret, "data encrypted");

    $decrypted = $crypto_aead->decrypt( $secret, $extra, $nonce, $key );
    ok($decrypted, "...and decrypted");
    is($decrypted, $msg, "......correctly");
}

done_testing();

