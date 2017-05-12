

use Test::More;
BEGIN { use_ok('Crypt::Curve25519') };

# OO
my $c = Crypt::Curve25519->new();

my $alice_rand = '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a';
my $bob_rand = '5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb';

# Alice:
my $alice_secret_key_hex = $c->secret_key($alice_rand);
my $alice_public_key_hex = $c->public_key( $alice_secret_key_hex );

# Bob:
my $bob_secret_key_hex = $c->secret_key($bob_rand);
my $bob_public_key_hex = $c->public_key( $bob_secret_key_hex );

# Alice and Bob exchange their public keys

# Alice calculates shared secret to communicate with Bob
my $shared_secret_with_bob_hex = $c->shared_secret(
                                $alice_secret_key_hex,
                                $bob_public_key_hex);

# Bob calculates shared secret to communicate with Alice
my $shared_secret_with_alice_hex = $c->shared_secret(
                                $bob_secret_key_hex,
                                $alice_public_key_hex);

# Shared secrets are equal
is( $shared_secret_with_bob_hex, $shared_secret_with_alice_hex,
    "Shared secrets match: $shared_secret_with_bob_hex");

# procedular

# Alice:
my $alice_secret_key = curve25519_secret_key(pack('H64', $alice_rand));
my $alice_public_key = curve25519_public_key( $alice_secret_key );

# Bob:
my $bob_secret_key = curve25519_secret_key(pack('H64', $bob_rand));
my $bob_public_key = curve25519_public_key( $bob_secret_key );

# Alice calculates shared secret to communicate with Bob
my $shared_secret_with_bob = curve25519_shared_secret( $alice_secret_key,
                                $bob_public_key);

# Bob calculates shared secret to communicate with Alice
my $shared_secret_with_alice = curve25519_shared_secret( $bob_secret_key,
                                $alice_public_key);

# Shared secrets are equal
is( $shared_secret_with_bob, $shared_secret_with_alice,
    "Shared secrets match: ". unpack('H64', $shared_secret_with_bob));


# OO vs proc
is( $alice_secret_key_hex, unpack('H64', $alice_secret_key),
    "Alice's secret keys in OO and procedular interfaces are the same");
is( $alice_public_key_hex, unpack('H64', $alice_public_key),
    "... as are public keys");
is( $bob_secret_key_hex, unpack('H64', $bob_secret_key),
    "Bob's secret keys in OO and procedular interfaces are the same");
is( $bob_public_key_hex, unpack('H64', $bob_public_key),
    "... as are public keys");

is( $shared_secret_with_bob_hex, unpack('H64', $shared_secret_with_alice),
    "Shared secrets in OO and procedular interfaces are also the same");


done_testing();

