package AEPS_TestSuite;

# Shared behavior suite, run against whichever backend
# Algorithm::EventsPerSecond loads. Set ALGORITHM_EVENTSPERSECOND_PP=1
# before loading this module to force the pure Perl backend.

use strict;
use warnings;
use Test::More;

# Mock time() so bucket rotation and rate math are deterministic. The
# override must be installed before Algorithm::EventsPerSecond is compiled.
our $fake_time;

BEGIN {
	$fake_time          = 1_000_000;
	*CORE::GLOBAL::time = sub { $fake_time };
}

use Algorithm::EventsPerSecond;

sub advance { $fake_time += shift }

# deterministic PRNG so failures reproduce identically everywhere
my $lcg_state = 42;

sub _rnd {
	my ($limit) = @_;
	$lcg_state = ( $lcg_state * 1103515245 + 12345 ) % 2147483648;
	return $lcg_state % $limit;
}

sub run_suite {

	#
	# constructor
	#
	{
		my $meter = Algorithm::EventsPerSecond->new;
		isa_ok( $meter, 'Algorithm::EventsPerSecond', 'new with defaults' );
		is( $meter->window, 60, 'default window is 60 seconds' );

		$meter = Algorithm::EventsPerSecond->new( window => 10 );
		is( $meter->window, 10, 'window argument is honored' );

		ok( !eval { Algorithm::EventsPerSecond->new( window =>  0 );    1 }, 'window of 0 dies' );
		ok( !eval { Algorithm::EventsPerSecond->new( window => -5 );    1 }, 'negative window dies' );
		ok( !eval { Algorithm::EventsPerSecond->new( window => 'abc' ); 1 }, 'non-numeric window dies' );
		ok( !eval { Algorithm::EventsPerSecond->new( window => 1.5 );   1 }, 'fractional window dies' );
	}

	#
	# mark, count, total
	#
	{
		my $meter = Algorithm::EventsPerSecond->new( window => 10 );

		is( $meter->count, 0, 'count starts at 0' );
		is( $meter->total, 0, 'total starts at 0' );

		is( $meter->mark,  $meter, 'mark returns the meter object' );
		is( $meter->count, 1,      'count is 1 after one mark' );
		is( $meter->total, 1,      'total is 1 after one mark' );

		$meter->mark(5);
		is( $meter->count, 6, 'mark($count) records multiple events' );
		is( $meter->total, 6, 'total tracks multi-event marks' );

		$meter->mark->mark->mark;
		is( $meter->count, 9, 'mark calls chain' );
	}

	#
	# mark count validation: both backends must reject what they cannot
	# represent identically, so PP and XS never drift apart
	#
	{
		my $meter = Algorithm::EventsPerSecond->new( window => 10 );
		$meter->mark(2);

		ok( !eval { $meter->mark(-3);    1 }, 'negative count dies' );
		ok( !eval { $meter->mark(2.5);   1 }, 'fractional count dies' );
		ok( !eval { $meter->mark('abc'); 1 }, 'non-numeric count dies' );
		ok( !eval { $meter->mark('');    1 }, 'empty-string count dies' );

		is( $meter->count, 2,             'rejected marks do not change count' );
		is( $meter->total, 2,             'rejected marks do not change total' );
		is( $meter->count, $meter->total, 'count and total agree after rejected marks' );

		is( $meter->mark(0), $meter, 'mark(0) is accepted and returns the meter object' );
		is( $meter->count,   2,      'mark(0) is a no-op for count' );
		is( $meter->total,   2,      'mark(0) is a no-op for total' );
	}

	#
	# events spread across seconds, then falling out of the window
	#
	{
		my $meter = Algorithm::EventsPerSecond->new( window => 5 );

		$meter->mark(2);    # second 0
		advance(1);
		$meter->mark(3);    # second 1
		advance(1);
		$meter->mark(4);    # second 2

		is( $meter->count, 9, 'count sums events across seconds in the window' );
		is( $meter->total, 9, 'total matches while all events are in the window' );

		# now at second 2; window of 5 covers seconds -2..2, so nothing has
		# expired yet. Advance to second 5: window covers 1..5, dropping the
		# 2 events from second 0.
		advance(3);
		is( $meter->count, 7, 'events older than the window are excluded' );

		# advance well past the window: everything expires
		advance(10);
		is( $meter->count, 0, 'count is 0 once all events age out' );
		is( $meter->total, 9, 'total is unaffected by expiry' );
	}

	#
	# ring buffer reuse: marks a full window apart land in the same bucket
	# and must not be double counted
	#
	{
		my $meter = Algorithm::EventsPerSecond->new( window => 3 );

		$meter->mark(5);
		advance(3);    # same bucket index, new second
		$meter->mark(2);

		is( $meter->count, 2, 'stale bucket is cleared before reuse' );
		is( $meter->total, 7, 'total still counts events from cleared buckets' );
	}

	#
	# window of 1: smallest ring buffer
	#
	{
		my $meter = Algorithm::EventsPerSecond->new( window => 1 );

		$meter->mark(3)->mark(4);
		is( $meter->count, 7, 'window of 1 counts the current second' );
		advance(1);
		is( $meter->count, 0, 'window of 1 expires after one second' );
	}

	#
	# rate
	#
	{
		my $meter = Algorithm::EventsPerSecond->new( window => 10 );

		is( $meter->rate, 0, 'rate is 0 when no time has elapsed' );

		$meter->mark(10);
		advance(5);
		is( $meter->rate, 2, 'rate uses elapsed lifetime while younger than the window' );

		advance(15);    # lifetime 20s > window; only recent events count
		$meter->mark(30);
		is( $meter->rate, 3, 'rate averages over the full window once mature' );
	}

	#
	# reset
	#
	{
		my $meter = Algorithm::EventsPerSecond->new( window => 10 );

		$meter->mark(4);
		advance(2);
		$meter->mark(6);

		is( $meter->reset, $meter, 'reset returns the meter object' );
		is( $meter->count, 0,      'count is 0 after reset' );
		is( $meter->total, 0,      'total is 0 after reset' );
		is( $meter->rate,  0,      'rate is 0 after reset' );

		advance(4);
		$meter->mark(8);
		is( $meter->count, 8, 'meter is usable after reset' );
		is( $meter->rate,  2, 'rate clock restarts at reset' );
	}

	#
	# clock stepping backwards (an NTP step): must not crash, must not
	# produce negative readings, and must count correctly once the
	# clock recovers
	#
	{
		my $meter = Algorithm::EventsPerSecond->new( window => 5 );

		$meter->mark(3);
		advance(-11);       # -11 is not a multiple of the window, so this
		$meter->mark(2);    # mark lands in a different bucket than the one above

		ok( $meter->count >= 0, 'count is non-negative after the clock steps back' );
		is( $meter->total, 5, 'total is unaffected by the clock stepping back' );
		is( $meter->rate,  0, 'rate reads 0 while the clock is behind the start time' );

		advance(13);        # two seconds past where the clock originally was
		$meter->mark(4);
		is( $meter->count, 7, 'only in-window events counted once the clock recovers' );
		is( $meter->total, 9, 'total tracks marks made at every clock position' );

		advance(10);
		is( $meter->count, 0, 'everything ages out normally after recovery' );
		is( $meter->total, 9, 'total survives the aging out' );
	}

	#
	# randomized cross-check against an independent reference model.
	# Window sizes chosen to exercise the SIMD main loop, its scalar
	# tail, and tail-only runs (AVX2 does 4 buckets a step, SSE4.2 2);
	# 257 and 1024 add long main-loop runs on odd and even boundaries.
	#
	for my $window ( 1, 2, 3, 5, 8, 16, 33, 64, 257, 1024 ) {
		my $meter = Algorithm::EventsPerSecond->new( window => $window );
		my %events;    # second => count, the reference model
		my $total = 0;
		my $bad   = 0;

		for ( 1 .. 200 ) {
			advance( _rnd(4) );    # 0-3 seconds pass
			my $n = _rnd(5);       # 0-4 events
			if ($n) {
				$meter->mark($n);
				$events{$fake_time} += $n;
				$total += $n;
			}

			my $oldest   = $fake_time - $window + 1;
			my $expected = 0;
			for my $sec ( keys %events ) {
				$expected += $events{$sec} if $sec >= $oldest;
			}

			$bad++ if $meter->count != $expected;
			$bad++ if $meter->total != $total;
		} ## end for ( 1 .. 200 )

		is( $bad, 0, "randomized marks match reference model (window $window)" );
	} ## end for my $window ( 1, 2, 3, 5, 8, 16, 33, 64,...)

	return;
} ## end sub run_suite

1;
