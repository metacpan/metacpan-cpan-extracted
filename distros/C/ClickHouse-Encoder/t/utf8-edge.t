#!/usr/bin/env perl
# Strings on the wire are byte sequences. When a Perl scalar has the
# utf8 flag set, the encoder must serialize the UTF-8-encoded bytes,
# not the codepoints. When the flag is cleared, it must serialize the
# raw bytes. Mixing flagged and unflagged scalars in one column must
# produce stable bytes regardless of order.
use strict;
use warnings;
use utf8;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Test::More;
use Encode qw(encode_utf8);
use ClickHouse::Encoder;
use TestCH qw(read_varint_ref skip_header);
*read_varint = \&read_varint_ref;

my $enc  = ClickHouse::Encoder->new(columns => [['v', 'String']]);
my $text = 'Привет';                      # utf8-flagged
my $raw  = encode_utf8($text);             # same bytes, flag cleared

my $b1 = $enc->encode([[$text]]);
my $b2 = $enc->encode([[$raw]]);
is($b1, $b2, 'utf8-flagged and raw-byte forms encode identically');

my $b3 = $enc->encode([[$text], [$raw], [$text], [$raw]]);
my $off = skip_header($b3);
for my $i (1..4) {
    my $len = read_varint(\$b3, \$off);
    my $val = substr($b3, $off, $len); $off += $len;
    is($val, $raw, "row $i bytes are utf-8 encoded form (regardless of flag)");
}

# A Latin-1 byte scalar: utf8 OFF, single byte 0xE9. Must serialize
# verbatim, not promoted to UTF-8.
{
    my $latin = "\xe9";
    my $bin   = $enc->encode([[$latin]]);
    my $o     = skip_header($bin);
    my $len   = read_varint(\$bin, \$o);
    is($len, 1, 'Latin-1 byte encodes as 1-byte String');
    is(substr($bin, $o, 1), "\xe9", 'Latin-1 byte preserved verbatim');
}

# FixedString truncation by bytes, not codepoints.
{
    my $f = ClickHouse::Encoder->new(columns => [['v', 'FixedString(6)']]);
    my $bin = $f->encode([['Привет']]);
    is(substr($bin, -6), "\xd0\x9f\xd1\x80\xd0\xb8",
       'FixedString(6) truncates by bytes, not codepoints (6-codepoint Cyrillic input)');
}

done_testing();
