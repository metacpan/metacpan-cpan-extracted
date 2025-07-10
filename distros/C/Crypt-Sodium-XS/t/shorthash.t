use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::OO::shorthash;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my @adatas = (
  "i wish i was",
  "a little bit",
  "taller",
  "",
);

for my $alg (Crypt::Sodium::XS::OO::shorthash->primitives) {
  my $m = Crypt::Sodium::XS::OO::shorthash->new(primitive => $alg);

  ok($m->BYTES > 0, "shorthash_BYTES > 0");
  ok($m->KEYBYTES > 0, "shorthash_KEYBYTES > 0");

  my $key1 = $m->keygen;
  ok($key1, "key generated");
  my $key2 = $m->keygen;

  for my $msg (@adatas) {
    my $mac1 = $m->shorthash($msg, $key1);
    ok($mac1, "mac calculated");
    my $mac2 = $m->shorthash($msg, $key1);
    is($mac1, $mac2, "same keys, same hash output");
    my $mac3 = $m->shorthash("something else", $key1);
    isnt($mac1, $mac3, "different input, different hash output");
    my $mac4 = $m->shorthash($msg, $key2);
    isnt($mac1, $mac4, "different keys, different hash output");
  }

}

done_testing();
