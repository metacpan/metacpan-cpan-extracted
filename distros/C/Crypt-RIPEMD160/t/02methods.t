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

subtest 'MAC reset after mac() preserves key' => sub {
    # mac() and hexmac() finalize the inner hash, but reset() must still
    # reconstruct the correct HMAC state from the preserved key.
    my $key = "secret key";
    my $data = "test data";

    my $mac = Crypt::RIPEMD160::MAC->new($key);
    $mac->add($data);
    my $hex1 = $mac->hexmac;

    # reset() after hexmac() should allow correct reuse
    $mac->reset();
    $mac->add($data);
    my $hex2 = $mac->hexmac;

    # Fresh instance as ground truth
    my $fresh = Crypt::RIPEMD160::MAC->new($key);
    $fresh->add($data);
    my $hex3 = $fresh->hexmac;

    is($hex1, $hex3, 'first mac matches fresh instance');
    is($hex2, $hex3, 'mac after reset matches fresh instance');
};

subtest 'MAC reset after mac() with long key' => sub {
    # Keys > 64 bytes are hashed before use; reset must handle this too
    my $key = chr(0xaa) x 80;
    my $data = "Test Using Larger Than Block-Size Key - Hash Key First";

    my $mac = Crypt::RIPEMD160::MAC->new($key);
    $mac->add($data);
    my $hex1 = $mac->hexmac;

    $mac->reset();
    $mac->add($data);
    my $hex2 = $mac->hexmac;

    is($hex1, '6466ca07 ac5eac29 e1bd523e 5ada7605 b791fd8b',
       'first mac matches RFC 2286 vector');
    is($hex2, $hex1, 'mac after reset matches first mac');
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
# clone() tests
# ========================================

subtest 'clone produces independent copy' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('abc');
    my $clone = $ctx->clone;
    isa_ok($clone, 'Crypt::RIPEMD160');

    # Both should produce the same digest
    my $hex_orig  = unpack("H*", $ctx->digest);
    my $hex_clone = unpack("H*", $clone->digest);
    is($hex_orig, $abc_hex, 'original produces correct hash');
    is($hex_clone, $abc_hex, 'clone produces same hash');
};

subtest 'clone is independent after diverging' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('abc');

    my $clone = $ctx->clone;
    $clone->add('def');  # diverge from original

    my $hex_orig = unpack("H*", $ctx->digest);
    my $hex_clone = unpack("H*", $clone->digest);

    is($hex_orig, $abc_hex, 'original unaffected by clone addition');
    isnt($hex_clone, $abc_hex, 'clone diverged after additional data');

    # Verify clone matches "abcdef" hash
    my $expected = Crypt::RIPEMD160->new;
    $expected->add('abcdef');
    my $hex_expected = unpack("H*", $expected->digest);
    is($hex_clone, $hex_expected, 'clone matches "abcdef" hash');
};

subtest 'clone at block boundary' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('X' x 64);  # exactly one block

    my $clone = $ctx->clone;
    $ctx->add('Y');
    $clone->add('Z');

    my $hex1 = unpack("H*", $ctx->digest);
    my $hex2 = unpack("H*", $clone->digest);

    isnt($hex1, $hex2, 'clone diverges at block boundary');
};

subtest 'clone of fresh context' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    my $clone = $ctx->clone;
    $clone->add('abc');

    my $hex_orig  = unpack("H*", $ctx->digest);
    my $hex_clone = unpack("H*", $clone->digest);

    is($hex_orig, $empty_hex, 'original stays empty');
    is($hex_clone, $abc_hex, 'clone of fresh context works');
};

# ========================================
# addfile() read error handling
# ========================================

subtest 'addfile croaks on read error' => sub {
    # Tied handle that simulates a read() failure (returns undef, sets $!)
    {
        package ReadErrorHandle;
        sub TIEHANDLE { bless {}, shift }
        sub BINMODE { 1 }
        sub READ { $! = 5; return undef }  # EIO
    }
    tie *ERR_FH, 'ReadErrorHandle';

    my $ctx = Crypt::RIPEMD160->new;
    eval { $ctx->addfile(\*ERR_FH) };
    like($@, qr/read failed/i, 'RIPEMD160 addfile croaks on read error');
    untie *ERR_FH;
};

subtest 'MAC addfile croaks on read error' => sub {
    {
        package ReadErrorHandle2;
        sub TIEHANDLE { bless {}, shift }
        sub BINMODE { 1 }
        sub READ { $! = 5; return undef }
    }
    tie *ERR_FH2, 'ReadErrorHandle2';

    my $mac = Crypt::RIPEMD160::MAC->new("key");
    eval { $mac->addfile(\*ERR_FH2) };
    like($@, qr/read failed/i, 'MAC addfile croaks on read error');
    untie *ERR_FH2;
};

# ========================================
# Padding boundary tests (55/56/57 bytes)
# ========================================
# RIPEMD-160 padding appends 0x80 + 64-bit length (9 bytes minimum).
# If (message_length mod 64) > 55, padding overflows into a second
# compression block.  These tests exercise both sides of that boundary.

