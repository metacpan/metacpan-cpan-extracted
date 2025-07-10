use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::MemVault;
use Crypt::Sodium::XS::generichash qw(generichash_blake2b_SALTBYTES generichash_blake2b_PERSONALBYTES);
use Crypt::Sodium::XS::OO::generichash;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my $msg = join('', 'a' .. 'z');
# needs testing differing salts/personals, and lengths greater than saltbytes.
my $salt = 'a' x generichash_blake2b_SALTBYTES;
my $personal = 'z' x generichash_blake2b_PERSONALBYTES;

for my $alg (Crypt::Sodium::XS::OO::generichash->primitives) {
  my $m = Crypt::Sodium::XS::OO::generichash->new(primitive => $alg);

  ok($m->$_ > 0, "$_ > 0 ($alg)")
    for qw(BYTES_MAX BYTES_MIN KEYBYTES_MAX KEYBYTES_MIN);
  if ($alg eq 'blake2b') {
    ok($m->PERSONALBYTES > 0, "PERSONALBYTES > 0 ($alg)");
    ok($m->SALTBYTES > 0, "SALTBYTES > 0 ($alg)");
  }

  for my $bytes ($m->BYTES_MIN .. $m->BYTES_MAX) {
    next unless $bytes % 4 == 0; # rather than 35109510 bajillion tests

    my $mac = $m->generichash($msg, $bytes);

# FIXME: needs basically all this testing for blake2b with salt and personalization

    # without key
    my $hasher1 = $m->init($bytes);
    ok($hasher1, "hasher1 without key initialized ($alg:$bytes)");
    my $hasher2 = $m->init($bytes);
    ok($hasher2, "hasher2 without key initialized ($alg:$bytes)");
    for my $c (split(//, $msg)) {
      $hasher1->update($c);
      $hasher2->update($c);
    }
    my $hasher3 = $hasher2->clone;
    ok($hasher3, "hasher3 cloned ($alg:$bytes)");

    my $hash1 = $hasher1->final;
    ok($hash1, "hasher1 produced final mac ($alg:$bytes)");
    is(length($hash1), $bytes, "correct mac length ($alg:$bytes)");
    is(unpack("H*", $hash1), unpack("H*", $mac), "hasher1 matches mac ($alg:$bytes)");

    my $hash2 = $hasher2->final;
    ok($hash2, "hasher2 produced final mac ($alg:$bytes)");
    is(length($hash2), $bytes, "correct mac length ($alg:$bytes)");
    is(unpack("H*", $hash2), unpack("H*", $mac), "hasher2 matches mac ($alg:$bytes)");

    my $hash3 = $hasher3->final;
    ok($hash3, "hasher2 produced final mac ($alg:$bytes)");
    is(length($hash3), $bytes, "correct mac length ($alg:$bytes)");
    is(unpack("H*", $hash3), unpack("H*", $mac), "hasher3 matches mac ($alg:$bytes)");

    # with key
    for my $keybytes ($m->KEYBYTES_MIN ..  $m->KEYBYTES_MAX) {
      next unless $keybytes % 4 == 0;

      my $key = $m->keygen($keybytes);
      ok($key, "key generated ($alg:$bytes:$keybytes)");
      is($key->length, $keybytes, "correct key length ($alg:$bytes:$keybytes)");

      my $hasher1 = $m->init($bytes, $key);
      ok($hasher1, "hasher1 with key initialized ($alg:$bytes:$keybytes)");
      my $hasher2 = $m->init($bytes, $key);
      ok($hasher2, "hasher2 with key initialized ($alg:$bytes:$keybytes)");

      my $mac = $m->generichash($msg, $bytes, $key);

      for my $c (split(//, $msg)) {
        $hasher1->update($c);
        $hasher2->update($c);
      }
      my $hasher3 = $hasher1->clone;
      ok($hasher3, "hasher3 cloned ($alg:$bytes:$keybytes)");

      my $hash1 = $hasher1->final;
      ok($hash1, "hasher1 produced final mac ($alg:$bytes:$keybytes)");
      is(length($hash1), $bytes, "correct mac length ($alg:$bytes:$keybytes)");
      is(unpack("H*", $hash1), unpack("H*", $mac), "hasher1 matches mac ($alg:$bytes:$keybytes)");

      my $hash2 = $hasher2->final;
      ok($hash2, "hasher2 produced final mac ($alg:$bytes:$keybytes)");
      is(length($hash2), $bytes, "correct mac length ($alg:$bytes:$keybytes)");
      is(unpack("H*", $hash2), unpack("H*", $mac), "hasher2 matches mac ($alg:$bytes:$keybytes)");

      my $hash3 = $hasher3->final;
      ok($hash3, "hasher3 produced final mac ($alg:$bytes:$keybytes)");
      is(length($hash3), $bytes, "correct mac length ($alg:$bytes:$keybytes)");
      is(unpack("H*", $hash3), unpack("H*", $mac), "hasher3 matches mac ($alg:$bytes:$keybytes)");
    }
  }

  if ($alg eq 'blake2b') {
    # ugly as heck copy-paste for salt and personal.
    for my $bytes ($m->BYTES_MIN .. $m->BYTES_MAX) {
      next unless $bytes % 4 == 0; # rather than 35109510 bajillion tests

      my $mac = $m->salt_personal($msg, $salt, $personal, $bytes);

      # without key
      my $hasher1 = $m->init_salt_personal($salt, $personal, $bytes);
      ok($hasher1, "hasher1 without key initialized ($alg:$bytes)");
      my $hasher2 = $m->init_salt_personal($salt, $personal, $bytes);
      ok($hasher2, "hasher2 without key initialized ($alg:$bytes)");
      for my $c (split(//, $msg)) {
        $hasher1->update($c);
        $hasher2->update($c);
      }
      my $hasher3 = $hasher2->clone;
      ok($hasher3, "hasher3 cloned ($alg:$bytes)");

      my $hash1 = $hasher1->final;
      ok($hash1, "hasher1 produced final mac ($alg:$bytes)");
      is(length($hash1), $bytes, "correct mac length ($alg:$bytes)");
      is(unpack("H*", $hash1), unpack("H*", $mac), "hasher1 matches mac ($alg:$bytes)");

      my $hash2 = $hasher2->final;
      ok($hash2, "hasher2 produced final mac ($alg:$bytes)");
      is(length($hash2), $bytes, "correct mac length ($alg:$bytes)");
      is(unpack("H*", $hash2), unpack("H*", $mac), "hasher2 matches mac ($alg:$bytes)");

      my $hash3 = $hasher3->final;
      ok($hash3, "hasher2 produced final mac ($alg:$bytes)");
      is(length($hash3), $bytes, "correct mac length ($alg:$bytes)");
      is(unpack("H*", $hash3), unpack("H*", $mac), "hasher3 matches mac ($alg:$bytes)");

      # with key
      for my $keybytes ($m->KEYBYTES_MIN ..  $m->KEYBYTES_MAX) {
        next unless $keybytes % 4 == 0;

        my $key = $m->keygen($keybytes);
        ok($key, "key generated ($alg:$bytes:$keybytes)");
        is($key->length, $keybytes, "correct key length ($alg:$bytes:$keybytes)");

        my $mac = $m->salt_personal($msg, $salt, $personal, $bytes, $key);

        my $hasher1 = $m->init_salt_personal($salt, $personal, $bytes, $key);
        ok($hasher1, "hasher1 with key initialized ($alg:$bytes:$keybytes)");
        my $hasher2 = $m->init_salt_personal($salt, $personal, $bytes, $key);
        ok($hasher2, "hasher2 with key initialized ($alg:$bytes:$keybytes)");

        for my $c (split(//, $msg)) {
          $hasher1->update($c);
          $hasher2->update($c);
        }
        my $hasher3 = $hasher1->clone;
        ok($hasher3, "hasher3 cloned ($alg:$bytes:$keybytes)");

        my $hash1 = $hasher1->final;
        ok($hash1, "hasher1 produced final mac ($alg:$bytes:$keybytes)");
        is(length($hash1), $bytes, "correct mac length ($alg:$bytes:$keybytes)");
        is(unpack("H*", $hash1), unpack("H*", $mac), "hasher1 matches mac ($alg:$bytes:$keybytes)");

        my $hash2 = $hasher2->final;
        ok($hash2, "hasher2 produced final mac ($alg:$bytes:$keybytes)");
        is(length($hash2), $bytes, "correct mac length ($alg:$bytes:$keybytes)");
        is(unpack("H*", $hash2), unpack("H*", $mac), "hasher2 matches mac ($alg:$bytes:$keybytes)");

        my $hash3 = $hasher3->final;
        ok($hash3, "hasher3 produced final mac ($alg:$bytes:$keybytes)");
        is(length($hash3), $bytes, "correct mac length ($alg:$bytes:$keybytes)");
        is(unpack("H*", $hash3), unpack("H*", $mac), "hasher3 matches mac ($alg:$bytes:$keybytes)");
      }
    }
  }

  my $hash = $m->generichash(Crypt::Sodium::XS::MemVault->new("foobar"));
  ok($hash, "generated hash with memvault input");
  my $hasher = $m->init;
  $hasher->update(Crypt::Sodium::XS::MemVault->new("foobar"));
  my $hash2 = $hasher->final;
  ok($hash eq $hash2, "memvault input hash and multipart are eq");


  eval { $m->generichash("foo", 1) };
  like($@, qr/Invalid output length/, "fail requesting too few bytes ($alg)");
  eval { $m->generichash("foo", 4096) };
  like($@, qr/Invalid output length/, "fail requesting too many bytes ($alg)");
}

done_testing();
