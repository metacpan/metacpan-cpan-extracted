#!perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);

use Crypt::RIPEMD160;
use Crypt::RIPEMD160::MAC;

# --- Constructor ---

{
    my $mac = Crypt::RIPEMD160::MAC->new("secret");
    isa_ok($mac, 'Crypt::RIPEMD160::MAC', 'constructor returns blessed object');
}

# --- Empty message ---

{
    my $mac = Crypt::RIPEMD160::MAC->new("key");
    my $digest = $mac->mac();
    is(length($digest), 20, 'mac() on empty message returns 20 bytes');

    $mac = Crypt::RIPEMD160::MAC->new("key");
    my $hex = $mac->hexmac();
    like($hex, qr/^[0-9a-f]{8}(?: [0-9a-f]{8}){4}$/, 'hexmac() format: 5 groups of 8 hex chars');
}

# --- mac() and hexmac() consistency ---

{
    my $key  = "test-consistency";
    my $data = "some data to hash";

    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->add($data);
    my $binary = $mac1->mac();

    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    $mac2->add($data);
    my $hex = $mac2->hexmac();

    # hexmac is the hex of mac with spaces
    my $expected_hex = unpack("H*", $binary);
    $expected_hex = join(" ", $expected_hex =~ /(.{8})/g);
    is($hex, $expected_hex, 'hexmac() matches formatted hex of mac()');
}

# --- Determinism: same key+data = same MAC ---

{
    my $key  = "determinism";
    my $data = "identical input";

    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->add($data);
    my $d1 = $mac1->mac();

    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    $mac2->add($data);
    my $d2 = $mac2->mac();

    is($d1, $d2, 'same key + data produces identical MAC');
}

# --- Different keys produce different MACs ---

{
    my $data = "same data";

    my $mac1 = Crypt::RIPEMD160::MAC->new("key-alpha");
    $mac1->add($data);
    my $d1 = $mac1->mac();

    my $mac2 = Crypt::RIPEMD160::MAC->new("key-beta");
    $mac2->add($data);
    my $d2 = $mac2->mac();

    isnt($d1, $d2, 'different keys produce different MACs');
}

# --- Different data produces different MACs ---

{
    my $key = "same-key";

    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->add("data one");
    my $d1 = $mac1->mac();

    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    $mac2->add("data two");
    my $d2 = $mac2->mac();

    isnt($d1, $d2, 'different data produces different MACs');
}

# --- Multiple add() calls equivalent to single add() ---

{
    my $key = "chunking-test";

    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->add("hello world foo bar");
    my $d1 = $mac1->mac();

    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    $mac2->add("hello ");
    $mac2->add("world ");
    $mac2->add("foo ");
    $mac2->add("bar");
    my $d2 = $mac2->mac();

    is($d1, $d2, 'chunked add() matches single add()');
}

# --- add() with list argument ---

{
    my $key = "list-add";

    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->add("abc", "def", "ghi");
    my $d1 = $mac1->mac();

    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    $mac2->add("abcdefghi");
    my $d2 = $mac2->mac();

    is($d1, $d2, 'add() with list matches add() with concatenated string');
}

# --- reset() and reuse ---

{
    my $key  = "reset-test";
    my $data = "data for reset test";

    my $mac = Crypt::RIPEMD160::MAC->new($key);
    $mac->add($data);
    my $d1 = $mac->mac();

    $mac->reset();
    $mac->add($data);
    my $d2 = $mac->mac();

    is($d1, $d2, 'reset() + same data produces same MAC');
}

# --- reset() after mac() matches fresh new() ---

{
    my $key  = "fresh-vs-reset";
    my $data = "compare fresh and reset";

    my $fresh = Crypt::RIPEMD160::MAC->new($key);
    $fresh->add($data);
    my $d_fresh = $fresh->mac();

    my $reused = Crypt::RIPEMD160::MAC->new($key);
    $reused->add("throwaway data to dirty the state");
    $reused->mac();  # consume
    $reused->reset();
    $reused->add($data);
    my $d_reused = $reused->mac();

    is($d_fresh, $d_reused, 'MAC after reset() matches fresh new()');
}

# --- reset() returns $self ---

{
    my $mac = Crypt::RIPEMD160::MAC->new("key");
    my $ret = $mac->reset();
    is($ret, $mac, 'reset() returns $self');
}

# --- Key exactly 64 bytes (block size boundary, no hashing) ---

{
    my $key64 = "A" x 64;
    my $data  = "block-size key test";

    my $mac = Crypt::RIPEMD160::MAC->new($key64);
    $mac->add($data);
    my $d64 = $mac->mac();

    is(length($d64), 20, '64-byte key produces valid 20-byte MAC');

    # Different from a shorter key
    my $mac_short = Crypt::RIPEMD160::MAC->new("A");
    $mac_short->add($data);
    my $d_short = $mac_short->mac();

    isnt($d64, $d_short, '64-byte key differs from 1-byte key');
}

