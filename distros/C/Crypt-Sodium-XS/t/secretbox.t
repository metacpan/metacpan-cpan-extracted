use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::OO::secretbox;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my $msg = "How do you do?";

for my $alg (Crypt::Sodium::XS::OO::secretbox->primitives) {
  my $m = Crypt::Sodium::XS::OO::secretbox->new(primitive => $alg);

  ok($m->KEYBYTES > 0, "KEYBYTES > 0 ($alg)");
  ok($m->NONCEBYTES > 0, "NONCEBYTES > 0 ($alg)");
  ok($m->MACBYTES > 0, "MACBYTES > 0 ($alg)");
  for (1 .. 2) {
    my $nonce = $m->nonce;
    ok($nonce, "nonce generated ($alg)");

    my $key = $m->keygen;
    ok($key, "key generated ($alg)");
    my $wrongkey = $m->keygen;

    my $encrypted = $m->encrypt($msg, $nonce, $key);
    ok($encrypted, "message encrypted ($alg)");
    my $encrypted2 = $m->encrypt($msg, $nonce, $wrongkey);

    my $decrypted = $m->decrypt($encrypted, $nonce, $key);
    ok($decrypted, "message decrypted ($alg)");
    $decrypted->unlock;
    is($decrypted, $msg, "decrypted correctly ($alg)");
    eval { my $junk = $m->decrypt($encrypted, $nonce, $wrongkey); };
    like($@, qr/Message forged/, "wrong decryption key fails to decrypt");
    eval { my $junk = $m->decrypt($encrypted2, $nonce, $key); };
    like($@, qr/Message forged/, "wrong encryption key fails to decrypt");

    # detached mode
    ($encrypted, my $mac) = $m->encrypt_detached($msg, $nonce, $key);
    ok($mac, "mac generated ($alg)");
    ok($encrypted, "message encrypted ($alg)");

    $decrypted = $m->decrypt_detached($encrypted, $mac, $nonce, $key);
    ok($decrypted, "message decrypted ($alg)");
    $decrypted->unlock;
    is($decrypted, $msg, "decrypted (detached) correctly ($alg)");
    my $badmac = 'X' x $m->MACBYTES;
    eval { my $junk = $m->decrypt_detached($encrypted, $badmac, $nonce, $key); };
    like($@, qr/Message forged/, "wrong decryption key fails to decrypt_detached");
    eval { my $junk = $m->decrypt_detached($encrypted, $mac, $nonce, $wrongkey); };
    like($@, qr/Message forged/, "wrong decryption key fails to decrypt_detached");
    eval { my $junk = $m->decrypt_detached($encrypted2, $mac, $nonce, $key); };
    like($@, qr/Message forged/, "wrong encryption key fails to decrypt_detached");
  }
}

done_testing();

