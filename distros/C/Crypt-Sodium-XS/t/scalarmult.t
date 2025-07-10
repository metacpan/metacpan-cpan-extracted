use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS;

my $scalarmult = Crypt::Sodium::XS->scalarmult;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

ok($scalarmult->BYTES > 0, "scalarmult_BYTES > 0");
ok($scalarmult->SCALARBYTES > 0, "scalarmult_SCALARBYTES > 0");

for (1 .. 2) {
  my $skeyA = $scalarmult->keygen;
  ok($skeyA, "skeyA generated");
  my $skeyB = $scalarmult->keygen;
  ok($skeyB, "skeyB generated");

  my $pkeyA = $scalarmult->base($skeyA);
  ok($pkeyA, "pkeyA calculated");
  my $pkeyB = $scalarmult->base($skeyB);
  ok($pkeyB, "pkeyB calculated");

  my $sharedAB = $scalarmult->scalarmult($skeyA, $pkeyB);
  ok($sharedAB, "sharedAB calculated");
  my $sharedBA = $scalarmult->scalarmult($skeyB, $pkeyA);
  ok($sharedBA, "sharedBA calculated");

  is(unpack("H*", $sharedAB->unlock), unpack("H*", $sharedBA->unlock),
     "Sab(skA, pkB) === Sba(skB, pkA)");
}

done_testing();
