#!/usr/bin/env perl
# Exhaustively exercise the Streamer batch boundaries / error paths /
# reset+resume. The streamer is the most stateful API surface and is
# the most likely place for regressions; these tests pin the contract.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use ClickHouse::Encoder;

sub make_enc { ClickHouse::Encoder->new(columns => [['v', 'UInt32']]) }

# batch_size = 1: every push_row flushes a complete block.
{
    my @blocks;
    my $st = make_enc()->streamer(sub { push @blocks, $_[0] }, batch_size => 1);
    $st->push_row([$_]) for 1..3;
    is(scalar @blocks, 3, 'batch_size=1: 3 pushes => 3 blocks');
    $st->finish;
    is(scalar @blocks, 3, 'finish on empty streamer: no extra block');
}

# Exact multiple of batch_size: finish must not emit an empty block.
{
    my @blocks;
    my $st = make_enc()->streamer(sub { push @blocks, $_[0] }, batch_size => 5);
    $st->push_row([$_]) for 1..10;
    is(scalar @blocks, 2, '10 rows / batch=5 => 2 blocks');
    $st->finish;
    is(scalar @blocks, 2, 'finish after exact multiple: no extra empty block');
}

# batch_size + 1: leftover row is flushed by finish.
{
    my @blocks;
    my $st = make_enc()->streamer(sub { push @blocks, $_[0] }, batch_size => 5);
    $st->push_row([$_]) for 1..6;
    is(scalar @blocks, 1, '6 rows / batch=5 => 1 auto block (leftover buffered)');
    is($st->buffered_count, 1, 'buffered_count = 1 leftover');
    ok(!$st->is_empty, 'is_empty false with leftover');
    $st->finish;
    is(scalar @blocks, 2, 'finish flushes the leftover block');
    is($st->buffered_count, 0, 'buffered_count = 0 after finish');
    ok($st->is_empty, 'is_empty true after finish');
}

# Writer croaks mid-batch: streamer state is consistent (empty buffer).
# A subsequent push_row must not replay the failed batch.
{
    my $emit = 0;
    my $writer = sub {
        $emit++;
        die "writer failed" if $emit == 1;
    };
    my @ok_blocks;
    my $st = make_enc()->streamer($writer, batch_size => 2);
    eval { $st->push_row([$_]) for 1..3 };
    like($@, qr/writer failed/, 'writer croak propagated');
    is($st->buffered_count, 0,
       'streamer recovers after writer croak: empty buffer (not replaying)')
        or diag "buffered=" . $st->buffered_count;

    # Replace the writer is not supported (writer is bound at streamer
    # creation), so we have to either retry from a new streamer or accept
    # the error.  The contract: subsequent pushes proceed cleanly.
    my $st2 = make_enc()->streamer(sub { push @ok_blocks, $_[0] }, batch_size => 2);
    $st2->push_row([$_]) for 1..2;
    is(scalar @ok_blocks, 1, 'fresh streamer post-error: works as normal');
}

# reset() discards buffered rows without flushing.
{
    my @blocks;
    my $st = make_enc()->streamer(sub { push @blocks, $_[0] }, batch_size => 100);
    $st->push_row([$_]) for 1..5;
    is($st->buffered_count, 5, '5 rows buffered before reset');
    $st->reset;
    is($st->buffered_count, 0, 'reset clears buffer');
    is(scalar @blocks, 0, 'reset emitted no block');
    $st->push_row([$_]) for 1..3;
    $st->finish;
    is(scalar @blocks, 1, 'streamer reusable after reset, finish flushes the new batch');
}

# Double-finish is harmless.
{
    my @blocks;
    my $st = make_enc()->streamer(sub { push @blocks, $_[0] }, batch_size => 10);
    $st->push_row([1]);
    $st->finish;
    is(scalar @blocks, 1, 'first finish emits the buffered batch');
    $st->finish;
    is(scalar @blocks, 1, 'second finish on empty streamer: no extra block');
}

