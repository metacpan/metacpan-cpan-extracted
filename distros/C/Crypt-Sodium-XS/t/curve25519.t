use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my $scalarmult = Crypt::Sodium::XS->scalarmult(primitive => 'ed25519');
my $curve25519 = Crypt::Sodium::XS->curve25519(primitive => 'ed25519');

for my $alg ($curve25519->primitives) {

  if ($alg eq 'ristretto255' and !$scalarmult->ristretto255_available) {
    # should be impossible to have the primitive here and no support there
    ok($scalarmult->ristretto255_available, "scalarmult ristretto255 available");
  }
  $curve25519->primitive($alg);
  $scalarmult->primitive($alg);

  # from libsodium example code:
  # Perform a secure two-party computation of f(x) = p(x)^k. x is the input
  # sent to the second party by the first party after blinding it using a
  # random invertible scalar r, and k is a secret key only known by the second
  # party. p(x) is a hash-to-group function.

  # note here using ->random for $px; p(x) would be generating randomness x of
  # BYTES length and then using ->from_hash (ristretto255) or ->from_uniform
  # (ed25519) as the p() function.
  # also using ->scalar_random instead of generating randomness
  # (NONREDUCEDSCALARBYTES length, twice the length of SCALARBYTES) given to
  # ->reduce to generate $r.

  # party 1

  my $px = $curve25519->random;
  ok($px, "generated p(x): random point ($alg)");
  ok($curve25519->is_valid_point($px), "px is a valid point ($alg)");
  is(length($px), $curve25519->BYTES, "random point is correct length ($alg)");

  my $r = $curve25519->scalar_random;
  ok($r, "generated r: random scalar ($alg)");
  isa_ok($r, 'Crypt::Sodium::XS::MemVault', "random scalar isa MemVault ($alg)");
  is($r->size, $curve25519->SCALARBYTES, "random scalar is correct length ($alg)");

  my $gr;
  if ($alg eq 'ristretto255') {
    $gr = $scalarmult->base($r);
  }
  else { # ed25519
    $gr = $scalarmult->base_noclamp($r);
  }
  ok($gr, "generated gr: g^r base point ($alg)");

  my $aa = $curve25519->add($px, $gr);
  ok($aa, "generated aa: blinded p(x) with g^r ($alg)");

  # party 2, gets $aa

  my $k = $curve25519->scalar_random;
  ok($r, "generated k: random scalar ($alg)");
  my $v = $scalarmult->base($k);
  ok($v, "generated v: g^k base point ($alg)");
  my $bb = $scalarmult->scalarmult($k, $aa);
  ok($bb, "generated bb: aa^k ($alg)");

  # party 1, gets $v and $bb

  my $ir = $curve25519->scalar_negate($r);
  ok($ir, "generated ir: inversion of r ($alg)");
  isa_ok($ir, 'Crypt::Sodium::XS::MemVault', "ir isa MemVault ($alg)");
  is($ir->size, $curve25519->SCALARBYTES, "ir is correct length ($alg)");

  my $vir;
  if ($alg eq 'ristretto255') {
    $vir = $scalarmult->scalarmult($ir, $v);
  }
  else { # ed25519
    $vir = $scalarmult->scalarmult_noclamp($ir, $v);
  }
  ok($vir, "generated vir: v^ir ($alg)");
  isa_ok($vir, 'Crypt::Sodium::XS::MemVault', "vir isa MemVault ($alg)");
  is($vir->size, $curve25519->SCALARBYTES, "vir is correct length ($alg)");

  my $fx = $curve25519->add($bb, $vir);
  ok($fx, "generated fx: bb * v^ir ($alg)");

  my $pxk = $scalarmult->scalarmult($k, $px);
  ok($pxk, "generated pxk: p(x)^k ($alg)");
  isa_ok($pxk, 'Crypt::Sodium::XS::MemVault', "pxk isa MemVault ($alg)");
  is($pxk->size, $curve25519->SCALARBYTES, "pxk is correct length ($alg)");
  ok($pxk->memcmp($fx), "fx = bb * v^ir = (p(x) * g^r)^k * (g^k)^ir = (p(x) * g)^k * g^(-k) = p(x)^k ($alg)");

}
done_testing();
