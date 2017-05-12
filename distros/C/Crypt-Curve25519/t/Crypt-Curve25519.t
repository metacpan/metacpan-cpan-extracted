use strict;
use warnings;

use Test::More;
use Crypt::Curve25519;

# e1
my $alice_secret_key = pack('H64', '03');
# e2
my $bob_secret_key   = pack('H64', '05');
# k
my $basepoint        = pack('H64', '09');

my $alice_200_expected  = 'bc7112cde03f97ef7008cad1bdc56be3c6a1037d74cceb3712e9206871dcf654';
my $bob_200_expected    = 'dd8fa254fb60bdb5142fe05b1f5de44d8e3ee1a63c7d14274ea5d4c67f065467';
my $shared_200_expected = '7ddb98bd89025d2347776b33901b3e7ec0ee98cb2257a4545c0cfb2ca3e1812b';

my $alice_10k_expected  = '4faf81190869fd742a33691b0e0824d57e0329f4dd2819f5f32d130f1296b500';
my $bob_10k_expected    = '05aec13f92286f3a781ccae98995a3b9e0544770bc7de853b38f9100489e3e79';
my $shared_10k_expected = 'cd6e8269104eb5aaee886bd2071fba88bd13861475516bc2cd2b6e005e805064';

for my $iter ( 1 .. 10000 ) {
    # e1k = f(e1, k)
    my $alice_public_key = curve25519_public_key($alice_secret_key, $basepoint);
    # e2k = f(e2, k)
    my $bob_public_key = curve25519_public_key($bob_secret_key, $basepoint);

    # e1e2k = f(e1, e2k)
    my $alice_shared_secret = curve25519_shared_secret($alice_secret_key, $bob_public_key);
    # e2e1k = f(e2, e1k)
    my $bob_shared_secret = curve25519_shared_secret($bob_secret_key, $alice_public_key);

    is($alice_shared_secret, $bob_shared_secret, "Shared secret matched: ".
        unpack('H64', $alice_shared_secret));

    if ( $iter == 200 ) {
        my $alice_200 = unpack('H64', $alice_secret_key);
        is($alice_200, $alice_200_expected, "Iteration no. 200 calculates correct secret key for Alice: $alice_200");
        my $bob_200 = unpack('H64', $bob_public_key);
        is($bob_200, $bob_200_expected, "... and correct public key for Bob: $bob_200");
        my $shared_200 = unpack('H64', $alice_shared_secret);
        is($shared_200, $shared_200_expected, "... and correct shared key for Alice & Bob: $shared_200");
    }
    elsif ( $iter == 10_000 ) {
        my $alice_10k = unpack('H64', $alice_secret_key);
        is($alice_10k, $alice_10k_expected, "Iteration no. 10000 calculates correct secret key for Alice: $alice_10k");
        my $bob_10k = unpack('H64', $bob_public_key);
        is($bob_10k, $bob_10k_expected, "... and correct public key for Bob: $bob_10k");
        my $shared_10k = unpack('H64', $alice_shared_secret);
        is($shared_10k, $shared_10k_expected, "... and correct shared key for Alice & Bob: $shared_10k");
    }

    $alice_secret_key ^= $bob_public_key;
    $bob_secret_key ^= $alice_public_key;
    $basepoint ^= $alice_shared_secret;
}

done_testing();

