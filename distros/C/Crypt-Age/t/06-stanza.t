#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Crypt::Age;
use Crypt::Age::Header;
use Crypt::Age::Keys;
use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use Crypt::Age::Stanza::X25519;

# ---------------------------------------------------------------------------
# karr #3 -- the empty final line
#
# c2sp.org/age ABNF:
#
#     stanza     = arg-line *full-line final-line
#     arg-line   = "->" 1*(SP VCHAR) LF
#     full-line  = 64base64char LF
#     final-line = *63base64char LF
#
# A final-line is at most 63 characters, so a body whose base64 encoding is an
# exact multiple of 64 MUST be followed by an EMPTY final line -- there is no
# other way to terminate the stanza. Header::parse reads this correctly
# (`last if $len < 64`); the writer was the broken half.
#
# A Perl round trip cannot catch this: our reader accepts both forms, so writer
# and reader stay in agreement while both drift off the wire format. These
# assertions are therefore on literal bytes, not on re-parsed structure.
# ---------------------------------------------------------------------------

# 48 raw bytes -> exactly 64 base64 chars -> one full-line + empty final-line.
{
    my $body = join '', map { chr($_ % 251) } 1 .. 48;
    my $body_b64 = Crypt::Age::Stanza::encode_base64_no_padding($body);
    is(length($body_b64), 64, 'fixture: 48-byte body encodes to exactly 64 base64 chars');

    my $stanza = Crypt::Age::Stanza->new(
        type => 'stanza-test',
        args => ['one'],
        body => $body,
    );

    my $expected = "-> stanza-test one\n" . $body_b64 . "\n";
    is($stanza->to_string, $expected,
        'exact-64-char body serializes with the required empty final line');

    my @lines = split /\n/, $stanza->to_string, -1;
    is(scalar @lines, 3,
        'arg-line, one full-line and an empty final line (split with -1 keeps it)');
    is($lines[2], '', 'the final line is empty');
}

# 96 raw bytes -> 128 base64 chars -> two full-lines + empty final-line.
{
    my $body = join '', map { chr($_ % 251) } 1 .. 96;
    my $body_b64 = Crypt::Age::Stanza::encode_base64_no_padding($body);
    is(length($body_b64), 128, 'fixture: 96-byte body encodes to exactly 128 base64 chars');

    my $stanza = Crypt::Age::Stanza->new(
        type => 'stanza-test',
        body => $body,
    );

    my $expected = "-> stanza-test\n"
        . substr($body_b64, 0, 64) . "\n"
        . substr($body_b64, 64, 64) . "\n";
    is($stanza->to_string, $expected,
        '128-char body serializes as two full lines plus the empty final line');

    my @lines = split /\n/, $stanza->to_string, -1;
    is(scalar @lines, 4, 'arg-line, two full-lines and an empty final line');
    is($lines[3], '', 'the final line is empty');
}

# 32 raw bytes -> 43 base64 chars: the X25519 shape. Not a multiple of 64, so
# the final line carries the remainder and there is NO extra empty line. This
# pins the unchanged half of the fix -- every file this distribution has ever
# written goes through here.
{
    my $body = join '', map { chr($_ % 251) } 1 .. 32;
    my $body_b64 = Crypt::Age::Stanza::encode_base64_no_padding($body);
    is(length($body_b64), 43, 'fixture: 32-byte body encodes to 43 base64 chars');

    my $stanza = Crypt::Age::Stanza->new(
        type => 'X25519',
        args => ['abc'],
        body => $body,
    );

    is($stanza->to_string, "-> X25519 abc\n" . $body_b64,
        '43-char body is unchanged: no trailing newline, no extra empty line');

    my @lines = split /\n/, $stanza->to_string, -1;
    is(scalar @lines, 2, 'arg-line and a short final line, nothing more');
}

# 65 base64 chars is not a boundary case: one full-line and a one-character
# final line. Guards against an off-by-one in the other direction.
{
    my $body = join '', map { chr($_ % 251) } 1 .. 49;   # 49 bytes -> 66 chars
    my $body_b64 = Crypt::Age::Stanza::encode_base64_no_padding($body);
    is(length($body_b64), 66, 'fixture: 49-byte body encodes to 66 base64 chars');

    my $stanza = Crypt::Age::Stanza->new(type => 'stanza-test', body => $body);
    is($stanza->to_string,
        "-> stanza-test\n" . substr($body_b64, 0, 64) . "\n" . substr($body_b64, 64),
        '66-char body: one full line plus a two-character final line');
}

