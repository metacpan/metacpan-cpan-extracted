#!perl

# Streaming consistency tests for RIPEMD160_update buffering logic.
#
# The RIPEMD-160 hash of a message must be identical regardless of how
# the message is split across add() calls.  These tests feed the same
# data in every possible chunk pattern (single split, two-way split,
# byte-at-a-time) to verify that the internal buffering in
# RIPEMD160_update correctly handles partial blocks, block boundaries,
# and multi-block inputs.

use strict;
use warnings;

use Test::More;
use Crypt::RIPEMD160;
use Crypt::RIPEMD160::MAC;

# ========================================
# Helper: hash a string as one add() call
# ========================================

sub reference_hash {
    my ($data) = @_;
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add($data);
    return unpack("H*", $ctx->digest);
}

# ========================================
# Every single split point (0..len)
# ========================================

subtest 'single split: 100-byte message at every offset' => sub {
    # 100 bytes covers: partial block (<64), exact block (64),
    # block + partial (65..99), and the padding boundary (55/56).
    my $msg = join('', map { chr($_ & 0xFF) } 0..99);
    my $expected = reference_hash($msg);

    for my $split (0 .. length($msg)) {
        my $left  = substr($msg, 0, $split);
        my $right = substr($msg, $split);

        my $ctx = Crypt::RIPEMD160->new;
        $ctx->add($left);
        $ctx->add($right);
        my $hex = unpack("H*", $ctx->digest);

        is($hex, $expected, "split at offset $split")
            or diag("left=" . length($left) . " right=" . length($right));
    }
};

# ========================================
# Every split on a block-aligned message
# ========================================

subtest 'single split: 128-byte (2 blocks) at every offset' => sub {
    my $msg = 'Q' x 128;
    my $expected = reference_hash($msg);

    for my $split (0 .. length($msg)) {
        my $ctx = Crypt::RIPEMD160->new;
        $ctx->add(substr($msg, 0, $split));
        $ctx->add(substr($msg, $split));
        my $hex = unpack("H*", $ctx->digest);

        is($hex, $expected, "split at offset $split");
    }
};

# ========================================
# Byte-at-a-time feeding
# ========================================

subtest 'byte-at-a-time: 130 bytes' => sub {
    # 130 bytes = 2 full blocks + 2 bytes partial
    my $msg = join('', map { chr(($_ * 7) & 0xFF) } 0..129);
    my $expected = reference_hash($msg);

    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add(substr($msg, $_, 1)) for 0 .. length($msg) - 1;
    my $hex = unpack("H*", $ctx->digest);

    is($hex, $expected, 'byte-at-a-time matches single add');
};

# ========================================
# Two-way split at key offsets
# ========================================

subtest 'two-way split at block boundaries' => sub {
    # 200 bytes = 3 full blocks + 8 bytes partial
    my $msg = 'R' x 200;
    my $expected = reference_hash($msg);

    # Key offsets: 0, 1, 55, 56, 63, 64, 65, 127, 128, 129, 191, 192, 199, 200
    my @key_offsets = (0, 1, 55, 56, 63, 64, 65, 127, 128, 129, 191, 192, 199, 200);

    for my $i (@key_offsets) {
        for my $j (@key_offsets) {
            next if $j < $i;
            next if $j > length($msg) || $i > length($msg);

            my $ctx = Crypt::RIPEMD160->new;
            $ctx->add(substr($msg, 0, $i));
            $ctx->add(substr($msg, $i, $j - $i));
            $ctx->add(substr($msg, $j));
            my $hex = unpack("H*", $ctx->digest);

            is($hex, $expected, "three-way split at $i/$j");
        }
    }
};

# ========================================
# Padding boundary stress: 55 and 56 bytes
# ========================================

subtest 'padding boundary: 55 bytes in every chunk pattern' => sub {
    my $msg = 'P' x 55;
    my $expected = reference_hash($msg);

    # Feed in chunks of 1..55
    for my $chunk_size (1 .. 55) {
        my $ctx = Crypt::RIPEMD160->new;
        my $offset = 0;
        while ($offset < length($msg)) {
            my $end = $offset + $chunk_size;
            $end = length($msg) if $end > length($msg);
            $ctx->add(substr($msg, $offset, $end - $offset));
            $offset = $end;
        }
        my $hex = unpack("H*", $ctx->digest);
        is($hex, $expected, "55 bytes in chunks of $chunk_size");
    }
};

