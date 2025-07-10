use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::hkdf 'hkdf_available';
use Crypt::Sodium::XS::OO::hkdf;

plan skip_all => 'no hkdf available' unless hkdf_available;

use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

for my $alg (Crypt::Sodium::XS::OO::hkdf->primitives) {
  my $m = Crypt::Sodium::XS::OO::hkdf->new(primitive => $alg);

  for my $blen (qw(KEYBYTES BYTES_MAX)) {
    ok($m->$blen > 0, "$blen > 0 ($alg)");
  }

  my $mk = $m->keygen;
  ok($mk, "generated master key ($alg)");

  my $prk1 = $m->extract($mk);
  ok($prk1, "generated a prk (from master ikm) ($alg)");
  is($prk1->length, $m->KEYBYTES, "prk length ($alg)");

  my $prk2 = $m->extract($mk);
  ok($prk2->memcmp($prk1), "extract same prk from same ikm ($alg)");

  $prk1 = $m->extract($mk, "foo");
  $prk2 = $m->extract($mk, "foo");
  ok($prk2->memcmp($prk1), "extract same prk from same ikm with same salt ($alg)");

  $prk2 = $m->extract($mk, "basalt");
  ok($prk2, "generated a prk (from master ikm and salt) ($alg)");
  ok(!$prk1->memcmp($prk2), "prk without and with salt differ ($alg)");
  my $prk3 = $m->extract($mk, "bapepper");
  ok(!$prk2->memcmp($prk3), "prk with different salts differ ($alg)");

  my $sk1 = $m->expand($prk1, 1);
  is($sk1->length, 1, "generated a 1 byte subkey ($alg)");
  my $sk2 = $m->expand($prk1, 2048);
  is($sk2->length, 2048, "generated a 2048 byte subkey ($alg)");

  my $sk3 = $m->expand($prk1, 2048);
  ok($sk3->memcmp($sk2), "expand same subkey from same prk ($alg)");

  $sk1 = $m->expand($prk1, 64, "foo");
  $sk2 = $m->expand($prk1, 64, "foo");
  ok($sk2->memcmp($sk1), "expand same subkey from same prk with same context ($alg)");

  $sk1 = $m->expand($prk1, 64);
  $sk2 = $m->expand($prk1, 64, "foo");
  ok(!$sk2->memcmp($sk1), "subkey without and with context differ ($alg)");
  $sk1 = $m->expand($prk1, 64, "bar");
  ok(!$sk1->memcmp($sk2), "subkey with different contexts differ ($alg)");

  $sk1 = $m->expand($prk1, 64);
  $sk2 = $m->expand($prk2, 64);
  ok(!$sk2->memcmp($sk1), "subkey with different prk differ ($alg)");

  $sk1 = $m->expand($prk1, 64, "context");
  $sk2 = $m->expand($prk2, 64, "context");
  ok(!$sk1->memcmp($sk2), "subkey with different prk and same context differ ($alg)");

  # assume extract implies extract_init (hkdf)

  $prk1 = $m->extract($mk);
  my $gen = $m->extract_init;
  $gen->update($mk);
  $prk2 = $gen->final;
  ok($prk2->memcmp($prk1), "prk extract/multipart with same ikm match ($alg)");

  $prk1 = $m->extract($mk, "foo");
  $gen = $m->extract_init("foo");
  $gen->update($mk);
  $prk2 = $gen->final;
  ok($prk2->memcmp($prk1), "prk extract/multipart with same ikm and salt match ($alg)");

  $prk1 = $m->extract($mk);
  $gen = $m->extract_init;
  $gen->update($m->keygen);
  $prk2 = $gen->final;
  ok(!$prk2->memcmp($prk1), "prk extract/multipart with different ikm differ ($alg)");

  $prk1 = $m->extract($mk, "foo");
  $gen = $m->extract_init("bar");
  $gen->update($mk);
  $prk2 = $gen->final;
  ok(!$prk2->memcmp($prk1), "prk extract/multipart with different salt and same ikm differ ($alg)");

  $prk1 = $m->extract($mk, "foo");
  $gen = $m->extract_init("foo");
  $gen->update($m->keygen);
  $prk2 = $gen->final;
  ok(!$prk2->memcmp($prk1), "prk extract/multipart with same salt and different ikm differ ($alg)");

}

done_testing();