# The second, measured consequence recorded on karr #3: since Header captures
# the literal header bytes at parse time, a re-serialization that omits the
# empty final line no longer reproduces the bytes the MAC was computed over,
# and the re-emitted header fails its own MAC. The ticket measured 204 captured
# bytes against 203 re-emitted on a fixture that also carried an X25519 stanza;
# this smaller fixture shows the same one-byte loss as 106 against 105.
{
    my $body = join '', map { chr($_ % 251) } 1 .. 48;
    my $body_b64 = Crypt::Age::Stanza::encode_base64_no_padding($body);

    my $file_key = Crypt::Age::Primitives->generate_file_key;

    my $head_no_mac = join("\n",
        'age-encryption.org/v1',
        '-> stanza-test',
        $body_b64,
        '',          # the required empty final line
        '---',
    );
    my $mac = Crypt::Age::Primitives->compute_header_mac($file_key, $head_no_mac);
    my $str = $head_no_mac . ' '
        . Crypt::Age::Stanza::encode_base64_no_padding($mac) . "\n";

    my $offset = 0;
    my $parsed = Crypt::Age::Header->parse(\$str, \$offset);

    # A header built from the parsed stanzas alone, i.e. with no captured
    # bytes, so its _bytes comes from the re-serializing builder.
    my $reserialized = Crypt::Age::Header->new(
        stanzas => $parsed->stanzas,
        mac     => $parsed->mac,
    );

    is(length($reserialized->_bytes), length($parsed->_bytes),
        're-serialization is the same length as the captured header bytes');
    is($reserialized->_bytes, $parsed->_bytes,
        'to_string on a parsed header reproduces the bytes that were parsed');
    ok($reserialized->verify_mac($file_key),
        'the re-serialized header still verifies its own MAC');
}

# ---------------------------------------------------------------------------
# karr #4 -- the base64 decoder must reject, not repair
#
# c2sp.org/age: "decoders MUST reject non-canonical encodings and encodings
# ending with = padding characters."
#
# Every error message below is checked for NOT containing the input: a stanza
# body is wrapped key material and a decoder error must name the reason, never
# the value.
# ---------------------------------------------------------------------------

# Padded input. "AA==" is the padded encoding of "\x00"; the age format is
# RFC 4648 section 4 unpadded, so the "==" alone makes it invalid.
{
    my $input = 'AA==';
    my $out = eval { Crypt::Age::Stanza::decode_base64_no_padding($input) };
    my $err = $@;
    ok(!defined $out, 'padded base64 does not decode');
    like($err, qr/pad/i, 'padded base64 croaks and says padding');
    unlike($err, qr/\Q$input\E/, 'the error does not repeat the input');
}

# A character outside the RFC 4648 section 4 alphabet. MIME::Base64 silently
# skips such characters, so without an explicit check "AA*A" would decode as
# "AAA" rather than being rejected.
{
    my $input = 'AA*A';
    my $out = eval { Crypt::Age::Stanza::decode_base64_no_padding($input) };
    my $err = $@;
    ok(!defined $out, 'base64 with a character outside the alphabet does not decode');
    like($err, qr/alphabet|character/i, 'invalid character croaks');
    unlike($err, qr/\Q$input\E/, 'the error does not repeat the input');
}

# Length 5, i.e. 5 % 4 == 1. No byte string encodes to a length congruent to 1
# mod 4: a trailing group of one character carries 6 bits, not enough for a
# byte. MIME::Base64 drops the stray character instead of complaining.
{
    my $input = 'AAAAA';
    my $out = eval { Crypt::Age::Stanza::decode_base64_no_padding($input) };
    my $err = $@;
    ok(!defined $out, 'length 5 (== 1 mod 4) does not decode');
    like($err, qr/length/i, 'impossible unpadded length croaks');
    unlike($err, qr/\Q$input\E/, 'the error does not repeat the input');
}

# Non-canonical trailing bits. Two base64 characters carry 12 bits but encode
# only one byte, so the low 4 bits of the second character MUST be zero.
# "AB" is 'A' = 000000, 'B' = 000001 -> byte 0x00 with leftover bits 0001.
# The canonical encoding of "\x00" is "AA", so "AB" is a second, non-canonical
# spelling of the same byte and must be rejected.
{
    my $input = 'AB';
    is(Crypt::Age::Stanza::encode_base64_no_padding("\x00"), 'AA',
        'fixture: the canonical encoding of a zero byte is "AA", not "AB"');

    my $out = eval { Crypt::Age::Stanza::decode_base64_no_padding($input) };
    my $err = $@;
    ok(!defined $out, 'non-canonical trailing bits do not decode');
    like($err, qr/canonical/i, 'non-canonical encoding croaks');
    unlike($err, qr/\Q$input\E/, 'the error does not repeat the input');
}

# The positive cases, including the two encodings this distribution produces
# itself: a 43-character X25519 stanza body and a 43-character MAC. Neither
# may be caught by the new checks.
{
    is(Crypt::Age::Stanza::decode_base64_no_padding('AA'), "\x00",
        'a canonical two-character encoding still decodes');
    is(Crypt::Age::Stanza::decode_base64_no_padding(''), '',
        'the empty encoding still decodes to the empty string');

    for my $len (16, 32, 48, 96) {
        my $bytes = join '', map { chr(($_ * 7) % 251) } 1 .. $len;
        my $b64 = Crypt::Age::Stanza::encode_base64_no_padding($bytes);
        is(Crypt::Age::Stanza::decode_base64_no_padding($b64), $bytes,
            "our own encoding of $len bytes round-trips through the strict decoder");
    }
}

# Blast radius of the strict decoder: it is also what Header::parse_from_fh
# runs over every stanza body and over the MAC line. A full encrypt/decrypt
# cycle has to keep working.
{
    my ($public, $secret) = Crypt::Age->generate_keypair;
    my $plaintext = "strict base64 decoder must not reject our own output.\n";

    my $encrypted = Crypt::Age->encrypt(
        plaintext  => $plaintext,
        recipients => [$public],
    );
    is(Crypt::Age->decrypt(ciphertext => $encrypted, identities => [$secret]),
        $plaintext,
        'full encrypt/decrypt round trip survives the strict decoder');
}

done_testing;
