use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::OO::secretstream;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my $msg = "I'm doing just fine. And you?";

for my $alg (Crypt::Sodium::XS::OO::secretstream->primitives) {
  my $m = Crypt::Sodium::XS::OO::secretstream->new(primitive => $alg);

  ok(!!defined($m->TAG_MESSAGE), "TAG_MESSAGE has a value ($alg)");
  ok($m->$_ > 0, "$_ > 0 ($alg)") for qw[ABYTES HEADERBYTES KEYBYTES
                                         MESSAGEBYTES_MAX TAG_PUSH
                                         TAG_REKEY TAG_FINAL];

  for (1 .. 2) {

    my $key = $m->keygen;
    ok($key, "key generated ($alg)");
    my $key2 = $m->keygen;

    my ($header, $encrypter) = $m->init_encrypt($key);
    isa_ok($encrypter, "Crypt::Sodium::XS::secretstream::xchacha20poly1305_encrypt");
    ok($header, "generated header ($alg)");
    ok(length($header) == $m->HEADERBYTES, "header is correct length ($alg)");

    my ($header2, $encrypter2) = $m->init_encrypt($key2);
    my $badheader = "X" x $m->HEADERBYTES;

    my $encrypted = $encrypter->encrypt($msg);

    my $decrypter = $m->init_decrypt($header, $key);
    isa_ok($decrypter, "Crypt::Sodium::XS::secretstream::xchacha20poly1305_decrypt");
    my $decrypter2 = $m->init_decrypt($header2, $key2);
    my $baddecrypter = $m->init_decrypt($header, $key2);
    my $baddecrypter2 = $m->init_decrypt($badheader, $key2);

    my $decrypted = $decrypter->decrypt($encrypted);
    is($decrypted->unlock, $msg, "decrypted ok ($alg)");
    eval { $decrypted = $decrypter->decrypt($encrypted); };
    like($@, qr/Message forged/, "decrypt same data fails ($alg)");
    eval { $decrypted = $decrypter->decrypt("a bunch of junk data ($alg)"); };
    like($@, qr/Message forged/, "decrypt bad data fails ($alg)");
    eval { $decrypted = $decrypter2->decrypt($encrypted); };
    like($@, qr/Message forged/, "decrypt with wrong header/key fails ($alg)");
    eval { $decrypted = $decrypter2->decrypt($encrypted); };
    like($@, qr/Message forged/, "decrypt with wrong header fails ($alg)");
    eval { $decrypted = $baddecrypter->decrypt($encrypted); };
    like($@, qr/Message forged/, "decrypt with wrong key fails ($alg)");

    $encrypted = $encrypter->encrypt("$msg 2");
    $decrypted = $decrypter->decrypt($encrypted);
    $decrypted->unlock;
    is($decrypted, "$msg 2", "decrypted msg 2 ok ($alg)");
    $encrypted = $encrypter2->encrypt($msg);
    $decrypted = $decrypter2->decrypt($encrypted);
    $decrypted->unlock;
    is ($decrypted, $msg, "secondary header/key set decrypted ok ($alg)");
    eval { $decrypted = $decrypter2->decrypt($encrypted); };
    like($@, qr/Message forged/, "decrypt with wrong decrypter fails ($alg)");

    $encrypted = $encrypter->encrypt($msg, $m->TAG_PUSH);
    ($decrypted, my $tag) = $decrypter->decrypt($encrypted);
    is($tag, $m->TAG_PUSH, "tag encrypted/decrypted ok ($alg)");

    $encrypted = $encrypter->encrypt($msg, $m->TAG_MESSAGE, "additional");
    $decrypted = $decrypter->decrypt($encrypted, "additional");
    $decrypted->unlock;
    is($decrypted, $msg, "decrypted with additional data ok ($alg)");
    $encrypted = $encrypter->encrypt($msg, $m->TAG_MESSAGE, "more");
    eval { $decrypted = $decrypter->decrypt($encrypted, "less"); };
    like($@, qr/Message forged/, "decrypt with bad additional data failed ($alg)");
    $decrypted = $decrypter->decrypt($encrypted, "more");
    $decrypted->unlock;
    is($decrypted, $msg, "decrypt again with correct data succeeds ($alg)");

  }

}

done_testing();
