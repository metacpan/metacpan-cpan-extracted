
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(bin2hex);

my $crypto_scalarmult = Crypt::NaCl::Sodium->scalarmult();

ok($crypto_scalarmult->$_ > 0, "$_ > 0")
    for qw( BYTES SCALARBYTES );

for ( 1 .. 2 ) {
    my $skeyA = $crypto_scalarmult->keygen();
    ok($skeyA, "skeyA generated");
    my $skeyB = $crypto_scalarmult->keygen();
    ok($skeyB, "skeyB generated");

    my $pkeyA = $crypto_scalarmult->base($skeyA);
    ok($pkeyA, "pkeyA calculated");
    my $pkeyB = $crypto_scalarmult->base($skeyB);
    ok($pkeyB, "pkeyB calculated");

    my $sharedAB = $crypto_scalarmult->shared_secret($skeyA, $pkeyB);
    ok($sharedAB, "sharedAB calculated");
    my $sharedBA = $crypto_scalarmult->shared_secret($skeyB, $pkeyA);
    ok($sharedBA, "sharedBA calculated");

    is(bin2hex($sharedAB), bin2hex($sharedBA), "Sab(skA, pkB) === Sba(skB, pkA)");
}

done_testing();
