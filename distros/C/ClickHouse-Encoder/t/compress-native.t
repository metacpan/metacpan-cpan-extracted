#!/usr/bin/env perl
# compress_native_block / decompress_native_block round-trip plus
# argument validation. Wire-compat with a real ClickHouse server
# requires a CityHash128 v1.0.2 hasher which this module does not
# bundle; here we use Digest::MD5 (16-byte digest) on both ends so
# the framing layer can be exercised without an external dep.
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use Digest::MD5 qw(md5);

# Compress::LZ4 is a 'recommends', not a hard requirement.
my $have_lz4 = eval { require Compress::LZ4; 1 };
plan skip_all => 'Compress::LZ4 not installed' unless $have_lz4;

# Default hasher is the bundled CityHash128 v1.0.2. Compress without
# passing a hasher to verify the default works end-to-end.
{
    my $bytes = 'default-hasher round-trip ' x 20;
    my $framed = ClickHouse::Encoder->compress_native_block($bytes);
    my $plain  = ClickHouse::Encoder->decompress_native_block($framed);
    is($plain, $bytes, 'compress/decompress works without explicit hasher');
}

# _cityhash128 returns exactly 16 bytes and is deterministic for any input.
{
    is(length(ClickHouse::Encoder::_cityhash128('')),    16, 'cityhash128("") is 16 bytes');
    is(length(ClickHouse::Encoder::_cityhash128('abc')), 16, 'cityhash128(short) is 16 bytes');
    my $a = ClickHouse::Encoder::_cityhash128('repeatable ' x 100);
    my $b = ClickHouse::Encoder::_cityhash128('repeatable ' x 100);
    is($a, $b, 'cityhash128 is deterministic');
    isnt($a, ClickHouse::Encoder::_cityhash128('different ' x 100),
         'cityhash128 distinguishes different inputs');
}

# unknown mode rejected
{
    my $err = eval {
        ClickHouse::Encoder->compress_native_block(
            'x' x 100, hasher => \&md5, mode => 'snappy'); 1
    } ? '' : $@;
    like($err, qr/unknown mode/, 'unknown compression mode rejected');
}

# hasher returning wrong byte count caught
{
    my $err = eval {
        ClickHouse::Encoder->compress_native_block(
            'x' x 100, hasher => sub { 'short' }); 1
    } ? '' : $@;
    like($err, qr/expected 16/, 'wrong-length hasher output caught');
}

# Round-trip: encode a Native block, compress it, decompress, verify byte
# identity and that the decoder still recognizes the bytes.
{
    my $enc = ClickHouse::Encoder->new(columns =>
        [['x','Int32'],['s','String']]);
    my $bytes = $enc->encode([[1, 'alpha'], [2, 'beta x' x 50], [3, '']]);

    my $framed = ClickHouse::Encoder->compress_native_block(
        $bytes, hasher => \&md5, mode => 'lz4');

    # Framing structure: 16 hash + 9 header + payload
    cmp_ok(length($framed), '>=', 16 + 9, 'framed block has at least header bytes');
    is(ord(substr($framed, 16, 1)), 0x82, 'LZ4 method tag byte');
    my ($csize, $usize) = unpack 'V V', substr($framed, 17, 8);
    is($usize, length($bytes), 'uncompressed_size header matches input');
    is($csize, length($framed) - 16,
       'compressed_size header covers 9-byte header + payload');

    my ($plain, $consumed) = ClickHouse::Encoder->decompress_native_block(
        $framed, hasher => \&md5);
    is($plain,    $bytes,         'round-trip restores original bytes');
    is($consumed, length($framed), 'consumed = whole framed block');

    # And the decoder still finds three rows in the decompressed block.
    my $blk = ClickHouse::Encoder->decode_block($plain);
    is($blk->{nrows}, 3, 'decoded block has 3 rows after decompression');
}

# Checksum mismatch detected
{
    my $framed = ClickHouse::Encoder->compress_native_block(
        'hello ' x 100, hasher => \&md5);
    substr($framed, 0, 1, "\xff");   # corrupt first byte of checksum
    my $err = eval {
        ClickHouse::Encoder->decompress_native_block(
            $framed, hasher => \&md5); 1
    } ? '' : $@;
    like($err, qr/checksum mismatch/, 'corrupt checksum detected');
}

# Unknown method tag rejected. The tag byte sits at offset 16, right
# after the 16-byte checksum. Corrupt it to an undefined value and
# skip checksum verification so the tag check is what fires.
{
    my $framed = ClickHouse::Encoder->compress_native_block(
        'tag test ' x 50, mode => 'none');
    substr($framed, 16, 1, "\x99");   # 0x99 is not 0x02/0x82/0x90
    my $err = eval {
        ClickHouse::Encoder->decompress_native_block(
            $framed, hasher => undef); 1
    } ? '' : $@;
    like($err, qr/unknown method tag 0x99/, 'unknown method tag rejected');
}

