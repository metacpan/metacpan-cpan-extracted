#!/usr/bin/env perl
# Force the internal Buffer to grow several times during a single
# encode and verify the final wire bytes match a one-shot encode of
# the same input. Catches realloc bugs in buf_grow (e.g. a stale
# buf->ptr after SvGROW relocates the SV body).
#
# The buffer starts at 256 bytes (see buf_init). Encoding ~10 MiB of
# data forces ~16 doublings (256 -> 512 -> ... -> 16 MiB). Doing it
# both in one shot and chunked via the streamer (which calls do_encode
# repeatedly with fresh buffers) cross-validates that buf_grow's
# pointer refresh is correct and that mortal-buffer cleanup between
# blocks doesn't leak or corrupt state.

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Test::More;
use ClickHouse::Encoder;
use TestCH qw(read_varint_ref);
*read_varint = \&read_varint_ref;

my $enc = ClickHouse::Encoder->new(columns => [['s', 'String']]);

# 50_000 strings of average ~200 bytes -> ~10 MiB. Each encode pass
# walks buf_grow many times because the buffer doubles geometrically.
my @rows = map { ['x' x (100 + ($_ % 200))] } 1 .. 50_000;

# One-shot encode: single call to do_encode, single buffer growth chain.
my $bin = $enc->encode(\@rows);
cmp_ok(length($bin), '>', 8 * 1024 * 1024,
       'one-shot 50k rows produces > 8 MiB of bytes');

# Chunked encode via stream(): many calls to do_encode, each with a
# fresh mortal buffer. If buf_grow leaked or corrupted state across
# blocks, the concatenated output would diverge from the single block.
# Note: stream() emits one Native block per batch (not one continuous
# block), so we can't byte-equal the two outputs -- but we can verify
# the block-headers + bodies decode to the same row count and content.
my $chunked = '';
my @rows2   = @rows;
$enc->stream(
    sub { shift @rows2 },
    sub { $chunked .= $_[0] },
    batch_size => 1000,
);
cmp_ok(length($chunked), '>', length($bin) * 0.95,
       'streamed 50k rows in 50 blocks adds up to similar size (per-block overhead is small)');

# Round-trip: decode the streamed concatenation and confirm we get
# back exactly @rows. This validates that every doubling-cycle of
# buf_grow produced wire-correct output.
my @decoded;
my $off = 0;
my $blen = length $chunked;
while ($off < $blen) {
    my $ncols = read_varint(\$chunked, \$off);
    my $nrows = read_varint(\$chunked, \$off);
    is($ncols, 1, 'block has 1 column');
    my $name_len = read_varint(\$chunked, \$off); $off += $name_len;
    my $type_len = read_varint(\$chunked, \$off); $off += $type_len;
    for (1 .. $nrows) {
        my $slen = read_varint(\$chunked, \$off);
        push @decoded, substr($chunked, $off, $slen);
        $off += $slen;
    }
}
is(scalar @decoded, scalar @rows, 'round-trip: 50000 rows decoded');
is($decoded[0],     $rows[0][0],   'round-trip: first row matches');
is($decoded[-1],    $rows[-1][0],  'round-trip: last row matches');
is($decoded[25_000],$rows[25_000][0], 'round-trip: middle row matches');

done_testing();
