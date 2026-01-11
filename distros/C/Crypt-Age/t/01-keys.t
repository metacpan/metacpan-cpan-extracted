#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Crypt::Age::Keys;

# Test keypair generation
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;

    ok(defined $public, 'public key generated');
    ok(defined $secret, 'secret key generated');

    like($public, qr/^age1[a-z0-9]+$/, 'public key has correct format');
    like($secret, qr/^AGE-SECRET-KEY-1[A-Z0-9]+$/, 'secret key has correct format');

    # Keys should be deterministic length
    is(length($public), 62, 'public key has correct length');
    is(length($secret), 74, 'secret key has correct length');
}

# Test public key encoding/decoding roundtrip
{
    my $raw_key = "\x00" x 32;  # 32 zero bytes
    my $encoded = Crypt::Age::Keys->encode_public_key($raw_key);
    my $decoded = Crypt::Age::Keys->decode_public_key($encoded);

    is($decoded, $raw_key, 'public key roundtrip');
}

# Test secret key encoding/decoding roundtrip
{
    my $raw_key = "\xff" x 32;  # 32 0xff bytes
    my $encoded = Crypt::Age::Keys->encode_secret_key($raw_key);
    my $decoded = Crypt::Age::Keys->decode_secret_key($encoded);

    is($decoded, $raw_key, 'secret key roundtrip');
}

# Test public_key_from_secret
{
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair;
    my $derived_public = Crypt::Age::Keys->public_key_from_secret($secret);

    is($derived_public, $public, 'public key derived from secret matches');
}

# Test error handling
{
    eval { Crypt::Age::Keys->encode_public_key("short") };
    like($@, qr/must be 32 bytes/, 'rejects short public key');

    eval { Crypt::Age::Keys->decode_public_key("invalid") };
    like($@, qr/Invalid bech32/, 'rejects invalid bech32');
}

# Test Bech32 with known test vectors
{
    # These are test vectors from BIP-173
    my $encoded = Crypt::Age::Keys->bech32_encode('a', '');
    is($encoded, 'a12uel5l', 'bech32 empty data');

    # Test decoding
    my ($hrp, $data) = Crypt::Age::Keys->bech32_decode('a12uel5l');
    is($hrp, 'a', 'bech32 decode hrp');
    is($data, '', 'bech32 decode empty data');
}

done_testing;
