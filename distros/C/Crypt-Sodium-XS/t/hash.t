use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::OO::hash;
use Digest::SHA qw/sha256_hex sha512_hex/;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my @adatas = (
  "Parcel was dispatched",
  "Hello World!",
);

# TODO: test cloning

for my $alg (Crypt::Sodium::XS::OO::hash->primitives) {
  my $m = Crypt::Sodium::XS::OO::hash->new(primitive => $alg);

  my $validator;
  if ($alg eq 'sha256') {
    $validator = \&sha256_hex;
  }
  elsif ($alg eq 'sha512') {
    $validator = \&sha512_hex;
  }

  ok($m->BYTES > 0, "BYTES > 0 ($alg)");

  for my $msg (@adatas) {
    my ($mac);

    $mac = $m->hash($msg);
    ok($mac, "hash for msg($alg)");
    is(unpack("H*", $mac), $validator->($msg), "hash agrees with perl's") if $validator;

    if ($alg ne 'default') {
      my $hasher = $m->init;
      ok($hasher, "hasher initialized ($alg)");
      my $hasher2 = $hasher->clone;
      ok($hasher2, "hasher cloned ($alg)");
      for my $c (split(//, $msg)) {
        $hasher->update($c);
        $hasher2->update($c);
      }
      my $hash = $hasher->final;
      my $hash2 = $hasher2->final;
      ok($hash, "hasher produced final hash ($alg)");
      is(unpack("H*", $hash), unpack("H*", $mac),
         "hasher produced same hash ($alg)");
      is(unpack("H*", $hash), $validator->($msg), "hasher agrees with perl's ($alg)") if $validator;
      is(unpack("H*", $hash2), unpack("H*", $hash),
         "cloned hasher produced same hash ($alg)");
    }
  }

}

done_testing();
