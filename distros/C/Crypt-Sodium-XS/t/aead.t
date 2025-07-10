use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::Util "sodium_increment";
use Crypt::Sodium::XS::OO::aead;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my $msg = "Delivered by Mr. Postman";
my @adatas = (
    "Parcel was dispatched",
    "",
);

for my $alg (Crypt::Sodium::XS::OO::aead->primitives) {
  my $m = Crypt::Sodium::XS::OO::aead->new(primitive => $alg);

  ok($m->$_ > 0, "$_ > 0 ($alg)") for qw(ABYTES KEYBYTES MESSAGEBYTES_MAX NPUBBYTES);

  for my $extra (@adatas) {
    my $nonce;
    $nonce = $m->nonce;
    ok($nonce, "nonce generated ($alg)");
    ok(length($nonce) == $m->NPUBBYTES, "correct nonce length ($alg)");

    my $key = $m->keygen;
    ok($key, "key generated ($alg)");

    my $ct = $m->encrypt($msg, $nonce, $key, $extra);
    ok($ct, "encrypted ($alg)");

    my $pt = $m->decrypt($ct, $nonce, $key, $extra);
    ok($pt, "decrypted ($alg)");
    $pt->unlock;
    is($pt, $msg, "decrypted correctly ($alg)");

    $nonce = sodium_increment($nonce);
    $ct = $m->encrypt($msg, $nonce, $key, $extra);
    ok($ct, "data encrypted next nonce ($alg)");

    $pt = $m->decrypt($ct, $nonce, $key, $extra);
    ok($pt, "data decrypted next nonce ($alg)");
    $pt->unlock;
    is($pt, $msg, "decrypted with next nonce correctly ($alg)");

    eval { my $x = $m->decrypt(scalar "X" x $m->ABYTES, $nonce, $key, $extra) };
    like($@, qr/^aead_decrypt: Message forged/, "decrypt with bad ciphertext fails ($alg)");
    eval { my $x = $m->decrypt($ct, $nonce, $key, "foobar") };
    like($@, qr/^aead_decrypt: Message forged/, "decrypt with bad extra data fails ($alg)");
    my $bad_nonce = scalar reverse $nonce;
    eval { my $x = $m->decrypt($ct, $bad_nonce, $key, $extra) };
    like($@, qr/^aead_decrypt: Message forged/, "decrypt with bad nonce fails ($alg)");
    eval { my $x = $m->decrypt($ct, $nonce, scalar "\1" x $m->KEYBYTES, $extra) };
    like($@, qr/^aead_decrypt: Message forged/, "decrypt with bad key fails ($alg)");

    $nonce = sodium_increment($nonce);
    ($ct, my $mac) = $m->encrypt_detached($msg, $nonce, $key, $extra);
    ok($ct, "data encrypted detached ($alg)");
    ok($mac, "mac generated ($alg)");

    $pt = $m->decrypt_detached($ct, $mac, $nonce, $key, $extra);
    ok($pt, "data decrypted detached ($alg)");
    $pt->unlock;
    is($pt, $msg, "decrypted detached correctly ($alg)");

    if ($alg eq 'aes256gcm') {
      # precalculated
      my $mp = $m->beforenm($key);
      ok($mp, "multipart msg initialized ($alg)");
      $nonce = sodium_increment($nonce);
      $ct = $mp->encrypt($msg, $nonce, $extra);
      ok($ct, "multipart msg encrypted ($alg)");
      $pt = $mp->decrypt($ct, $nonce, $extra);
      ok($pt, "multipart msg decrypted ($alg)");
      $pt->unlock;
      is($pt, $msg, "multipart msg decrypted correctly ($alg)");

      eval { my $x = $mp->decrypt(scalar "X" x $m->ABYTES, $nonce, $extra) };
      like($@, qr/^decrypt: Message forged/, "multipart decrypt with bad ciphertext fails ($alg)");
      eval { my $x = $mp->decrypt($ct, $nonce, "foobar") };
      like($@, qr/^decrypt: Message forged/, "multipart decrypt with bad extra data fails ($alg)");
      eval { my $x = $mp->decrypt($ct, $bad_nonce, $extra) };
      like($@, qr/^decrypt: Message forged/, "multipart decrypt with bad nonce fails ($alg)");

      $nonce = sodium_increment($nonce);
      my $ct2 = $mp->encrypt($msg, $nonce, $extra);
      ok($ct2, "multipart same msg encrypted ($alg)");
      isnt(unpack("H*", $ct), unpack("H*", $ct2),
           "multipart same msg different ciphertext");
      my $pt2 = $mp->decrypt($ct2, $nonce, $extra);
      ok($pt2, "multipart same msg decrypted ($alg)");
      $pt2->unlock;
      is($pt2, $msg, "multipart same msg decrypted correctly ($alg)");

      $nonce = sodium_increment($nonce);
      my $ct3 = $mp->encrypt("$msg with other stuff", $nonce, $extra);
      ok($ct3, "multipart new msg encrypted ($alg)");
      my $pt3 = $mp->decrypt($ct3, $nonce, $extra);
      ok($pt3, "multipart new msg decrypted ($alg)");
      $pt3->unlock;
      is($pt3, "$msg with other stuff", "multipart new msg decrypted correctly ($alg)");

      $nonce = sodium_increment($nonce);
      ($ct, $mac) = $mp->encrypt_detached($msg, $nonce, $extra);
      ok($ct, "multipart detached msg encrypted ($alg)");
      ok($mac, "multipart detached msg mac ($alg)");
      $pt = $mp->decrypt_detached($ct, $mac, $nonce, $extra);
      ok($pt, "multipart detached msg decrypted ($alg)");
      $pt->unlock;
      is($pt, $msg, "multipart detached msg decrypted correctly ($alg)");

      $nonce = sodium_increment($nonce);
      ($ct2, my $mac2) = $mp->encrypt_detached($msg, $nonce, $extra);
      ok($ct2, "multipart detached same msg encrypted ($alg)");
      ok($mac2, "multipart detached same msg mac ($alg) ($alg)");
      isnt(unpack("H*", $ct2), unpack("H*", $ct),
           "multipart detached same msg different ciphertext ($alg)");
      isnt(unpack("H*", $mac2), unpack("H*", $mac),
           "multipart detached same msg different mac ($alg)");
      $pt2 = $mp->decrypt_detached($ct2, $mac2, $nonce, $extra);
      ok($pt2, "multipart detached msg decrypted ($alg)");
      $pt2->unlock;
      is($pt2, $msg, "multipart detached same msg decrypted correctly ($alg)");

      $nonce = sodium_increment($nonce);
      ($ct3, my $mac3) = $mp->encrypt_detached($msg, $nonce, $extra);
      ok($ct3, "multipart detached same msg encrypted ($alg)");
      ok($mac3, "multipart detached same msg mac ($alg)");
      $pt3 = $mp->decrypt_detached($ct3, $mac3, $nonce, $extra);
      ok($pt3, "multipart detached msg decrypted ($alg)");
      $pt3->unlock;
      is($pt3, $msg, "multipart detached same msg decrypted correctly ($alg)");
    }
  }
}

done_testing();

