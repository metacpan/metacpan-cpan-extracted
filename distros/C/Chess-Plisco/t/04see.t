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
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

my ($pos, @moves, @expect);

my @tests = (
	# Test positions from Arasan (https://github.com/jdart1/arasan-chess).
	[
		"4R3/2r3p1/5bk1/1p1r3p/p2PR1P1/P1BK1P2/1P6/8 b - - 0 1",
		"hxg4",
		0,
		__FILE__, __LINE__ - 3
	],
	[
		"4R3/2r3p1/5bk1/1p1r1p1p/p2PR1P1/P1BK1P2/1P6/8 b - -",
		"hxg4",
		0,
		__FILE__, __LINE__ - 3
	],
	[
		"4r1k1/5pp1/nbp4p/1p2p2q/1P2P1b1/1BP2N1P/1B2QPPK/3R4 b - -",
		"Bxf3",
		CP_KNIGHT_VALUE - CP_BISHOP_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"2r1r1k1/pp1bppbp/3p1np1/q3P3/2P2P2/1P2B3/P1N1B1PP/2RQ1RK1 b - -",
		"dxe5",
		CP_PAWN_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"7r/5qpk/p1Qp1b1p/3r3n/BB3p2/5p2/P1P2P2/4RK1R w - -",
		"Re8",
		0,
		__FILE__, __LINE__ - 3
	],
	[
		"6rr/6pk/p1Qp1b1p/2n5/1B3p2/5p2/P1P2P2/4RK1R w - -",
		"Re8",
		-CP_ROOK_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"7r/5qpk/2Qp1b1p/1N1r3n/BB3p2/5p2/P1P2P2/4RK1R w - -",
		"Re8",
		-CP_ROOK_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"6RR/4bP2/8/8/5r2/3K4/5p2/4k3 w - -",
		"f8=Q",
		CP_BISHOP_VALUE - CP_PAWN_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"6RR/4bP2/8/8/5r2/3K4/5p2/4k3 w - -",
		"f8=N",
		CP_KNIGHT_VALUE - CP_PAWN_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		# Moved the rook so that the white king is not in chess.
		"7R/5P2/8/8/6r1/3K4/5p2/4k3 w - - 0 1",
		"f8=Q",
		CP_QUEEN_VALUE - CP_PAWN_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		# Moved the rook so that the white king is not in chess.
		"7R/5P2/8/8/6r1/3K4/5p2/4k3 w - - 0 1",
		"f8=B",
		CP_BISHOP_VALUE - CP_PAWN_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"7R/4bP2/8/8/1q6/3K4/5p2/4k3 w - -",
		"f8=R",
		-CP_PAWN_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"8/4kp2/2npp3/1Nn5/1p2PQP1/7q/1PP1B3/4KR1r b - -",
		"Rxf1+",
		0,
		__FILE__, __LINE__ - 3
	],
	[
		"8/4kp2/2npp3/1Nn5/1p2P1P1/7q/1PP1B3/4KR1r b - -",
		"Rxf1+",
		0,
		__FILE__, __LINE__ - 3
	],
	[
		"2r2r1k/6bp/p7/2q2p1Q/3PpP2/1B6/P5PP/2RR3K b - -",
		"Qxc1",
		2 * CP_ROOK_VALUE - CP_QUEEN_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"r2qk1nr/pp2ppbp/2b3p1/2p1p3/8/2N2N2/PPPP1PPP/R1BQR1K1 w kq -",
		"Nxe5",
		CP_PAWN_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"6r1/4kq2/b2p1p2/p1pPb3/p1P2B1Q/2P4P/2B1R1P1/6K1 w - -",
		"Bxe5",
		0,
		__FILE__, __LINE__ - 3
	],
	[
		"3q2nk/pb1r1p2/np6/3P2Pp/2p1P3/2R4B/PQ3P1P/3R2K1 w - h6",
		"gxh6",
		0,
		__FILE__, __LINE__ - 3
	],
	[
		"3q2nk/pb1r1p2/np6/3P2Pp/2p1P3/2R1B2B/PQ3P1P/3R2K1 w - h6",
		"gxh6",
		CP_PAWN_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"2r4r/1P4pk/p2p1b1p/7n/BB3p2/2R2p2/P1P2P2/4RK2 w - -",
		"Rxc8",
		CP_ROOK_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"2r5/1P4pk/p2p1b1p/5b1n/BB3p2/2R2p2/P1P2P2/4RK2 w - -",
		"Rxc8",
		CP_BISHOP_VALUE,  # Was originally CP_ROOK_VALUE.
		__FILE__, __LINE__ - 3
	],
	[
		"2r4k/2r4p/p7/2b2p1b/4pP2/1BR5/P1R3PP/2Q4K w - -",
		"Rxc5",
		CP_BISHOP_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"8/pp6/2pkp3/4bp2/2R3b1/2P5/PP4B1/1K6 w - -",
		"Bxc6",
		CP_PAWN_VALUE - CP_BISHOP_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"4q3/1p1pr1k1/1B2rp2/6p1/p3PP2/P3R1P1/1P2R1K1/4Q3 b - -",
		"Rxe4",
		CP_PAWN_VALUE - CP_ROOK_VALUE,
		__FILE__, __LINE__ - 3
	],
	[
		"4q3/1p1pr1kb/1B2rp2/6p1/p3PP2/P3R1P1/1P2R1K1/4Q3 b - -",
		"Bxe4",
		CP_PAWN_VALUE,
		__FILE__, __LINE__ - 3
	],
);

plan tests => 3 * @tests;

foreach my $test (@tests) {
	my ($fen, $san, $expect, $file, $line) = @$test;
	my $position = Chess::Plisco->new($fen);
	ok $fen, "$file:$line: new $fen";

	my $move = $position->parseMove($san);
	ok $move, "$file:$line: parseMove($san) @ $fen";

	is $position->SEE($move), $expect, "$file:$line: SEE $san @ $fen";
}
