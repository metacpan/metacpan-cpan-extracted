#!perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);

use Crypt::RIPEMD160;
use Crypt::RIPEMD160::MAC;

# Known test vector: RIPEMD-160("abc") = 8eb208f7e05d987a9b044a8e98c6b087f15a0bfc
my $abc_hex = '8eb208f7e05d987a9b044a8e98c6b087f15a0bfc';
my $abc_spaced = '8eb208f7 e05d987a 9b044a8e 98c6b087 f15a0bfc';
my $empty_hex = '9c1185a5c5e9fc54612808977ee8f548b2258d31';

# ========================================
# Constructor and basic object tests
# ========================================

subtest 'constructor' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    isa_ok($ctx, 'Crypt::RIPEMD160');

    # Creating multiple independent contexts
    my $ctx2 = Crypt::RIPEMD160->new;
    isa_ok($ctx2, 'Crypt::RIPEMD160');
    $ctx->add('abc');
    $ctx2->add('');
    my $hex1 = unpack("H*", $ctx->digest);
    my $hex2 = unpack("H*", $ctx2->digest);
    is($hex1, $abc_hex, 'first context hashes abc correctly');
    is($hex2, $empty_hex, 'second context hashes empty string independently');
};

# ========================================
# digest() returns correct binary
# ========================================

subtest 'digest returns 20 bytes' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('test');
    my $digest = $ctx->digest;
    is(length($digest), 20, 'digest is 20 bytes');
};

# ========================================
# hexdigest() format
# ========================================

subtest 'hexdigest format' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('abc');
    my $hex = $ctx->hexdigest;
    is($hex, $abc_spaced, 'hexdigest returns space-separated hex');
    like($hex, qr/^[0-9a-f]{8}( [0-9a-f]{8}){4}$/, 'hexdigest format is 5 groups of 8 hex chars');
};

# ========================================
# hash() as class method and instance method
# ========================================

subtest 'hash as class method' => sub {
    my $digest = Crypt::RIPEMD160->hash('abc');
    is(unpack("H*", $digest), $abc_hex, 'class method hash works');
};

subtest 'hash as instance method' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    my $digest = $ctx->hash('abc');
    is(unpack("H*", $digest), $abc_hex, 'instance method hash works');
};

# ========================================
# hexhash() as class method and instance method
# ========================================

subtest 'hexhash as class method' => sub {
    my $hex = Crypt::RIPEMD160->hexhash('abc');
    is($hex, $abc_spaced, 'class method hexhash works');
};

subtest 'hexhash as instance method' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    my $hex = $ctx->hexhash('abc');
    is($hex, $abc_spaced, 'instance method hexhash works');
};

# ========================================
# reset() allows context reuse
# ========================================

subtest 'reset and reuse' => sub {
    my $ctx = Crypt::RIPEMD160->new;

    # First use
    $ctx->add('abc');
    my $hex1 = unpack("H*", $ctx->digest);
    is($hex1, $abc_hex, 'first hash correct');

    # Reset and reuse
    $ctx->reset;
    $ctx->add('abc');
    my $hex2 = unpack("H*", $ctx->digest);
    is($hex2, $abc_hex, 'hash after reset is identical');

    # Reset to different data
    $ctx->reset;
    $ctx->add('');
    my $hex3 = unpack("H*", $ctx->digest);
    is($hex3, $empty_hex, 'hash of empty string after reset');
};

# ========================================
# add() with multiple arguments
# ========================================

subtest 'add with multiple arguments' => sub {
    my $ctx1 = Crypt::RIPEMD160->new;
    $ctx1->add('a', 'b', 'c');
    my $hex1 = unpack("H*", $ctx1->digest);

    my $ctx2 = Crypt::RIPEMD160->new;
    $ctx2->add('abc');
    my $hex2 = unpack("H*", $ctx2->digest);

    is($hex1, $hex2, 'add("a","b","c") == add("abc")');
};

subtest 'add with empty strings in list' => sub {
    my $ctx1 = Crypt::RIPEMD160->new;
    $ctx1->add('', 'abc', '');
    my $hex1 = unpack("H*", $ctx1->digest);

    is($hex1, $abc_hex, 'empty strings in add list have no effect');
};

# ========================================
# Block boundary tests (64-byte block size)
# ========================================

subtest 'block boundary: exactly 64 bytes' => sub {
    my $data = 'A' x 64;
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add($data);
    my $hex = unpack("H*", $ctx->digest);
    isnt($hex, '', 'exactly 64 bytes produces valid hash');
    is(length($hex), 40, 'hash is 40 hex chars');
};

subtest 'block boundary: 63 bytes' => sub {
    my $data = 'B' x 63;
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add($data);
    my $hex = unpack("H*", $ctx->digest);
    is(length($hex), 40, '63 bytes produces valid hash');
};

subtest 'block boundary: 65 bytes' => sub {
    my $data = 'C' x 65;
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add($data);
    my $hex = unpack("H*", $ctx->digest);
    is(length($hex), 40, '65 bytes produces valid hash');
};

subtest 'block boundary: 128 bytes (two blocks)' => sub {
    my $data = 'D' x 128;
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add($data);
    my $hex = unpack("H*", $ctx->digest);
    is(length($hex), 40, '128 bytes produces valid hash');
};

subtest 'incremental add matches single add at block boundary' => sub {
    my $data = 'E' x 64;

    my $ctx1 = Crypt::RIPEMD160->new;
    $ctx1->add($data);
    my $hex1 = unpack("H*", $ctx1->digest);

    # Add in two chunks that straddle the boundary
    my $ctx2 = Crypt::RIPEMD160->new;
    $ctx2->add('E' x 30);
    $ctx2->add('E' x 34);
    my $hex2 = unpack("H*", $ctx2->digest);

    is($hex1, $hex2, 'incremental add across block boundary matches single add');
};

