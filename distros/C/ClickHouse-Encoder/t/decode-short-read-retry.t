#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use ClickHouse::Encoder::TCP;
use File::Temp ();

# Short reads must be retried, not fatal, for wide-column guards.
# A partial chunk buffer between nrows and width*nrows bytes passes
# the decode prologue (1 byte/row floor) and trips the per-column
# guard; its message must match the sliding-buffer retry regexes in
# decode_stream/select_blocks/read_packet. 400 rows of a 16-byte-wide
# type with 512-byte chunks lands in that window on chunk boundaries.

sub stream_blocks {
    my ($body, $chunk) = @_;
    my ($fh, $path) = File::Temp::tempfile(UNLINK => 1);
    binmode $fh; print $fh $body; close $fh;
    open my $in, '<', $path or die "open $path: $!";
    binmode $in;
    my @blocks;
    my $ok = eval {
        ClickHouse::Encoder->decode_stream($in,
            sub { push @blocks, $_[0] }, chunk_size => $chunk);
        1;
    };
    my $err = $ok ? '' : $@;
    close $in;
    return ($ok, $err, \@blocks);
}

my $uuid = '123e4567-e89b-12d3-a456-426614174000';
my @cases = (
    ['Decimal128(4)',      '1.5'],
    ['Decimal256(4)',      '1.5'],
    ['UUID',                $uuid],
    ['IPv6',                "\x01" x 16],
    ['Array(UInt8)',        [1, 2, 3]],
    ['Map(String, UInt32)', {a => 1, b => 2}],
);
for my $c (@cases) {
    my ($type, $val) = @$c;
    my $enc = ClickHouse::Encoder->new(columns => [['v', $type]]);
    my $body = $enc->encode([ map { [$val] } 1 .. 400 ]);
    my ($ok, $err, $blocks) = stream_blocks($body, 512);
    ok($ok, "decode_stream retries short $type reads") or diag($err);
    is(scalar @$blocks, 1, "$type: one block streamed");
    is($blocks->[0]{nrows}, 400, "$type: all rows streamed");
}

{
    my $enc = ClickHouse::Encoder->new(columns => [['u', 'UUID']]);
    my $body = $enc->encode([ map { [$uuid] } 1 .. 400 ]);
    my ($ok, undef, $blocks) = stream_blocks($body, 512);
    ok($ok, 'UUID stream succeeds for value check');
    my $vals = $blocks->[0]{columns}[0]{values};
    is($vals->[0], $uuid, 'UUID first value round-trips');
    is($vals->[399], $uuid, 'UUID last value round-trips');

    my $aenc = ClickHouse::Encoder->new(columns => [['v', 'Array(UInt8)']]);
    my $abody = $aenc->encode([ map { [[1, 2, 3]] } 1 .. 400 ]);
    my ($aok, undef, $ablocks) = stream_blocks($abody, 512);
    ok($aok, 'Array stream succeeds for value check');
    is_deeply($ablocks->[0]{columns}[0]{values}[0], [1, 2, 3],
              'Array first value round-trips');
}

# Contract: a truncated wide-column buffer croaks retryable wording.
{
    my $enc = ClickHouse::Encoder->new(columns => [['u', 'UUID']]);
    my $body = $enc->encode([ map { [$uuid] } 1 .. 400 ]);
    my $err = eval {
        ClickHouse::Encoder->decode_block(substr($body, 0, 1000)); 1;
    } ? '' : $@;
    like($err, qr/exceeds remaining buffer/,
         'truncated UUID decode matches retry regex');
}

# read_packet pulls 4 KiB sysreads; a 6.4 KiB UUID block trips the
# same guard mid-packet and must be retried.
{
    my $enc = ClickHouse::Encoder->new(columns => [['u', 'UUID']]);
    my $block = $enc->encode([ map { [$uuid] } 1 .. 400 ]);
    my $pkt = "\x01" . "\x00"
        . ClickHouse::Encoder::TCP::pack_block_info() . $block;
    pipe(my $r, my $w) or die "pipe: $!";
    binmode $r; binmode $w;
    print $w $pkt;
    close $w;
    my $got = eval { ClickHouse::Encoder::TCP->read_packet($r) };
    my $err = $@;
    close $r;
    ok(!$err && $got, 'read_packet retries short UUID reads') or diag($err);
    is($got->{block}{nrows}, 400, 'read_packet: all UUID rows decoded');
    is($got->{block}{columns}[0]{values}[0], $uuid,
       'read_packet: UUID value round-trips');
}

done_testing();