subtest 'padding boundary: 56 bytes in every chunk pattern' => sub {
    my $msg = 'P' x 56;
    my $expected = reference_hash($msg);

    for my $chunk_size (1 .. 56) {
        my $ctx = Crypt::RIPEMD160->new;
        my $offset = 0;
        while ($offset < length($msg)) {
            my $end = $offset + $chunk_size;
            $end = length($msg) if $end > length($msg);
            $ctx->add(substr($msg, $offset, $end - $offset));
            $offset = $end;
        }
        my $hex = unpack("H*", $ctx->digest);
        is($hex, $expected, "56 bytes in chunks of $chunk_size");
    }
};

# ========================================
# Multi-argument add() streaming
# ========================================

subtest 'multi-arg add matches sequential add' => sub {
    my $msg = 'X' x 200;
    my $expected = reference_hash($msg);

    # Split into 7 pieces at irregular intervals
    my @pieces = map { substr($msg, $_ * 29, 29) } 0..5;
    push @pieces, substr($msg, 174);  # remaining 26 bytes

    # Verify pieces reconstruct the message
    is(join('', @pieces), $msg, 'pieces reconstruct message');

    # All at once via multi-arg add
    my $ctx1 = Crypt::RIPEMD160->new;
    $ctx1->add(@pieces);
    my $hex1 = unpack("H*", $ctx1->digest);

    # Sequential add calls
    my $ctx2 = Crypt::RIPEMD160->new;
    $ctx2->add($_) for @pieces;
    my $hex2 = unpack("H*", $ctx2->digest);

    is($hex1, $expected, 'multi-arg add produces correct hash');
    is($hex2, $expected, 'sequential add produces correct hash');
};

# ========================================
# MAC streaming consistency
# ========================================

subtest 'MAC streaming: same data different chunk sizes' => sub {
    my $key  = chr(0x0b) x 20;
    my $data = "Hi There" x 10;  # 80 bytes, crosses block boundary

    # Reference: single add
    my $mac_ref = Crypt::RIPEMD160::MAC->new($key);
    $mac_ref->add($data);
    my $expected = $mac_ref->hexmac;

    # Byte-at-a-time
    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->add(substr($data, $_, 1)) for 0 .. length($data) - 1;
    is($mac1->hexmac, $expected, 'MAC byte-at-a-time matches');

    # Chunks of 13 (prime, misaligns with block size)
    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    my $offset = 0;
    while ($offset < length($data)) {
        my $end = $offset + 13;
        $end = length($data) if $end > length($data);
        $mac2->add(substr($data, $offset, $end - $offset));
        $offset = $end;
    }
    is($mac2->hexmac, $expected, 'MAC chunks of 13 matches');

    # Split at block boundary (64 bytes)
    my $mac3 = Crypt::RIPEMD160::MAC->new($key);
    $mac3->add(substr($data, 0, 64));
    $mac3->add(substr($data, 64));
    is($mac3->hexmac, $expected, 'MAC split at block boundary matches');
};

# ========================================
# Clone mid-stream preserves consistency
# ========================================

subtest 'clone mid-stream then diverge' => sub {
    my $prefix = 'A' x 70;  # crosses one block boundary
    my $suffix_a = 'B' x 50;
    my $suffix_b = 'C' x 50;

    my $expected_a = reference_hash($prefix . $suffix_a);
    my $expected_b = reference_hash($prefix . $suffix_b);

    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add($prefix);

    my $clone = $ctx->clone;

    $ctx->add($suffix_a);
    $clone->add($suffix_b);

    is(unpack("H*", $ctx->digest), $expected_a, 'original path correct');
    is(unpack("H*", $clone->digest), $expected_b, 'cloned path correct');
};

subtest 'clone at every offset of a message' => sub {
    my $msg = join('', map { chr($_ & 0xFF) } 0..99);
    my $expected = reference_hash($msg);

    for my $split (0, 1, 31, 32, 33, 55, 56, 63, 64, 65, 99) {
        my $ctx = Crypt::RIPEMD160->new;
        $ctx->add(substr($msg, 0, $split));
        my $clone = $ctx->clone;
        $clone->add(substr($msg, $split));
        my $hex = unpack("H*", $clone->digest);
        is($hex, $expected, "clone at offset $split then complete");
    }
};

done_testing;
