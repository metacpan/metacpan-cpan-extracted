use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS;
use Crypt::Sodium::XS::scalarmult;

use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;


for my $alg (Crypt::Sodium::XS::scalarmult->primitives) {
  my $scalarmult = Crypt::Sodium::XS->scalarmult(primitive => $alg);

  ok($scalarmult->BYTES > 0, "scalarmult_BYTES > 0 ($alg)");
  ok($scalarmult->SCALARBYTES > 0, "scalarmult_SCALARBYTES > 0 ($alg)");

  for (1 .. 2) {
    my $skeyA = $scalarmult->keygen;
    ok($skeyA, "skeyA generated ($alg)");
    my $skeyB = $scalarmult->keygen;
    ok($skeyB, "skeyB generated ($alg)");

    my $pkeyA = $scalarmult->base($skeyA);
    ok($pkeyA, "pkeyA calculated ($alg)");
    my $pkeyB = $scalarmult->base($skeyB);
    ok($pkeyB, "pkeyB calculated ($alg)");

    my $sharedAB = $scalarmult->scalarmult($skeyA, $pkeyB);
    ok($sharedAB, "sharedAB calculated ($alg)");
    my $sharedBA = $scalarmult->scalarmult($skeyB, $pkeyA);
    ok($sharedBA, "sharedBA calculated ($alg)");

    is(unpack("H*", $sharedAB->unlock), unpack("H*", $sharedBA->unlock),
       "Sab(skA, pkB) === Sba(skB, pkA) ($alg)");
  }

}

done_testing();