# --- Key longer than 64 bytes (hashed per RFC 2104) ---

{
    my $key80 = "B" x 80;
    my $data  = "long key test";

    my $mac = Crypt::RIPEMD160::MAC->new($key80);
    $mac->add($data);
    my $d80 = $mac->mac();

    is(length($d80), 20, 'long key (80 bytes) produces valid 20-byte MAC');

    # Long key gets hashed to 20 bytes, so it should differ from using
    # the key directly (if it were <= 64 bytes)
    my $mac_raw = Crypt::RIPEMD160::MAC->new($key80);
    $mac_raw->add($data);
    my $d_raw = $mac_raw->mac();

    is($d80, $d_raw, 'long key is deterministic');
}

# --- Key exactly 65 bytes (just over block size) ---

{
    my $key65 = "C" x 65;
    my $data  = "boundary key test";

    my $mac = Crypt::RIPEMD160::MAC->new($key65);
    $mac->add($data);
    my $d65 = $mac->mac();

    is(length($d65), 20, '65-byte key produces valid 20-byte MAC');
}

# --- Binary key ---

{
    my $key = join('', map { chr($_) } 0..255);
    my $data = "binary key test";

    my $mac = Crypt::RIPEMD160::MAC->new($key);
    $mac->add($data);
    my $digest = $mac->mac();

    is(length($digest), 20, 'binary key (all byte values) produces valid MAC');
}

# --- Empty key ---

{
    my $mac = Crypt::RIPEMD160::MAC->new("");
    $mac->add("data with empty key");
    my $digest = $mac->mac();

    is(length($digest), 20, 'empty key produces valid 20-byte MAC');
}

# --- addfile() ---

{
    my $key  = "addfile-test";
    my $data = "file content for MAC addfile test\n" x 100;

    # Write test data to a temp file
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh $data;
    close $fh;

    # MAC via addfile
    open(my $rfh, '<', $filename) or die "Cannot open $filename: $!";
    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->addfile($rfh);
    my $d1 = $mac1->mac();
    close $rfh;

    # MAC via add
    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    $mac2->add($data);
    my $d2 = $mac2->mac();

    is($d1, $d2, 'addfile() produces same MAC as add() with same content');
}

# --- addfile() with empty file ---

{
    my $key = "empty-file";
    my ($fh, $filename) = tempfile(UNLINK => 1);
    close $fh;

    open(my $rfh, '<', $filename) or die "Cannot open $filename: $!";
    my $mac1 = Crypt::RIPEMD160::MAC->new($key);
    $mac1->addfile($rfh);
    my $d_file = $mac1->mac();
    close $rfh;

    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    my $d_empty = $mac2->mac();

    is($d_file, $d_empty, 'addfile() on empty file matches empty-message MAC');
}

# --- Large data (multiple blocks) ---

{
    my $key  = "large-data";
    my $data = "x" x 10000;

    my $mac = Crypt::RIPEMD160::MAC->new($key);
    $mac->add($data);
    my $digest = $mac->mac();

    is(length($digest), 20, 'large data (10KB) produces valid MAC');

    # Verify chunked processing matches
    my $mac2 = Crypt::RIPEMD160::MAC->new($key);
    for my $i (0 .. 99) {
        $mac2->add("x" x 100);
    }
    my $d2 = $mac2->mac();

    is($digest, $d2, 'large data chunked matches single add');
}

# --- Data crossing block boundaries (63, 64, 65 bytes) ---

{
    my $key = "boundary-data";

    for my $len (63, 64, 65, 127, 128, 129) {
        my $data = "Z" x $len;

        my $mac = Crypt::RIPEMD160::MAC->new($key);
        $mac->add($data);
        my $digest = $mac->mac();

        is(length($digest), 20, "MAC with $len-byte data produces 20 bytes");
    }
}

# --- Multiple reset cycles ---

{
    my $key = "multi-reset";
    my @digests;

    my $mac = Crypt::RIPEMD160::MAC->new($key);
    for my $round (1..3) {
        $mac->add("round $round data");
        push @digests, $mac->mac();
        $mac->reset();
    }

    # Each round should produce a different MAC (different data)
    isnt($digests[0], $digests[1], 'different data after reset produces different MAC (round 1 vs 2)');
    isnt($digests[1], $digests[2], 'different data after reset produces different MAC (round 2 vs 3)');

    # Same data after reset should match
    $mac->reset();
    $mac->add("round 1 data");
    my $d_repeat = $mac->mac();
    is($d_repeat, $digests[0], 'same data after reset reproduces original MAC');
}

done_testing;
