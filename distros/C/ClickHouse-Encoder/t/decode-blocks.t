#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# decode_blocks reads a concatenated stream of Native blocks - which is
# what a select ... format native response over HTTP returns when the
# result spans multiple blocks (the server emits one block per N rows,
# bounded by max_block_size).

my $enc = ClickHouse::Encoder->new(columns => [['n', 'Int32'], ['s', 'String']]);

# Two blocks of 2 rows each, concatenated.
my $block1 = $enc->encode([[1, "one"], [2, "two"]]);
my $block2 = $enc->encode([[3, "three"], [4, "four"]]);
my $stream = $block1 . $block2;

my $blocks = ClickHouse::Encoder->decode_blocks($stream);
is(scalar(@$blocks), 2, 'two blocks decoded');
is($blocks->[0]{nrows}, 2, 'block 0: 2 rows');
is($blocks->[1]{nrows}, 2, 'block 1: 2 rows');
is_deeply($blocks->[0]{columns}[0]{values}, [1, 2], 'block 0 col 0');
is_deeply($blocks->[1]{columns}[1]{values}, ["three", "four"], 'block 1 col 1');

# Empty stream
{
    my $blocks = ClickHouse::Encoder->decode_blocks("");
    is_deeply($blocks, [], 'empty stream -> empty list');
}

# Single block also works
{
    my $blocks = ClickHouse::Encoder->decode_blocks($block1);
    is(scalar(@$blocks), 1, 'single block via decode_blocks');
    is($blocks->[0]{nrows}, 2);
}

# Three blocks
{
    my $three = $block1 . $block1 . $block2;
    my $blocks = ClickHouse::Encoder->decode_blocks($three);
    is(scalar(@$blocks), 3, 'three blocks');
    is_deeply($blocks->[0]{columns}[0]{values}, [1, 2]);
    is_deeply($blocks->[1]{columns}[0]{values}, [1, 2]);
    is_deeply($blocks->[2]{columns}[0]{values}, [3, 4]);
}

# Trailing garbage croaks
{
    my $err = eval {
        ClickHouse::Encoder->decode_blocks($block1 . "xxx"); 1
    } ? "" : $@;
    like($err, qr/truncated|exceeds remaining/i, 'trailing garbage croaks');
}

# Direct 3-arg form of decode_block (with offset) - this is the XS path
# decode_blocks relies on; pin it independently.
{
    my $first = ClickHouse::Encoder->decode_block($stream, 0);
    is($first->{nrows}, 2, '3-arg decode_block at offset 0');
    my $second = ClickHouse::Encoder->decode_block($stream, $first->{consumed});
    is($second->{nrows}, 2, '3-arg decode_block at non-zero offset');
    is_deeply($second->{columns}[1]{values}, ["three", "four"],
              '3-arg form decoded correct second block');

    # Negative offset rejected
    my $err = eval { ClickHouse::Encoder->decode_block($stream, -1); 1 }
            ? "" : $@;
    like($err, qr/non-negative/, 'negative offset rejected');

    # Offset past end rejected
    $err = eval {
        ClickHouse::Encoder->decode_block($stream, length($stream) + 1); 1
    } ? "" : $@;
    like($err, qr/past end/, 'offset past end rejected');
}

# decode_blocks callback form
{
    my $three = $block1 . $block1 . $block2;
    my @nrows;
    ClickHouse::Encoder->decode_blocks($three, sub {
        push @nrows, $_[0]{nrows};
    });
    is_deeply(\@nrows, [2, 2, 2], 'callback form invoked per block');
}

# decode_blocks_iter returns coderef yielding one block per call
{
    my $three = $block1 . $block1 . $block2;
    my $iter = ClickHouse::Encoder->decode_blocks_iter($three);
    isa_ok($iter, 'CODE', 'iter returns coderef');
    my @blocks;
    while (my $b = $iter->()) { push @blocks, $b }
    is(scalar(@blocks), 3, 'iter yielded 3 blocks');
    is($iter->(), undef, 'iter exhausted returns undef');
}

# Empty input via iter
{
    my $iter = ClickHouse::Encoder->decode_blocks_iter("");
    is($iter->(), undef, 'empty input iter -> undef immediately');
}

# decode_stream: pull-style from a filehandle, exercises chunk-by-chunk
# buffer growth and the "need more bytes" retry path.
{
    require File::Temp;
    my ($fh, $path) = File::Temp::tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $block1 . $block2;
    close $fh;
    open my $in, '<', $path or die "open $path: $!";
    binmode $in;
    my @nrows;
    ClickHouse::Encoder->decode_stream($in,
        sub { push @nrows, $_[0]{nrows} },
        chunk_size => 4);  # tiny chunks force the buffer-grow path
    close $in;
    is_deeply(\@nrows, [2, 2],
              'decode_stream yields blocks across small reads');
}

# Truncated tail -> croak with clear message.
{
    require File::Temp;
    my ($fh, $path) = File::Temp::tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $block1 . substr($block2, 0, 5);  # mid-header
    close $fh;
    open my $in, '<', $path or die;
    binmode $in;
    my $err = eval {
        ClickHouse::Encoder->decode_stream($in, sub { }); 1
    } ? '' : $@;
    close $in;
    like($err, qr/trailing bytes after last complete block/,
         'decode_stream croaks on truncated tail');
}

# types: enumeration is sensible
{
    my @t = ClickHouse::Encoder->types;
    cmp_ok(scalar @t, '>', 20, 'types returns many entries');
    ok((grep { $_ eq 'Int64'         } @t), 'types includes Int64');
    ok((grep { $_ eq 'JSON'          } @t), 'types includes JSON');
    ok((grep { $_ eq 'Dynamic'       } @t), 'types includes Dynamic');
    ok((grep { $_ eq 'LowCardinality'} @t), 'types includes LowCardinality');
}

