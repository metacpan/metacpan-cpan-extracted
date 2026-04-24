#!perl

use strict;
use warnings;

use Test::More;
use Encode ();

use Crypt::RIPEMD160;

# RIPEMD-160("") = 9c1185a5c5e9fc54612808977ee8f548b2258d31
my $empty_hex = '9c1185a5c5e9fc54612808977ee8f548b2258d31';

# ========================================
# UTF-8 flagged strings hash as bytes
# ========================================

subtest 'UTF-8 flagged byte-range string matches byte string' => sub {
    # "\xe9" as a plain byte string (Latin-1 'e-acute')
    my $byte_str = "\xe9";
    ok(!utf8::is_utf8($byte_str), 'byte string has no UTF-8 flag');

    # Same character but with UTF-8 flag set via Encode::decode
    my $utf8_str = Encode::decode('latin-1', "\xe9");
    ok(utf8::is_utf8($utf8_str), 'decoded string has UTF-8 flag');

    # Both should produce the same hash (SvPVbyte downgrades)
    my $ctx1 = Crypt::RIPEMD160->new;
    $ctx1->add($byte_str);
    my $hex1 = unpack("H*", $ctx1->digest);

    my $ctx2 = Crypt::RIPEMD160->new;
    $ctx2->add($utf8_str);
    my $hex2 = unpack("H*", $ctx2->digest);

    is($hex1, $hex2, 'UTF-8 flagged string hashes identically to byte string');
};

subtest 'UTF-8 flagged ASCII string matches byte string' => sub {
    my $byte_str = "hello";
    my $utf8_str = Encode::decode('UTF-8', "hello");
    ok(utf8::is_utf8($utf8_str), 'decoded ASCII has UTF-8 flag');

    my $ctx1 = Crypt::RIPEMD160->new;
    $ctx1->add($byte_str);
    my $hex1 = unpack("H*", $ctx1->digest);

    my $ctx2 = Crypt::RIPEMD160->new;
    $ctx2->add($utf8_str);
    my $hex2 = unpack("H*", $ctx2->digest);

    is($hex1, $hex2, 'UTF-8 flagged ASCII hashes same as byte ASCII');
};

# ========================================
# Wide characters are rejected
# ========================================

subtest 'wide character in add() croaks' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    eval { $ctx->add("\x{100}") };
    like($@, qr/Wide character/, 'add() rejects characters > 0xFF');
};

subtest 'wide character in multi-arg add() croaks' => sub {
    my $ctx = Crypt::RIPEMD160->new;
    eval { $ctx->add("safe", "\x{263A}") };
    like($@, qr/Wide character/, 'add() rejects wide char in arg list');
};

# ========================================
# Mixed encoding in multi-arg add()
# ========================================

subtest 'multi-arg add with mixed byte and UTF-8 flagged' => sub {
    my $byte_part = "abc";
    my $utf8_part = Encode::decode('latin-1', "def");

    my $ctx1 = Crypt::RIPEMD160->new;
    $ctx1->add($byte_part, $utf8_part);
    my $hex1 = unpack("H*", $ctx1->digest);

    my $ctx2 = Crypt::RIPEMD160->new;
    $ctx2->add("abcdef");
    my $hex2 = unpack("H*", $ctx2->digest);

    is($hex1, $hex2, 'mixed byte/UTF-8 args produce correct hash');
};

# ========================================
# Full Latin-1 range with UTF-8 flag
# ========================================

subtest 'all Latin-1 bytes match with and without UTF-8 flag' => sub {
    my $all_bytes = join('', map { chr($_) } 0..255);

    my $utf8_str = Encode::decode('latin-1', $all_bytes);
    ok(utf8::is_utf8($utf8_str), 'decoded Latin-1 has UTF-8 flag');

    my $ctx1 = Crypt::RIPEMD160->new;
    $ctx1->add($all_bytes);
    my $hex1 = unpack("H*", $ctx1->digest);

    my $ctx2 = Crypt::RIPEMD160->new;
    $ctx2->add($utf8_str);
    my $hex2 = unpack("H*", $ctx2->digest);

    is($hex1, $hex2, 'full Latin-1 range hashes identically regardless of UTF-8 flag');
};

done_testing;
