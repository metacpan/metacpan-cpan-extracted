#!/usr/bin/env perl
use v5.36;
use Test::More;

# Test TLV encoding/decoding
use_ok('Protocol::HAP::TLV');

# Test basic encoding with ordered pairs (new interface)
{
    my $encoded = Protocol::HAP::TLV::encode(
        0x06, pack('C', 1),  # State = 1
        0x00, pack('C', 0),  # Method = 0
    );

    ok(defined $encoded, 'TLV encoding returns data');
    is(length($encoded), 6, 'TLV encoding has correct length');

    # Test decoding
    my %decoded = Protocol::HAP::TLV::decode($encoded);
    is_deeply(\%decoded, {
        0x06 => pack('C', 1),
        0x00 => pack('C', 0),
    }, 'TLV decoding matches original');
}

# Test TLV order preservation
{
    # Encode with a specific order: State before PublicKey before
    # Salt. Use values that do not conflict with the type bytes.
    my $encoded = Protocol::HAP::TLV::encode(
        0x06, pack('C', 0xAA),       # State = 0xAA (unique)
        0x03, 'public_key_data',     # PublicKey
        0x02, 'salt_data_here',      # Salt
    );

    # Check the TLV header positions to make sure the encoder keeps
    # the order. Look for type-length pairs to find the start of
    # each TLV item.
    my $state_pos = index($encoded, pack('CC', 0x06, 1));   # Type 0x06, length 1
    my $pubkey_pos = index($encoded, pack('CC', 0x03, 15)); # Type 0x03, length 15
    my $salt_pos = index($encoded, pack('CC', 0x02, 14));   # Type 0x02, length 14

    ok($state_pos >= 0, 'State TLV found');
    ok($pubkey_pos >= 0, 'PublicKey TLV found');
    ok($salt_pos >= 0, 'Salt TLV found');
    ok($state_pos < $pubkey_pos, 'State comes before PublicKey');
    ok($pubkey_pos < $salt_pos, 'PublicKey comes before Salt');
}

# Test with longer values (chunking)
{
    my $long_value = 'x' x 300;
    my $encoded_long = Protocol::HAP::TLV::encode(
        0x01, $long_value,
    );

    ok(length($encoded_long) > 300, 'Long value is encoded with chunks');

    my %decoded_long = Protocol::HAP::TLV::decode($encoded_long);
    is($decoded_long{0x01}, $long_value, 'Long value decoded correctly');
}

# Test separator encoding (for List Pairings)
{
    my $sep = Protocol::HAP::TLV::encode(0xFF, '');
    is(length($sep), 2, 'Separator is 2 bytes');
    my ($type, $len) = unpack('CC', $sep);
    is($type, 0xFF, 'Separator type is 0xFF');
    is($len, 0, 'Separator length is 0');
}

# Test empty value encoding
{
    my $encoded = Protocol::HAP::TLV::encode(
        0xFF, '',  # Separator (empty value)
    );
    is(length($encoded), 2, 'Empty value encodes to 2 bytes');
    my ($type, $len) = unpack('CC', $encoded);
    is($type, 0xFF, 'Empty value type preserved');
    is($len, 0, 'Empty value length is 0');
}

# Test multiple items with same type (for List Pairings response)
{
    my $encoded = Protocol::HAP::TLV::encode(
        0x06, pack('C', 2),     # State
        0x01, 'controller-1',   # Identifier 1
        0x03, 'pubkey-1',       # PublicKey 1
        0x0B, pack('C', 1),     # Permissions 1
        0xFF, '',               # Separator
        0x01, 'controller-2',   # Identifier 2
        0x03, 'pubkey-2',       # PublicKey 2
        0x0B, pack('C', 0),     # Permissions 2
    );

    ok(length($encoded) > 0, 'Multiple pairing entries encoded');

    # Make sure the separator is in the encoded data
    my $sep_found = 0;
    my $pos = 0;
    while ($pos < length($encoded)) {
        my ($type, $len) = unpack('CC', substr($encoded, $pos, 2));
        if ($type == 0xFF && $len == 0) {
            $sep_found = 1;
            last;
        }
        $pos += 2 + $len;
    }
    ok($sep_found, 'Separator found in encoded data');
}

done_testing();