# server_version: live test (skip if no server)
SKIP: {
    require HTTP::Tiny;
    my $ping = HTTP::Tiny->new(timeout => 1)
        ->get("http://127.0.0.1:18123/ping");
    skip "ClickHouse HTTP not reachable on :18123", 3
        unless $ping->{success} && $ping->{content} =~ /Ok/;

    my $v = ClickHouse::Encoder->server_version(
        host => '127.0.0.1', port => 18123);
    is(ref $v, 'HASH', 'server_version scalar form returns hashref');
    cmp_ok($v->{major}, '>=', 20, 'major version sane');
    my @parts = ClickHouse::Encoder->server_version(
        host => '127.0.0.1', port => 18123);
    cmp_ok(scalar @parts, '>=', 2, 'list form returns parts');
}

# Column projection threaded through the three multi-block helpers.
# Build a two-block stream with three columns (id, payload, ts), then
# decode keeping only id + ts; verify that "payload" comes back with
# skipped=1 and that id+ts values match the originals.
{
    my $enc = ClickHouse::Encoder->new(columns =>
        [['id','Int32'], ['payload','String'], ['ts','DateTime']]);
    my $block_a = $enc->encode([[1, 'a' x 200, 1700000000],
                                [2, 'b' x 200, 1700000001]]);
    my $block_b = $enc->encode([[3, 'c' x 200, 1700000002]]);
    my $stream  = $block_a . $block_b;

    my $keep = { id => 1, ts => 1 };

    # decode_blocks (callback form)
    my @ids;
    ClickHouse::Encoder->decode_blocks($stream, sub {
        my $blk = shift;
        for my $col (@{ $blk->{columns} }) {
            if ($col->{name} eq 'payload') {
                ok($col->{skipped}, 'payload marked skipped (decode_blocks cb)');
            }
            push @ids, @{ $col->{values} } if $col->{name} eq 'id';
        }
    }, keep => $keep);
    is_deeply(\@ids, [1, 2, 3], 'decode_blocks keep retained id column');

    # decode_blocks (list form)
    my $blocks = ClickHouse::Encoder->decode_blocks($stream, undef, keep => $keep);
    is(scalar @$blocks, 2, 'list form returns both blocks');
    my %by_name = map { $_->{name} => $_ } @{ $blocks->[0]{columns} };
    ok($by_name{payload}{skipped}, 'list form: payload skipped');
    is_deeply($by_name{id}{values}, [1, 2], 'list form: id values intact');

    # decode_blocks_iter
    my $iter = ClickHouse::Encoder->decode_blocks_iter($stream, keep => $keep);
    my $b1 = $iter->();
    my $b2 = $iter->();
    is($iter->(), undef, 'iter exhausted after 2 blocks');
    my %iter_by_name = map { $_->{name} => $_ } @{ $b1->{columns} };
    ok($iter_by_name{payload}{skipped}, 'iter form: payload skipped');

    # decode_stream
    open my $in, '<', \$stream or die;
    binmode $in;
    my @seen_ids;
    ClickHouse::Encoder->decode_stream($in, sub {
        my $blk = shift;
        for my $col (@{ $blk->{columns} }) {
            if ($col->{name} eq 'payload') {
                ok($col->{skipped}, 'decode_stream: payload skipped');
            }
            push @seen_ids, @{ $col->{values} } if $col->{name} eq 'id';
        }
    }, chunk_size => 64, keep => $keep);
    is_deeply(\@seen_ids, [1, 2, 3], 'decode_stream keep: ids match across reads');
}

# decode_stream(decompress => 1) reads a stream of compressed-block-
# framed Native blocks (the format CH's HTTP `?compress=1` returns).
SKIP: {
    eval { require Compress::LZ4; 1 }
        or skip 'Compress::LZ4 not installed', 3;
    my $enc = ClickHouse::Encoder->new(columns =>
        [['id','Int32'], ['s','String']]);
    my $block_a = $enc->encode([[1,'a'], [2,'bb']]);
    my $block_b = $enc->encode([[3,'ccc']]);
    # The compressed stream: each Native block wrapped in compressed-block
    # framing, then concatenated.
    my $stream = ClickHouse::Encoder->compress_native_block($block_a)
               . ClickHouse::Encoder->compress_native_block($block_b);

    open my $in, '<', \$stream or die;
    binmode $in;
    my @seen_ids;
    ClickHouse::Encoder->decode_stream($in, sub {
        my $blk = shift;
        for my $col (@{ $blk->{columns} }) {
            push @seen_ids, @{ $col->{values} } if $col->{name} eq 'id';
        }
    }, chunk_size => 32, decompress => 1);
    is_deeply(\@seen_ids, [1, 2, 3],
              'decode_stream(decompress=>1): ids match across decompressed blocks');

    # Same, but with a single chunk_size large enough to hold everything
    # in one read - the inner two-phase walker should still work.
    open my $in2, '<', \$stream or die;
    binmode $in2;
    my $count = 0;
    ClickHouse::Encoder->decode_stream($in2, sub { $count++ },
        chunk_size => 65536, decompress => 1);
    is($count, 2, 'decode_stream(decompress=>1): both blocks seen in one chunk');

    # Truncated tail (chop off the last 4 bytes of the last compressed
    # block) -> croak with the trailing-bytes message.
    my $truncated = substr($stream, 0, -4);
    open my $in3, '<', \$truncated or die;
    binmode $in3;
    my $err = eval {
        ClickHouse::Encoder->decode_stream($in3, sub { },
            chunk_size => 32, decompress => 1);
        1
    } ? '' : $@;
    like($err, qr/trailing bytes/,
         'decode_stream(decompress=>1): truncated stream croaks');
}

done_testing();
