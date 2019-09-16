#!/usr/bin/env perl

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Test::More;

use_ok('Crypt::IDA::SlidingWindow');

# test minimal 'split' and 'combine' constructors
my $s = Crypt::IDA::SlidingWindow
    ->new(window => 10, mode => 'split', rows => 4);
ok(ref $s, "new split?");
my $c = Crypt::IDA::SlidingWindow
    ->new(window => 10, mode => 'combine', rows => 3);
ok(ref $c, "new combine?");

# Expect errors for invalid/missing parameters
my $bad;
eval {
    $bad = Crypt::IDA::SlidingWindow
	->new(window => 10, mode => 'orange', rows => 4);
};
ok($@, "expected fail on invalid mode?");
eval {
    $bad = Crypt::IDA::SlidingWindow
	->new(window => 10, mode => 'combine');
};
ok($@, "expected fail on missing rows?");
eval {
    $bad = Crypt::IDA::SlidingWindow
	->new(mode => 'combine', rows => 4);
};
ok($@, "expected fail on missing window?");
eval {
    $bad = Crypt::IDA::SlidingWindow
	->new(window => -10, mode => 'combine', rows => 4);
};
ok($@, "expected fail on invalid window?");
eval {
    $bad = Crypt::IDA::SlidingWindow
	->new(window => 10, mode => 'combine', rows => -4);
};
ok($@, "expected fail on invalid rows?");
eval {
    $bad = Crypt::IDA::SlidingWindow
	->new(window => 10, mode => 'combine', rows => 4, 
	      read_head => 1);
};
ok($@, "expected forbid passing pointers?");

# Check splitting/combining values
ok($c->splitting == 0, "expect \$combiner->splitting == 0");
ok($c->combining == 1, "expect \$combiner->combining == 1");
ok($s->splitting == 1, "expect \$splitter->splitting == 1");
ok($s->combining == 0, "expect \$splitter->combining == 0");

# Check "yet to start" count (should be n=4, k=3) 
ok($c->yts == 3, "expect 3 combine streams at starting line");
ok($s->yts == 4, "expect 4 split streams at starting line");

# Check initial can_advance returns
my ($rok,$pok,$wok,$subs);

# split first (read from single stream, write to 4 substreams)
($rok,$pok,$wok,$subs) = $s->can_advance;
ok($rok == $s->window,      "Expect splitter can read full window");
ok($pok == 0,               "Expect splitter can't process yet");
ok($wok == 0,               "Expect splitter can't write out yet");
ok(ref $subs eq 'ARRAY',    "Expect substream is []");
ok(0 + @$subs == 4,         "Expect splitting to 4 substreams");
is_deeply($subs, [0,0,0,0], "Expect no writable split streams");

# Then combine (read from 3 input substreams, write to single)
($rok,$pok,$wok,$subs) = $c->can_advance;
ok($rok == $c->window,      "Expect combiner can read full window");
ok($pok == 0,               "Expect combiner can't process yet");
ok($wok == 0,               "Expect combiner can't write out yet");
ok(ref $subs eq 'ARRAY',    "Expect substream is []");
ok(0 + @$subs == 3,         "Expect combining from 3 substreams");
is_deeply($subs, [10,10,10],"Expect substreams can read full window");

# Invalid advance requests
eval { $s->advance_read(11) };
ok($@, "expect split can't advance read past window");
eval { $s->advance_read_substream(0,1) };
ok($@, "expect split doesn't read from substreams");
eval { $s->advance_process(1) };
ok($@, "expect split can't process without input");
eval { $s->advance_write(0,1) };
ok($@, "expect split doesn't write to single stream");

# test destraddle -- non-wrapping cases first (window size 10)
is(undef, ($c->destraddle( 0,1))[1],  "no wrap: 0 + 1");
is(undef, ($c->destraddle( 0,9))[1],  "no wrap: 0 + 9");
is(undef, ($c->destraddle( 8,1))[1],  "no wrap: 8 + 1");
is(undef, ($c->destraddle(10,1))[1],  "no wrap: 10 + 1");
is(undef, ($c->destraddle(10,9))[1],  "no wrap: 10 + 9");
is(undef, ($c->destraddle(18,1))[1],  "no wrap: 18 + 1");

