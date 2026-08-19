#!/usr/bin/env perl
use v5.36;
use Test::More;

BEGIN {
    eval {
        require Math::BigInt;
        require Digest::SHA;
    };
    if ($@) {
        plan skip_all => 'Math::BigInt or Digest::SHA not available';
    }
}

use_ok('Protocol::HAP::SRP');
use_ok('Protocol::HAP::Crypto');

# Test that the module pads A and B to N_len (384 bytes) when it
# computes u, M1, and M2. This padding is critical for SRP-6a
# compatibility with HomeKit.
#
# Bug: the original implementation did not pad A and B to 384 bytes
# before hashing. This caused proof verification failures with the
# iOS Home app.

# Test padding of A and B in u computation
{
    my $srp = Protocol::HAP::SRP->new(password => '123-45-678');
    my $salt = $srp->generate_salt();
    $srp->compute_verifier($salt);
    my $B = $srp->generate_server_public();

    # Create a client public key A that encodes to less than 384
    # bytes. For example, a small value such as 256 (0x100) is 2
    # bytes without padding.
    my $A_small = Math::BigInt->new(256);
    my $A_bytes_unpadded = Protocol::HAP::SRP::_bigint_to_bytes($A_small);

    # Without padding, the value is 2 bytes
    ok(length($A_bytes_unpadded) < 384,
        'Small A is less than 384 bytes without padding');

    # With padding, the value must be 384 bytes
    my $A_bytes_padded = Protocol::HAP::SRP::_bigint_to_bytes($A_small, 384);
    is(length($A_bytes_padded), 384,
        '[HAP-Pairing §2.5] small A is left-padded to 384 bytes');

    # Make sure the padding uses leading zeros
    is(unpack('H*', $A_bytes_padded), ('00' x 382) . '0100',
        '[HAP-Pairing §2.5] A is padded with leading zeros');
}

# Test that compute_session_key uses padded A and B for u
{
    my $srp = Protocol::HAP::SRP->new(password => '123-45-678');
    my $salt = $srp->generate_salt();
    $srp->compute_verifier($salt);
    $srp->generate_server_public();
    
    # Create two different encodings of the same A value. One
    # encoding is minimal. The other one has padding to 384 bytes.
    my $A_val = Math::BigInt->new(12345);
    my $A_bytes_unpadded = Protocol::HAP::SRP::_bigint_to_bytes($A_val);
    my $A_bytes_padded = Protocol::HAP::SRP::_bigint_to_bytes($A_val, 384);
    
    isnt(length($A_bytes_unpadded), length($A_bytes_padded),
        'Padded and unpadded A have different lengths');

    # Both encodings must give the same session key. Internally,
    # compute_session_key pads A to 384 bytes before it computes u.
    my $K1 = $srp->compute_session_key($A_bytes_unpadded);

    # Use a fresh SRP instance for the second test
    my $srp2 = Protocol::HAP::SRP->new(password => '123-45-678');
    $srp2->generate_salt();
    $srp2->compute_verifier($salt);
    # Copy the same b and B to keep the server state identical
    $srp2->{b} = $srp->{b};
    $srp2->{B} = $srp->{B};
    $srp2->{v} = $srp->{v};
    $srp2->{salt} = $srp->{salt};

    my $K2 = $srp2->compute_session_key($A_bytes_padded);

    ok(defined $K1 && defined $K2, 'Both session keys computed');
    is(unpack('H*', $K1), unpack('H*', $K2),
        '[HAP-Pairing §2.6] u uses PAD(A): unpadded and padded A '
        . 'wire encodings derive the same session key');
}

# Test full SRP exchange with known values to check the padding
{
    # Set up SRP with known parameters
    my $password = '123-45-678';
    my $srp = Protocol::HAP::SRP->new(password => $password);
    
    # Generate a known salt. For reproducibility, use a fixed value
    # in a real test.
    my $salt = $srp->generate_salt();
    $srp->compute_verifier($salt);
    my $B = $srp->generate_server_public();
    
    # Create a valid client public key A. It must be non-zero mod N.
    # For the test, use a small valid value.
    my $A_int = Math::BigInt->new(2)->bmodpow(Math::BigInt->new(256), $srp->{N});
    my $A_bytes = Protocol::HAP::SRP::_bigint_to_bytes($A_int, 384);
    
    # Compute the session key. This internally computes
    # u = H(PAD(A) | PAD(B)).
    my $K = $srp->compute_session_key($A_bytes);
    ok(defined $K, 'Session key computed successfully');
    is(length($K), 64,
        '[HAP-Pairing §2.6] session key K = H(S) is 64 bytes (SHA-512)');
    
    # Make sure the object stores the internal A
    ok(defined $srp->{A}, 'A is stored in SRP object');
    
    # Compute the client proof M1. The client usually computes this
    # value, but the test can make sure that the verification works.
    # For now, only test that verify_client_proof uses padded values.
    my $M1_dummy = 'X' x 64;  # Wrong proof for this test
    my $result = $srp->verify_client_proof($M1_dummy);
    ok(!$result, '[HAP-Pairing §2.6] wrong client proof M1 is rejected');
}

# The public key that M2 carries is padded too. About one B in 256
# is small enough that its natural encoding is 383 bytes. A caller
# that packed the number itself would send a short key for one
# pairing in 256, and both sides would then hash different bytes for
# u. Thus SRP owns the encoding, beside N_LEN.
subtest '[HAP-Pairing §2.4] the M2 public key is padded to N' => sub {
	my $srp = Protocol::HAP::SRP->new( password => '123-45-678' );
	my $salt = $srp->generate_salt();
	$srp->compute_verifier($salt);
	$srp->generate_server_public();

	is( length( $srp->server_public_bytes ),
		384, 'a real B goes out as 384 bytes' );

	# Force a B whose natural encoding is short. This is the one
	# case in 256 that a random run almost never reaches.
	$srp->{B} = Math::BigInt->new(256);
	my $short = $srp->server_public_bytes;
	is( length($short), 384, 'and so does a small B' );
	is( unpack( 'H*', $short ),
		( '00' x 382 ) . '0100',
		'the padding is leading zeros, and the value is last' );

	# The bytes are the same ones that u is computed over
	is( unpack( 'H*', $short ),
		unpack( 'H*', Protocol::HAP::SRP::_bigint_to_bytes( $srp->{B}, 384 ) ),
		'the wire encoding matches the hashed encoding' );

	my $fresh = Protocol::HAP::SRP->new( password => '123-45-678' );
	is( $fresh->server_public_bytes,
		undef, 'no key before generate_server_public' );
};

# Test that the N_len constant matches the padding expectation
{
    # N is 3072 bits = 384 bytes
    my $N_len = length($Protocol::HAP::SRP::N_3072);
    is($N_len, 384,
        '[HAP-Pairing §2.2] N_3072 group prime is 384 bytes (3072 bits)');
}

done_testing();
