#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

my @tests = (
	{
		name => 'Start position',
		perft => [20, 400, 8902, 197281, 4865609, 119060324, 3195901860],
	},
	{
		name => 'Kiwipete',
		fen => 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
		perft => [48, 2039, 97862, 4085603, 193690690],
	},
	{
		name => 'Discovered check',
		fen => '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -',
		perft => [14, 191, 2812, 43238, 674624, 11030083, 178633661, 3009794393],
	},
	{
		name => 'Chessprogramming.org Position 4',
		fen => 'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
		perft => [6, 264, 9467, 422333, 15833292, 706045033],
	},
	{
		name => 'Chessprogramming.org Position 4 Reversed',
		fen => 'r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1',
		perft => [6, 264, 9467, 422333, 15833292, 706045033],
	},
	{
		name => 'Chessprogramming.org Position 5',
		fen => 'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
		perft => [44, 1486, 62379, 2103487, 89941194],
	},
	{
		name => 'Steven Edwards Alternative (chessprogramming.org position 6)',
		fen => 'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10',
		perft => [46, 2079, 89890, 3894594, 164075551],
	},
	{
		name => 'Most Legal Moves (Nenad Petrovic 1964)',
		fen => 'R6R/3Q4/1Q4Q1/4Q3/2Q4Q/Q4Q2/pp1Q4/kBNN1KB1 w - - 1 1',
		perft => [218, 99, 19073, 85043, 13853661, 115892741],
	},
	# http://talkchess.com/forum3/viewtopic.php?f=7&t=77949&p=902361#p902361
	{
		name => 'JVMervino 1',
		fen => 'r3k2r/8/8/8/3pPp2/8/8/R3K1RR b KQkq e3 0 1',
		perft => [29, 829, 20501, 624871, 15446339, 485647607]
	},
	{
		name => 'JVMervino 2',
		fen => 'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
		perft => [6, 264, 9467, 422333, 15833292, 706045033]
	},
	{
		name => 'JVMervino 3',
		fen => '8/7p/p5pb/4k3/P1pPn3/8/P5PP/1rB2RK1 b - d3 0 28',
		perft => [5, 117, 3293, 67197, 1881089, 38633283]
	},
	{
		name => 'JMervino 4',
		fen => '8/3K4/2p5/p2b2r1/5k2/8/8/1q6 b - - 1 67',
		perft => [50, 279, 13310, 54703, 2538084, 10809689, 493407574],
	},
	{
		name => 'JMervino 5',
		fen => 'rnbqkb1r/ppppp1pp/7n/4Pp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3',
		perft => [31, 570, 17546, 351806, 11139762, 244063299],
	},
	{
		name => 'JMervino 6',
		fen => 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -',
		perft => [48, 2039, 97862, 4085603, 193690690],
	},
	{
		name => 'JMervino 7',
		fen => '8/p7/8/1P6/K1k3p1/6P1/7P/8 w - -',
		perft => [5, 39, 237, 2002, 14062, 120995, 966152, 8103790],
	},
	{
		name => 'JMervino 8',
		fen => 'n1n5/PPPk4/8/8/8/8/4Kppp/5N1N b - -',
		perft => [24, 496, 9483, 182838, 3605103, 71179139],
	},
	{
		name => 'JMervino 9',
		fen => 'r3k2r/p6p/8/B7/1pp1p3/3b4/P6P/R3K2R w KQkq -',
		perft => [17, 341, 6666, 150072, 3186478, 77054993],
	},
	{
		name => 'JMervino 10',
		fen => '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -',
		perft => [14, 191, 2812, 43238, 674624, 11030083, 178633661],
	},
	{
		name => 'JMervino 11',
		fen => '8/5p2/8/2k3P1/p3K3/8/1P6/8 b - -',
		perft => [9, 85, 795, 7658, 72120, 703851, 6627106, 64451405],
	},
	{
		name => 'JMervino 12',
		fen => 'r3k2r/pb3p2/5npp/n2p4/1p1PPB2/6P1/P2N1PBP/R3K2R w KQkq -',
		perft => [33, 946, 30962, 899715, 29179893],
	},
);

my $num_tests = 0;
$num_tests += @{$_->{perft}} foreach (@tests);
plan tests => $num_tests;

my $seconds_per_test = $ENV{CP_STRESS_TEST} || 5;
foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	my @perfts = @{$test->{perft}};

	for (my $depth = 1; $depth <= @perfts; ++$depth) {
		no integer;
		SKIP: {
			my $started = [gettimeofday];
			my $got = $pos->perftByUndo($depth);
			my $elapsed = tv_interval($started);
			my $expect = $perfts[$depth - 0.5];
			is $got, $expect, "perft depth $depth ($test->{name})";

			my $nps = $elapsed ? ($got / $elapsed) : 1;
			$nps ||= 100000;
			if ($depth < @perfts) {
				my $next_nodes = $perfts[$depth];
				my $eta = $perfts[$depth] / $nps;
				if ($eta > $seconds_per_test) {
					my $skipped = @perfts - $depth;
					$depth = @perfts;
					skip "set environment variable CP_SECONDS_PER_TEST to a "
						. "value > $seconds_per_test to run more tests",
						$skipped;
				}
			}
		}
	}
}
