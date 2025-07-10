use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::Util "sodium_random_bytes";
use Crypt::Sodium::XS::OO::box;
use Crypt::Sodium::XS::scalarmult "scalarmult_base";
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my $msg = "How do you do?";

my $m = Crypt::Sodium::XS::OO::box->new;

for my $alg (Crypt::Sodium::XS::OO::box->primitives) {
  $m->primitive($alg);

  ok($m->$_ > 0, "$_ > 0 ($alg)")
    for qw(BEFORENMBYTES MACBYTES MESSAGEBYTES_MAX NONCEBYTES
           PUBLICKEYBYTES SEALBYTES SECRETKEYBYTES SEEDBYTES);

  for (1 .. 2) {
    my $nonce = $m->nonce;
    ok($nonce, "nonce generated ($alg)");

    my ($pkey, $skey) = $m->keypair;
    ok($pkey, "pkey generated ($alg)");
    ok($skey, "skey generated ($alg)");
    my $pkey_test = scalarmult_base($skey);
    is(unpack("H*", $pkey_test), unpack("H*", $pkey), "pkey extracted from skey ($alg)");

    my $seed = sodium_random_bytes($m->SEEDBYTES);
    ok($seed, "seed generated ($alg)");
    for (1 .. 2) {
      ($pkey, $skey) = $m->keypair($seed);
      ok($pkey, "pkey generated with seed ($alg)");
      ok($skey, "skey generated with seed ($alg)");
      $pkey_test = scalarmult_base($skey);
      is(unpack("H*", $pkey_test), unpack("H*", $pkey), "pkey extracted from seeded skey ($alg)");
    }

    my ($pkey2, $skey2) = $m->keypair;

    my $ct = $m->encrypt($msg, $nonce, $pkey2, $skey);
    ok($ct, "ciphertext generated ($alg)");

    my $pt = $m->decrypt($ct, $nonce, $pkey, $skey2);
    ok($pt, "message decrypted ($alg)");
    is($pt->unlock, $msg, "decrypted correctly ($alg)");

    # detached mode
    ($ct, my $mac) = $m->encrypt_detached($msg, $nonce, $pkey2, $skey);
    ok($mac, "mac generated ($alg)");
    ok($ct, "ciphertext generated ($alg)");

    $pt = $m->decrypt_detached($ct, $mac, $nonce, $pkey, $skey2);
    ok($pt, "message decrypted ($alg)");
    is($pt->unlock, $msg, "decrypted correctly ($alg)");

    # precalculated
    my $precalc = $m->beforenm($pkey2, $skey);
    my $precalc2 = $m->beforenm($pkey, $skey2);
    ok($precalc, "precalc generated ($alg)");
    ok($precalc2, "precalc2 generated ($alg)");

    $ct = $precalc->encrypt($msg, $nonce);
    ok($ct, "ciphertext generated with precalc object ($alg)");

    $pt = $precalc->decrypt($ct, $nonce);
    ok($pt, "message decrypted with precalc object ($alg)");
    is($pt->unlock, $msg, "decrypted correctly with precalc object ($alg)");
    $pt = $precalc2->decrypt($ct, $nonce);
    ok($pt, "message decrypted with other side's precalc object ($alg)");
    is($pt->unlock, $msg, "decrypted correctly with other side's precalc object ($alg)");

    # detached mode
    ($ct, $mac) = $precalc->encrypt_detached($msg, $nonce);
    ok($mac, "mac generated with precalc object ($alg)");
    ok($ct, "ciphertext generated with precalc object ($alg)");

    $pt = $precalc->decrypt_detached($ct, $mac, $nonce);
    ok($pt, "message decrypted with precalc object ($alg)");
    is($pt->unlock, $msg, "decrypted correctly with precalc object ($alg)");
    $pt = $precalc2->decrypt_detached($ct, $mac, $nonce);
    ok($pt, "message decrypted with other side's precalc object ($alg)");
    is($pt->unlock, $msg, "decrypted correctly with other side's precalc object ($alg)");

    # sealed box
    $ct = $m->seal_encrypt($msg, $pkey);
    ok($ct, "seal ciphertext generated ($alg)");

    $pt = $m->seal_decrypt($ct, $pkey, $skey);
    ok($pt, "seal message decrypted ($alg)");
    is($pt->unlock, $msg, "seal decrypted correctly ($alg)");
  }

}

done_testing();