# Although technically, the pointers would wrap with the following,
# it's better to return (10) than (10,0), I think. Think of it in
# terms of contiguous reads/writes rather than whether the pointer has
# wrapped or not.
is(undef, ($c->destraddle( 0,10))[1],  "no wrap: 0 + 10");
is(undef, ($c->destraddle(10,10))[1],  "no wrap: 10 + 10");

# Test error: writing more than 'window' columns 
eval { $c->destraddle( 0,11) };
ok ($@, "expect 'too many columns' error");

# wrapping cases
is_deeply([9,1], [$c->destraddle( 1,10)],  "wrap: 1 + 10 -> 9, 1");
is_deeply([8,1], [$c->destraddle( 2, 9)],  "wrap: 2 + 9  -> 8, 1");
is_deeply([1,1], [$c->destraddle( 9, 2)],  "wrap: 9 + 2  -> 1, 1");
is_deeply([9,1], [$c->destraddle(11,10)],  "wrap: 11 + 10 -> 9, 1");
is_deeply([8,1], [$c->destraddle(12, 9)],  "wrap: 12 + 9  -> 8, 1");
is_deeply([1,1], [$c->destraddle(19, 2)],  "wrap: 19 + 2  -> 1, 1");

# test advance of single read stream (split)

ok($s->advance_read(1), "advance_read(1) returns true");
($rok,$pok,$wok,$subs) = $s->can_advance;
is ($rok, 9, "read fills single input buffer");
is ($pok, 1, "read allows a column to be processed");
is ($wok, 0, "read is independent of write");

# fill up the single input buffer
$s->advance_read(9);
($rok,$pok,$wok,$subs) = $s->can_advance;
is ($rok, 0,  "single input buffer full");
is ($pok, 10, "read allowed 10 columns to be processed");
is ($wok, 0,  "read is independent of write");

eval {$s->advance_read(1)}; ok($@, "expect error reading past window");

# test advance of bundled read streams (combine)

# Try to get coverage for all possible scenarios...
#
# 1. advance row 0 by 1
# 2. advance row 1 by 4
# 3. advance row 2 by 6 (triggering update of parent; leapfrog)
#
# 4. advance row 0 by 1 (becoming 2, updating parent; no leapfrog)
# 5. advance row 0 by 4 (becoming 6, updating parent, now with 2 rows @ 6)
# 6. advance row 1 by 2 (all at 6 now)
#
# I'll test both can_advance outputs and introspect into parent
# pointer and yts values at the start, but drop some of that testing
# once it's clear that they're being updated in sync.

# we should be able to add a callback even after object construction
# thanks to Class::Tiny creating accessors
my $read_cb_count = 0;
ok($c->cb_read_bundle(sub { ++$read_cb_count}),
   "Added callback for when parent's read pointer updates");

# 1. advance row 0 by 1
ok (0 == $c->advance_read_substream(0,1), "can advance row 0 by 1");
($rok,$pok,$wok,$subs) = $c->can_advance;

is ($rok, 10, "expect read one substream not to advance parent");
is ($pok, 0,  "expect read one substream not to allow processing");
is ($wok, 0,  "expect read independent of write");
is ($subs->[0], 9, "expect reduced read space in substream");
is ($c->bundle->[0]->{head}, 1, "advanced substream's head variable");
is ($c->yts, 2, "expect read substream to decrement 'yet to start'");

is ($read_cb_count, 0, "expect no read callbacks yet");

eval { $c->advance_read_substream(0,10) };
ok ($@, "expect error advancing substream past window");

# 2. advance row 1 by 4
ok (0 == $c->advance_read_substream(1,4), "can advance row 1 by 4");
($rok,$pok,$wok,$subs) = $c->can_advance;

is ($rok, 10, "expect read two substreams not to advance parent");
is ($pok, 0,  "expect read two substream not to allow processing");
is ($wok, 0,  "expect read still independent of write");
is ($subs->[1], 6, "expect reduced read space in substream");
is ($c->bundle->[1]->{head}, 4, "advanced substream's head variable");
is ($c->yts, 1, "expect read substream to decrement 'yet to start'");

