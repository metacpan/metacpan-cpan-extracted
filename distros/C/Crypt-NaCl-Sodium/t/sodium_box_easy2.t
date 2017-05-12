
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(:utils);

my $crypto_box = Crypt::NaCl::Sodium->box();

my ($m, $c, $d);

my ($alicepk, $alicesk) = $crypto_box->keypair();
my ($bobpk, $bobsk) = $crypto_box->keypair();

my $nonce = $crypto_box->nonce();
my $msg = random_bytes( random_number( 10_000 ) );

$c = $crypto_box->encrypt( $msg, $nonce, $bobpk, $alicesk );
ok($c, "encrypted using keys");
is( length($c), length($msg) + $crypto_box->MACBYTES, "ciphertext is of correct length: ". length($c));

$d = $crypto_box->decrypt( $c, $nonce, $alicepk, $bobsk );
ok($d, "got decrypted message");
is($d, $msg, "... and was correctly decrypted");

my $alice_precal_key = $crypto_box->beforenm( $bobpk, $alicesk );
my $bob_precal_key = $crypto_box->beforenm( $alicepk, $bobsk );

ok($alice_precal_key, "precalculated key for alice");
ok($bob_precal_key, "precalculated key for bob");

$c = $crypto_box->encrypt_afternm( $msg, $nonce, $alice_precal_key );
ok($c, "encrypted using precalculated key");
is( length($c), length($msg) + $crypto_box->MACBYTES, "ciphertext is of correct length: ". length($c));

$d = $crypto_box->decrypt_afternm( $c, $nonce, $bob_precal_key );
ok($d, "got decrypted message");
is($d, $msg, "... and was correctly decrypted");

($m, $c) = $crypto_box->encrypt( $msg, $nonce, $alicepk, $bobsk );
ok($m, "got mac in detached mode");
is( length($m), $crypto_box->MACBYTES, "...of correct length: ". length($m));
ok($c, "got ciphertext in detached mode");
is( length($c), length($msg), "...of correct length: ". length($msg));

$d = $crypto_box->decrypt( $m . $c, $nonce, $bobpk, $alicesk );
ok($d, "got decrypted message");
is($d, $msg, "... and was correctly decrypted");

($m, $c) = $crypto_box->encrypt_afternm( $msg, $nonce, $bob_precal_key );
ok($m, "got mac in detached mode with precalculated key");
is( length($m), $crypto_box->MACBYTES, "...of correct length: ". length($m));
ok($c, "got ciphertext in detached mode with precalculated key");
is( length($c), length($msg), "...of correct length: ". length($msg));

$d = $crypto_box->decrypt_afternm( $m . $c, $nonce, $alice_precal_key );
ok($d, "got decrypted message with precalculated key");
is($d, $msg, "... and was correctly decrypted with precalculated key");

done_testing();