# Decompressed-size mismatch rejected. The uncompressed-size field is a
# 4-byte LE word at offset 21; corrupt it on a method=none block (whose
# payload is the verbatim plain bytes) so the post-decompress length
# check catches the lie.
{
    my $plain  = 'size test ' x 40;
    my $framed = ClickHouse::Encoder->compress_native_block(
        $plain, mode => 'none');
    substr($framed, 21, 4, pack('V', length($plain) + 999));
    my $err = eval {
        ClickHouse::Encoder->decompress_native_block(
            $framed, hasher => undef); 1
    } ? '' : $@;
    like($err, qr/decompressed size mismatch/,
         'wrong uncompressed-size field detected');
}

# Explicit hasher => undef on decompress skips verification entirely.
# Useful for inspecting captured payloads whose hasher we can't reproduce.
{
    my $bytes  = 'payload ' x 500;
    my $framed = ClickHouse::Encoder->compress_native_block(
        $bytes, hasher => \&md5);
    my $plain  = ClickHouse::Encoder->decompress_native_block(
        $framed, hasher => undef);
    is($plain, $bytes,
       'decompress with hasher => undef skips verification');
}

# offset = walk a stream of compressed blocks back-to-back.
{
    my @inputs = ('first block payload',
                  'second' x 200,
                  '' . ('z' x 100));
    my $stream = '';
    for my $b (@inputs) {
        $stream .= ClickHouse::Encoder->compress_native_block(
            $b, hasher => \&md5);
    }
    my $off = 0;
    my @decoded;
    while ($off < length $stream) {
        my ($plain, $n) = ClickHouse::Encoder->decompress_native_block(
            $stream, hasher => \&md5, offset => $off);
        push @decoded, $plain;
        $off += $n;
    }
    is_deeply(\@decoded, \@inputs, 'walked a multi-block compressed stream');
}

# mode => 'auto' picks LZ4 when it wins, falls back to method-tag 0x02
# (uncompressed-inside-framing) when LZ4 output >= input size. Mirrors
# what ClickHouse's own CompressedWriteBuffer does for incompressible
# payloads.
{
    # Highly compressible (LZ4 wins): expect tag 0x82
    my $compressible = 'aaaaaaaa' x 200;
    my $framed1 = ClickHouse::Encoder->compress_native_block(
        $compressible, mode => 'auto');
    is(ord(substr($framed1, 16, 1)), 0x82,
       'auto: compressible payload -> LZ4 tag 0x82');
    my $plain1 = ClickHouse::Encoder->decompress_native_block($framed1);
    is($plain1, $compressible, 'auto/LZ4 round-trip restores input');

    # Incompressible (random-ish): LZ4 doesn't shrink it, fall back to NONE
    my $incompressible = pack('C*', map { $_ * 37 + 11 & 0xff } 0..255);
    my $framed2 = ClickHouse::Encoder->compress_native_block(
        $incompressible, mode => 'auto');
    is(ord(substr($framed2, 16, 1)), 0x02,
       'auto: incompressible payload -> NONE tag 0x02');
    my $plain2 = ClickHouse::Encoder->decompress_native_block($framed2);
    is($plain2, $incompressible, 'auto/NONE round-trip restores input');
}

# mode => 'auto' compresses the payload only once when LZ4 wins.
# Wrap Compress::LZ4::lz4_compress with a call counter and confirm
# the auto-LZ4 path calls it exactly once, not twice (the probe
# result must be reused as the final payload).
{
    require Compress::LZ4;
    my $count = 0;
    my $orig  = \&Compress::LZ4::lz4_compress;
    no warnings 'redefine';
    local *Compress::LZ4::lz4_compress = sub { $count++; $orig->(@_) };
    my $compressible = 'aaaaaaaa' x 200;
    my $framed = ClickHouse::Encoder->compress_native_block(
        $compressible, mode => 'auto');
    is($count, 1, 'auto/LZ4-win: lz4_compress invoked once (probe reused)');
    # Verify the framed output still round-trips correctly.
    my $plain = ClickHouse::Encoder->decompress_native_block($framed);
    is($plain, $compressible, 'auto/LZ4-win: round-trip after single-pass');
}

# Explicit mode => 'none' (compressed-block framing without compression)
{
    my $bytes = 'mixed data ' x 30;
    my $framed = ClickHouse::Encoder->compress_native_block(
        $bytes, mode => 'none');
    is(ord(substr($framed, 16, 1)), 0x02,
       'mode=none: NONE tag 0x02');
    # Compressed_size header == 9 + length of payload (uncompressed)
    my ($csize, $usize) = unpack 'V V', substr($framed, 17, 8);
    is($usize, length($bytes), 'mode=none: uncompressed_size = input');
    is($csize, 9 + length($bytes), 'mode=none: compressed_size = 9 + input');
    my $plain = ClickHouse::Encoder->decompress_native_block($framed);
    is($plain, $bytes, 'mode=none: round-trip');
}

# ZSTD path (optional - only run if Compress::Zstd is installed)
SKIP: {
    eval { require Compress::Zstd; 1 }
        or skip 'Compress::Zstd not installed', 2;
    my $bytes  = 'zstd payload ' x 50;
    my $framed = ClickHouse::Encoder->compress_native_block(
        $bytes, hasher => \&md5, mode => 'zstd');
    is(ord(substr($framed, 16, 1)), 0x90, 'ZSTD method tag byte');
    my $plain = ClickHouse::Encoder->decompress_native_block(
        $framed, hasher => \&md5);
    is($plain, $bytes, 'zstd round-trip');
}

done_testing();