is ($read_cb_count, 0, "expect no read callbacks yet");

# 3. advance row 2 by 6 (triggering update of parent)
ok(1 == $c->advance_read_substream(2,6), "can advance row 2 by 6");
($rok,$pok,$wok,$subs) = $c->can_advance;

is ($rok, 9,  "expect read 3 substreams advance parent by min");
is ($pok, 1,  "expect read 3 substreams to allow processing");
is ($wok, 0,  "expect read still independent of write");
is ($subs->[2], 4, "expect reduced read space in substream");
is ($c->bundle->[2]->{head}, 6, "advanced substream's head variable");
is ($c->bundle->[2]->{tail}, 0, "expect substream's tail unchanged");
is ($c->yts, 1, "expect new 'yet to start': 1 stream at min");

is ($read_cb_count, 1, "expected 1st read callback");

# 4. advance row 0 by 1 (becoming 2, updating parent; no leapfrog)
ok(1 == $c->advance_read_substream(0,1), "can advance row 0 by 1 to 2");
($rok,$pok,$wok,$subs) = $c->can_advance;

is ($rok, 8,  "expect read space reduced by 1 again");
is ($pok, 2,  "expect another column of processing");
is ($subs->[0], 8, "expect reduced read space in substream");
is ($c->bundle->[0]->{head}, 2, "advanced substream's head variable");
is ($c->yts, 1, "expect no other streams at read level 2");

is ($read_cb_count, 2, "expected 2nd read callback");

# 5. advance row 0 by 4 (becoming 6, updating parent, now with 2 rows @ 6)
# (still waiting for stream 1 @ 4 to catch up)
ok(1 == $c->advance_read_substream(0,4), "can advance row 0 by 4 to 6");
($rok,$pok,$wok,$subs) = $c->can_advance;

is ($rok, 6,  "expect min read fill is row 1, with 4 read");
is ($pok, 4,  "expect another 2 columns of processing");
is ($subs->[0], 4, "expect reduced read space in substream");
is ($c->bundle->[0]->{head}, 6, "advanced substream's head variable");
is ($c->yts, 1, "expect waiting on laggard stream 1");

is ($read_cb_count, 3, "expected 3rd read callback");

# 6. advance row 1 by 2 (all at 6 now)
ok(1 == $c->advance_read_substream(1,2), "can advance row 1 by 2 to 6");
($rok,$pok,$wok,$subs) = $c->can_advance;

is ($rok, 4,  "expect all read substreams at 6 reads");
is ($pok, 6,  "expect another 2 columns to process");
is ($c->yts, 3, "expect all streams waiting together");

is ($read_cb_count, 4, "expected 4th read callback");

# Testing write substreams (split) needn't be so comprehensive, but we
# will need to check a few things:
#
# * it's updating the tail/write_tail pointer
# * interactions with processing (also similar for read buffer)
# * that we can advance read_head two windows from write_tail
# * that it's using the correct callback
#
# First, though, testing advance_process using our current combiner
# since it has 6 data columns ready to go.

# Move on one read substream
ok(0 == $c->advance_read_substream(0,2), "can advance row 0 by 2 to 8");

eval { $c->advance_process(7)};
ok ($@, "expect error trying to process 7 columns");

$c->advance_process(2);		# first output
($rok,$pok,$wok,$subs) = $c->can_advance;
is($rok, 6, "expected process(2) to make space for more reads");
is($c->read_head, 6, "expect read head unchanged");
is($c->read_tail, 2, "expect read tail advanced");
is($c->write_head, 2, "expect write_head advanced");
is($wok, 2, "expected process(2) to advance write head");
is ($c->bundle->[0]->{tail}, 2, "advanced combine substream 0's tail");
is ($c->bundle->[1]->{tail}, 2, "advanced combine substream 1's tail");
is ($c->bundle->[2]->{tail}, 2, "advanced combine substream 2's tail");




done_testing;
