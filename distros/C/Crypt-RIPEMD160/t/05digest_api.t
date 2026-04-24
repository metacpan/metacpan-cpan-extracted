#!perl

use strict;
use warnings;

use Test::More;
use Crypt::RIPEMD160;

# Known test vector: RIPEMD-160("abc") = 8eb208f7e05d987a9b044a8e98c6b087f15a0bfc
my $abc_digest = pack("H*", '8eb208f7e05d987a9b044a8e98c6b087f15a0bfc');
my $abc_hex    = '8eb208f7e05d987a9b044a8e98c6b087f15a0bfc';

# ========================================
# Digest::base inheritance
# ========================================

subtest 'isa Digest::base' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    isa_ok($ctx, 'Digest::base');
};

# ========================================
# b64digest (provided by Digest::base)
# ========================================

subtest 'b64digest' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('abc');
    my $b64 = $ctx->b64digest;
    ok(defined $b64, 'b64digest returns a value');

    # Verify by encoding the known digest
    require MIME::Base64;
    my $expected = MIME::Base64::encode($abc_digest, '');
    $expected =~ s/=+$//;
    is($b64, $expected, 'b64digest matches expected base64 of digest');
};

# ========================================
# base64_padded_digest (provided by Digest::base)
# ========================================

subtest 'base64_padded_digest' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    plan skip_all => 'base64_padded_digest not available in this Digest::base'
        unless $ctx->can('base64_padded_digest');
    $ctx->add('abc');
    my $b64 = $ctx->base64_padded_digest;
    ok(defined $b64, 'base64_padded_digest returns a value');

    require MIME::Base64;
    my $expected = MIME::Base64::encode($abc_digest, '');
    is($b64, $expected, 'base64_padded_digest includes padding');
};

# ========================================
# add_bits (provided by Digest::base)
# ========================================

subtest 'add_bits with bit string' => sub {
    # "abc" in binary = 01100001 01100010 01100011
    my $bits = '011000010110001001100011';

    my $ctx = Crypt::RIPEMD160->new;
    plan skip_all => 'add_bits not available in this Digest::base'
        unless $ctx->can('add_bits');
    $ctx->add_bits($bits);
    my $hex = unpack("H*", $ctx->digest);
    is($hex, $abc_hex, 'add_bits with binary string matches add("abc")');
};

subtest 'add_bits with raw bytes and count' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    plan skip_all => 'add_bits not available in this Digest::base'
        unless $ctx->can('add_bits');
    $ctx->add_bits("abc", 24);  # 3 bytes = 24 bits
    my $hex = unpack("H*", $ctx->digest);
    is($hex, $abc_hex, 'add_bits with bytes+count matches add("abc")');
};

subtest 'add_bits rejects non-byte-aligned' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    plan skip_all => 'add_bits not available in this Digest::base'
        unless $ctx->can('add_bits');
    eval { $ctx->add_bits('01100001011', 11) };
    like($@, qr/multiple of 8/i, 'add_bits croaks on non-byte-aligned input');
};

# ========================================
# Digest->new() interoperability
# ========================================

subtest 'Digest->new("RIPEMD-160")' => sub {
    eval { require Digest };
    plan skip_all => 'Digest module not available' if $@;

    my $ctx = eval { Digest->new('RIPEMD-160') };
    plan skip_all => "Digest->new('RIPEMD-160') not supported: $@" if $@;
    isa_ok($ctx, 'Crypt::RIPEMD160');
    $ctx->add('abc');
    my $hex = unpack("H*", $ctx->digest);
    is($hex, $abc_hex, 'Digest->new("RIPEMD-160") produces correct hash');
};

subtest 'Digest->new("RIPEMD-160") has b64digest' => sub {
    eval { require Digest };
    plan skip_all => 'Digest module not available' if $@;

    my $ctx = eval { Digest->new('RIPEMD-160') };
    plan skip_all => "Digest->new('RIPEMD-160') not supported: $@" if $@;
    $ctx->add('abc');
    my $b64 = $ctx->b64digest;
    ok(defined $b64, 'b64digest available via Digest->new');
    ok(length($b64) > 0, 'b64digest is non-empty');
};

# ========================================
# Existing methods still work correctly
# ========================================

subtest 'hexdigest format preserved' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('abc');
    my $hex = $ctx->hexdigest;
    like($hex, qr/^[0-9a-f]{8}( [0-9a-f]{8}){4}$/,
         'hexdigest retains space-separated format');
};

subtest 'hash class method works' => sub {
    my $digest = Crypt::RIPEMD160->hash('abc');
    is(unpack("H*", $digest), $abc_hex, 'hash() unaffected by inheritance');
};

subtest 'clone still works' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('ab');
    my $clone = $ctx->clone;
    $clone->add('c');
    is(unpack("H*", $clone->digest), $abc_hex, 'clone works with Digest::base');
};

subtest 'reset still works' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('garbage');
    $ctx->reset;
    $ctx->add('abc');
    is(unpack("H*", $ctx->digest), $abc_hex, 'XS reset overrides Digest::base reset');
};

done_testing;