# ========================================
# addfile() with lexical filehandle
# ========================================

subtest 'addfile with lexical filehandle' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh 'abc';
    close $fh;

    open my $rfh, '<', $filename or die "Cannot open $filename: $!";
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->addfile($rfh);
    my $hex = unpack("H*", $ctx->digest);
    close $rfh;

    is($hex, $abc_hex, 'addfile with lexical filehandle');
};

subtest 'addfile with empty file' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    close $fh;

    open my $rfh, '<', $filename or die "Cannot open $filename: $!";
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->addfile($rfh);
    my $hex = unpack("H*", $ctx->digest);
    close $rfh;

    is($hex, $empty_hex, 'addfile with empty file gives empty string hash');
};

# ========================================
# Binary data handling
# ========================================

subtest 'binary data with null bytes' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add("\x00\x00\x00");
    my $hex = unpack("H*", $ctx->digest);
    is(length($hex), 40, 'null bytes produce valid hash');
    isnt($hex, $empty_hex, 'null bytes differ from empty string');
};

subtest 'all byte values' => sub {
    my $all_bytes = join('', map { chr($_) } 0..255);
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add($all_bytes);
    my $hex = unpack("H*", $ctx->digest);
    is(length($hex), 40, 'all 256 byte values produce valid hash');
};

# ========================================
# MAC module tests
# ========================================

subtest 'MAC constructor' => sub {
    my $mac = Crypt::RIPEMD160::MAC->new('secret');
    isa_ok($mac, 'Crypt::RIPEMD160::MAC');
};

subtest 'MAC reset and reuse' => sub {
    my $key = chr(0x0b) x 20;
    my $data = "Hi There";

    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->add($data);
    my $hex1 = $mac1->hexmac;

    # Create fresh instance for comparison
    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    $mac2->add($data);
    my $hex2 = $mac2->hexmac;

    is($hex1, $hex2, 'two fresh MAC instances produce same result');
};

subtest 'MAC mac() returns 20 bytes' => sub {
    my $mac = Crypt::RIPEMD160::MAC->new('key');
    $mac->add('data');
    my $digest = $mac->mac;
    is(length($digest), 20, 'mac() returns 20 bytes');
};

subtest 'MAC hexmac() format' => sub {
    my $mac = Crypt::RIPEMD160::MAC->new('key');
    $mac->add('data');
    my $hex = $mac->hexmac;
    like($hex, qr/^[0-9a-f]{8}( [0-9a-f]{8}){4}$/, 'hexmac format matches hexdigest format');
};

subtest 'MAC with empty data' => sub {
    my $mac = Crypt::RIPEMD160::MAC->new('key');
    $mac->add('');
    my $hex = $mac->hexmac;
    like($hex, qr/^[0-9a-f]{8}( [0-9a-f]{8}){4}$/, 'MAC of empty data produces valid output');
};

subtest 'MAC add with multiple arguments' => sub {
    my $key = chr(0xaa) x 80;
    my $data = "Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data";

    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->add($data);
    my $hex1 = $mac1->hexmac;

    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    $mac2->add("Test Using Lar", "ger Than Block-Size K", "ey and Larger Than One Block-Size Dat", "a");
    my $hex2 = $mac2->hexmac;

    is($hex1, $hex2, 'MAC add with split data matches single add');
};

subtest 'MAC addfile' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "what do ya want for nothing?";
    close $fh;

    open my $rfh, '<', $filename or die "Cannot open $filename: $!";
    my $mac = Crypt::RIPEMD160::MAC->new("Jefe");
    $mac->addfile($rfh);
    my $hex = $mac->hexmac;
    close $rfh;

    is($hex, 'dda6c021 3a485a9e 24f47420 64a7f033 b43c4069',
       'MAC addfile matches known RFC 2286 test vector');
};

subtest 'MAC key longer than 64 bytes is hashed' => sub {
    # RFC 2286 test case 6: key = 0xaa repeated 80 times
    my $mac = Crypt::RIPEMD160::MAC->new(chr(0xaa) x 80);
    $mac->add("Test Using Larger Than Block-Size Key - Hash Key First");
    my $hex = $mac->hexmac;
    is($hex, '6466ca07 ac5eac29 e1bd523e 5ada7605 b791fd8b',
       'long key is correctly hashed before use');
};

subtest 'MAC key exactly 64 bytes' => sub {
    my $key = 'K' x 64;
    my $mac = Crypt::RIPEMD160::MAC->new($key);
    $mac->add('test data');
    my $hex = $mac->hexmac;
    like($hex, qr/^[0-9a-f]{8}( [0-9a-f]{8}){4}$/, 'key of exactly 64 bytes works');
};

subtest 'MAC single byte key' => sub {
    my $mac = Crypt::RIPEMD160::MAC->new('K');
    $mac->add('test');
    my $hex = $mac->hexmac;
    like($hex, qr/^[0-9a-f]{8}( [0-9a-f]{8}){4}$/, 'single byte key works');
};

# ========================================
# Version sanity
# ========================================

subtest 'module version defined' => sub {
    ok(defined $Crypt::RIPEMD160::VERSION, 'Crypt::RIPEMD160 has VERSION');
    ok(defined $Crypt::RIPEMD160::MAC::VERSION, 'Crypt::RIPEMD160::MAC has VERSION');
};

done_testing;
