use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::OO::kdf;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

for my $alg (Crypt::Sodium::XS::OO::kdf->primitives) {
  my $m = Crypt::Sodium::XS::OO::kdf->new(primitive => $alg);

  my @test_lens = qw(KEYBYTES BYTES_MAX);
  for my $blen (@test_lens) {
    ok($m->$blen > 0, "$blen > 0 ($alg)");
  }

  my $min = $m->BYTES_MIN;
  my $max = $m->BYTES_MAX;

  my $mk = $m->keygen;
  ok($mk, "generated master key ($alg)");

  my $subkey = $m->derive($mk, 1, $min);
  ok($subkey, "generated a min length subkey ($alg)");
  is($subkey->size, $min, "min length correct size ($alg)");
  $subkey = $m->derive($mk, 1, $max);
  ok($subkey, "generated a max length subkey ($alg)");
  is($subkey->size, $max, "max length correct size ($alg)");

  eval { my $x = $m->derive($mk, 13, $m->BYTES_MIN, "short") };
  like($@, qr/Invalid context length \(too short\)/, "short context rejected ($alg)");

  my $sk1 = $m->derive($mk, 4294967295, $min);
  my $sk2 = $m->derive($mk, 4294967296, $min);
  my $sk3 = $m->derive($mk, 4294967297, $min);
  ok(!$sk2->memcmp($sk1), "keys differ reaching id 2 ** 32 ($alg)");
  ok(!$sk3->memcmp($sk2), "keys differ after id 2 ** 32 ($alg)");

  eval { $sk1 = $m->derive($mk, 2 ** 53 - 2, $min); };
  is($@, '', "id 2 ** 53 - 2 accepted");
  isa_ok($sk1, 'Crypt::Sodium::XS::MemVault', 'id 2 ** 53 - 2 returned MemVault');
  eval { $sk2 = $m->derive($mk, 2 ** 53 - 1, $min); };
  is($@, '', "id 2 ** 53 - 1 accepted");
  isa_ok($sk2, 'Crypt::Sodium::XS::MemVault', 'id 2 ** 53 - 1 returned MemVault');
  ok(!$sk1->memcmp($sk2), 'id 2 ** 53 - 2 and id 2 ** 53 - 1 keys differ');
  eval { $m->derive($mk, 2 ** 53, $min); };
  like($@, qr/id cannot be larger than/, "id above 2 ** 53 - 1 rejected");

  for my $len ($min .. $max) {
    next if $len % 8;
    my $child1 = $m->derive($mk, 42, $len);
    ok($child1, "derived key, no context ($alg:$len)");
    # same id should never actually be used, as it makes the same key!
    my $child2 = $m->derive($mk, 42, $len);
    is($child2->to_hex->unlock, $child1->to_hex->unlock,
       "derived same key for same id, no context ($alg:$len)");

    my $child3 = $m->derive($mk, 999, $len);
    isnt($child3->to_hex->unlock, $child2->to_hex->unlock,
         "different id produces different key ($alg:$len)");

    my $child4 = $m->derive($mk, 42, $len, "newcontext");
    isnt($child4->to_hex->unlock, $child2->to_hex->unlock,
         "different context produces different key ($alg:$len)");

  }
}

done_testing();