# push_row after finish is allowed; behaves like a fresh streaming session.
{
    my @blocks;
    my $st = make_enc()->streamer(sub { push @blocks, $_[0] }, batch_size => 10);
    $st->push_row([1]); $st->finish;
    $st->push_row([2]); $st->finish;
    is(scalar @blocks, 2, 'push_row after finish reopens the streamer');
}

# Encoder dropped before streamer: streamer keeps the encoder alive
# (XS holds a refcount) and finish still works.
{
    my @blocks;
    my $st;
    {
        my $enc = make_enc();
        $st = $enc->streamer(sub { push @blocks, $_[0] }, batch_size => 5);
    }   # $enc drops out of scope here
    $st->push_row([$_]) for 1..3;
    $st->finish;
    is(scalar @blocks, 1, 'encoder dropped: streamer still flushes a block');
}

# streamer(compress => 'lz4'): each emitted batch goes through
# compress_native_block before reaching the writer.
SKIP: {
    eval { require Compress::LZ4; 1 }
        or skip 'Compress::LZ4 not installed', 5;
    my $enc = ClickHouse::Encoder->new(columns => [['x','Int32']]);
    my @emitted;
    my $st = $enc->streamer(sub { push @emitted, $_[0] },
        batch_size => 3, compress => 'lz4');
    $st->push_row([$_]) for 1..7;
    $st->finish;
    is(scalar @emitted, 3, 'three compressed batches emitted');

    # Each emitted blob must be a compressed-block-framed payload:
    # method tag 0x82 at offset 16. Round-trip via decompress_native_block
    # and verify the inner Native bytes decode to the expected rows.
    my @all_ids;
    for my $i (0..$#emitted) {
        my $tag = ord substr($emitted[$i], 16, 1);
        is($tag, 0x82, "emitted block $i carries LZ4 method tag");
        my $plain = ClickHouse::Encoder->decompress_native_block($emitted[$i]);
        my $blk   = ClickHouse::Encoder->decode_block($plain);
        push @all_ids, @{ $blk->{columns}[0]{values} };
    }
    is_deeply(\@all_ids, [1..7], 'compressed streamer: ids round-trip in order');
}

# streamer(compress => 'none') is the same as no compress option:
# the writer sees raw Native bytes (no compressed-block framing).
{
    my $enc = ClickHouse::Encoder->new(columns => [['x','Int32']]);
    my @emitted;
    my $st = $enc->streamer(sub { push @emitted, $_[0] },
        batch_size => 2, compress => 'none');
    $st->push_row([10]);
    $st->push_row([20]);
    $st->finish;
    is(scalar @emitted, 1, 'compress=none: one batch emitted');
    # Native blocks start with two varints (ncols, nrows). The 0x82
    # method tag would only appear at offset 16, so a 2-row Native
    # block under 16 bytes can't be confused with a compressed block.
    my $blk = ClickHouse::Encoder->decode_block($emitted[0]);
    is($blk->{nrows}, 2, 'compress=none: writer received raw Native bytes');
}


# streamer(compress => 'lz4', hasher => $cref): the custom hasher must
# be the one that produces the 16-byte checksum at the start of each
# framed block. A fixed-output hasher makes this directly observable.
SKIP: {
    eval { require Compress::LZ4; 1 }
        or skip 'Compress::LZ4 not installed', 2;

    my $marker = "X" x 16;
    my @emitted;
    my $st = make_enc()->streamer(
        sub { push @emitted, $_[0] },
        batch_size => 2,
        compress   => 'lz4',
        hasher     => sub { $marker },
    );
    $st->push_row([1]);
    $st->push_row([2]);
    $st->finish;

    is(scalar @emitted, 1, 'streamer + lz4 + custom hasher: one batch');
    is(substr($emitted[0], 0, 16), $marker,
       'streamer hasher override: first 16 bytes are the custom checksum');
}

done_testing();
