#!/usr/bin/env perl
# Pin the streamer's swap-before-emit invariant: if the writer
# croaks mid-stream, the streamer's buffer must be empty (the
# spliced-out batch is the only thing the croak threw away) and
# the next push_row must work on a fresh batch.
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

my $enc = ClickHouse::Encoder->new(columns => [['x','Int32']]);

# Scenario 1: writer croaks on first emit; subsequent pushes succeed
# and a flush after a fixed writer drains the new batch cleanly.
{
    my $fail_once = 1;
    my @blocks;
    my $writer = sub {
        my $bytes = shift;
        if ($fail_once) { $fail_once = 0; die "transient writer failure\n" }
        push @blocks, $bytes;
    };
    my $s = $enc->streamer($writer, batch_size => 4);

    # Fill below batch_size so no autoflush, then flush via finish.
    # The flush calls the writer; the writer dies; eval catches it.
    $s->push_row([1]);
    $s->push_row([2]);
    $s->push_row([3]);
    my $err = eval { $s->finish; 1 } ? '' : $@;
    like($err, qr/transient writer failure/,
         'first finish bubbles writer croak');

    # The streamer should be back to empty - swap-before-emit dropped
    # the failed batch. Pushing fresh rows works.
    is($s->buffered_count, 0, 'buffer empty after failed emit (swap-before-emit)');
    ok($s->is_empty,           'is_empty true after failed emit');

    $s->push_row([10]);
    $s->push_row([20]);
    $s->push_row([30]);
    $s->finish;     # not in eval - writer no longer fails
    is(scalar @blocks, 1, 'recovered batch flushed once');

    my $blk = ClickHouse::Encoder->decode_block($blocks[0]);
    is_deeply([map @{ $_->{values} }, @{ $blk->{columns} }],
              [10, 20, 30],
              'recovered batch contains only the post-failure rows');
}

# Scenario 2: failure on a batch-size autoflush (not from finish).
# The push_row that triggers the flush should propagate the croak.
{
    my $always_fail = sub { die "writer down\n" };
    my $s = $enc->streamer($always_fail, batch_size => 2);
    $s->push_row([1]);
    # The second push_row triggers an autoflush which calls the writer
    # which dies. Wrap both push_rows so the eval{} block catches it -
    # the autoflush happens INSIDE push_row, not later.
    my $err = eval { $s->push_row([2]); 1 } ? '' : $@;
    like($err, qr/writer down/, 'autoflush propagates writer croak');
    is($s->buffered_count, 0, 'buffer empty after autoflush failure');

    # Switch to a working writer via a fresh streamer (writer is
    # captured at streamer creation time).
    my @blocks;
    my $s2 = $enc->streamer(sub { push @blocks, $_[0] }, batch_size => 2);
    $s2->push_row([7]);
    $s2->push_row([8]);  # triggers autoflush
    is(scalar @blocks, 1, 'fresh streamer recovers cleanly');
}

done_testing();
