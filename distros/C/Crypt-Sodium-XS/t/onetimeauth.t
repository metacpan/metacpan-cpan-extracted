use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::OO::onetimeauth;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my $msg = "Signed by me";

#TODO: test cloning. test hashing memvault.

for my $alg (Crypt::Sodium::XS::OO::onetimeauth->primitives) {
  my $m = Crypt::Sodium::XS::OO::onetimeauth->new(primitive => $alg);

  my $key = $m->keygen;
  ok($key, "key generated ($alg)");

  my $mac = $m->onetimeauth($msg, $key);
  ok($mac, "got mac for msg ($alg)");

  ok($m->verify($mac, $msg, $key), "msg verified ($alg)");

  my $hasher_1 = $m->init($key);
  ok($hasher_1, "hasher_1 initialized ($alg)");
  my $hasher_2 = $m->init($key);
  ok($hasher_2, "hasher_2 initialized ($alg)");
  for my $c ( split(//, $msg) ) {
    $hasher_1->update($c);
    $hasher_2->update($c);
  }
  my $hash_1 = $hasher_1->final;
  ok($hash_1, "hasher_1 produced final mac ($alg)");
  my $hash_2 = $hasher_2->final;
  ok($hash_2, "hasher_2 produced final mac ($alg)");
  is(unpack("H*", $hash_1), unpack("H*", $hash_2), "macs match ($alg)");

  ok($m->verify($hash_1, $msg, $key), "Message /1 verified ($alg)");
  ok($m->verify($hash_2, $msg, $key), "Message /2 verified ($alg)");

}

done_testing();