subtest 'padding boundary: 55 bytes (fits in one block)' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('A' x 55);
    is(unpack("H*", $ctx->digest),
       'c4cf09138ab0b859b70c321375557430649190b4',
       '55 bytes: padding fits in one block');
};

subtest 'padding boundary: 56 bytes (spills to second block)' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('A' x 56);
    is(unpack("H*", $ctx->digest),
       '6da64c99dd269139248fa73adfb40e19b8722196',
       '56 bytes: padding requires second compression block');
};

subtest 'padding boundary: 57 bytes' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('A' x 57);
    is(unpack("H*", $ctx->digest),
       '017d4d1b03c32d833b31df97148b43c0130bd295',
       '57 bytes: one past the padding boundary');
};

# Same boundary at 119/120 bytes (second block pair)
subtest 'padding boundary: 119 bytes (55 mod 64, fits in block)' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('A' x 119);
    is(unpack("H*", $ctx->digest),
       'a0dcfad464c8cee6ea3137a640a90498e80db360',
       '119 bytes: multi-block, padding fits');
};

subtest 'padding boundary: 120 bytes (56 mod 64, spills)' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('A' x 120);
    is(unpack("H*", $ctx->digest),
       '2c62c467efc39f9c6b73394ef63abf3c89aa0f96',
       '120 bytes: multi-block, padding spills');
};

subtest 'padding boundary: incremental add across boundary' => sub {
    # Feed 56 bytes one at a time — exercises the partial-block
    # accumulation path in RIPEMD160_update plus the padding overflow
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('A') for 1..56;
    is(unpack("H*", $ctx->digest),
       '6da64c99dd269139248fa73adfb40e19b8722196',
       '56 bytes fed incrementally matches single-add vector');
};

# ========================================
# Method return values ($self for chaining)
# ========================================

subtest 'add returns self for chaining' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    my $ret = $ctx->add('abc');
    is($ret, $ctx, 'add() returns the context object');
};

subtest 'reset returns self for chaining' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('junk');
    my $ret = $ctx->reset;
    is($ret, $ctx, 'reset() returns the context object');
};

subtest 'chained add produces correct hash' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('a')->add('b')->add('c');
    is(unpack("H*", $ctx->digest), $abc_hex, 'chained add("a")->add("b")->add("c") works');
};

subtest 'chained reset then add' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    $ctx->add('junk');
    $ctx->digest;
    $ctx->reset->add('abc');
    is(unpack("H*", $ctx->digest), $abc_hex, 'reset->add chain works');
};

subtest 'addfile returns $self for chaining' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh 'abc';
    close $fh;

    open my $rfh, '<', $filename or die "Cannot open $filename: $!";
    my $ctx = Crypt::RIPEMD160->new;
    my $ret = $ctx->addfile($rfh);
    close $rfh;

    is($ret, $ctx, 'addfile returns the context object');
};

subtest 'MAC add returns $self for chaining' => sub {
    my $mac = Crypt::RIPEMD160::MAC->new('secret');
    my $ret = $mac->add('data');
    is($ret, $mac, 'MAC add returns the MAC object');
};

subtest 'MAC add chaining produces correct result' => sub {
    my $key = "Jefe";
    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->add("what do ya ");
    $mac1->add("want for nothing?");
    my $hex1 = $mac1->hexmac;

    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    $mac2->add("what do ya ")->add("want for nothing?");
    my $hex2 = $mac2->hexmac;

    is($hex1, $hex2, 'chained MAC add produces same result as sequential');
    is($hex1, 'dda6c021 3a485a9e 24f47420 64a7f033 b43c4069',
       'chained result matches RFC 2286 vector');
};

subtest 'MAC addfile returns $self for chaining' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh 'data';
    close $fh;

    open my $rfh, '<', $filename or die "Cannot open $filename: $!";
    my $mac = Crypt::RIPEMD160::MAC->new('key');
    my $ret = $mac->addfile($rfh);
    close $rfh;

    is($ret, $mac, 'MAC addfile returns the MAC object');
};

# ========================================
# Version sanity
# ========================================

subtest 'module version defined' => sub {
    ok(defined $Crypt::RIPEMD160::VERSION, 'Crypt::RIPEMD160 has VERSION');
    ok(defined $Crypt::RIPEMD160::MAC::VERSION, 'Crypt::RIPEMD160::MAC has VERSION');
};

# ========================================
# MAC DESTROY zeroes key material
# ========================================

subtest 'MAC DESTROY zeroes key material' => sub {
    my $key = "super secret key";
    my $mac = Crypt::RIPEMD160::MAC->new($key);
    $mac->add("data");

    # Grab refs to the internal scalars before DESTROY
    my $key_ref   = \$mac->{'key'};
    my $ipad_ref  = \$mac->{'k_ipad'};
    my $opad_ref  = \$mac->{'k_opad'};

    # Explicitly destroy
    $mac->DESTROY;

    is($$key_ref, '', 'key zeroed after DESTROY');
    is($$ipad_ref, '', 'k_ipad zeroed after DESTROY');
    is($$opad_ref, '', 'k_opad zeroed after DESTROY');
};

done_testing;
