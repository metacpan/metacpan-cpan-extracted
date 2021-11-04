#! /usr/bin/env perl

# Copyright (C) 2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More;
use Chess::Plisco::Engine::Position;

my @tests = (
	{
		name => 'initial position',
	},
	{
		name => 'after 1. e4',
		fen => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
	},
	{
		name => 'white superior, white on move',
		fen => '4k3/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQ - 0 1',
	},
	{
		name => 'white superior, black on move',
		fen => '4k3/8/8/8/8/8/PPPPPPPP/RNBQKBNR b KQ - 0 1',
	},
	{
		name => 'black superior, black on move',
		fen => 'rnbqkbnr/pppppppp/8/8/8/8/8/4K3 b kq - 0 1',
	},
	{
		name => 'black superior, white on move',
		fen => 'rnbqkbnr/pppppppp/8/8/8/8/8/4K3 w kq - 0 1',
	},
	{
		name => 'Billy68',
		fen => '6nr/p5pk/p3p2p/5P2/3BQ2q/5P1N/6KP/1R6 b - - 0 28',
	},
	{
		name => 'Billy68 2',
		fen => 'Q5nr/p4pp1/p3pk1p/2B5/6Pq/5P1N/6KP/1b5R w - - 0 25',
	}
);

# This is the PeSTO evaluation function as seen on
# https://www.chessprogramming.org/PeSTO%27s_Evaluation_Function ported to
# Perl using their board structure and constants.
use constant PAWN => 0;
use constant KNIGHT => 1;
use constant BISHOP => 2;
use constant ROOK => 3;
use constant QUEEN => 4;
use constant KING => 5;

# board representation
use constant WHITE => 0;
use constant BLACK => 1;

use constant WHITE_PAWN => (2 * PAWN + WHITE);
use constant BLACK_PAWN => (2 * PAWN + BLACK);
use constant WHITE_KNIGHT => (2 * KNIGHT + WHITE);
use constant BLACK_KNIGHT => (2 * KNIGHT + BLACK);
use constant WHITE_BISHOP => (2 * BISHOP + WHITE);
use constant BLACK_BISHOP => (2 * BISHOP + BLACK);
use constant WHITE_ROOK => (2 * ROOK + WHITE);
use constant BLACK_ROOK => (2 * ROOK + BLACK);
use constant WHITE_QUEEN => (2 * QUEEN + WHITE);
use constant BLACK_QUEEN => (2 * QUEEN + BLACK);
use constant WHITE_KING => (2 * KING + WHITE);
use constant BLACK_KING => (2 * KING + BLACK);
use constant EMPTY => (BLACK_KING + 1);

sub parse_fen;

sub PCOLOR {
	my ($p) = @_;
	$p & 1;
}

my $side2move = WHITE;
my @start_position = (
	BLACK_ROOK, BLACK_KNIGHT, BLACK_BISHOP, BLACK_QUEEN, BLACK_KING, BLACK_BISHOP, BLACK_KNIGHT, BLACK_ROOK,
	BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN,
	EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY,
	EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY,
	EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY,
	EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY,
	WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN,
	WHITE_ROOK, WHITE_KNIGHT, WHITE_BISHOP, WHITE_QUEEN, WHITE_KING, WHITE_BISHOP, WHITE_KNIGHT, WHITE_ROOK,
);
my @board = @start_position;

sub FLIP {
	shift ^ 56;
}

sub OTHER {
	shift ^ 1;
}

my @mg_value = ( 82, 337, 365, 477, 1025, 0);
my @eg_value = ( 94, 281, 297, 512, 936, 0);

# piece/sq tables
# values from Rofchade: http://www.talkchess.com/forum3/viewtopic.php?f=2&t=68311&start=19

my @mg_pawn_table = (
	  0,   0,   0,   0,   0,   0,  0,   0,
	 98, 134,  61,  95,  68, 126, 34, -11,
	 -6,   7,  26,  31,  65,  56, 25, -20,
	-14,  13,   6,  21,  23,  12, 17, -23,
	-27,  -2,  -5,  12,  17,   6, 10, -25,
	-26,  -4,  -4, -10,   3,   3, 33, -12,
	-35,  -1, -20, -23, -15,  24, 38, -22,
	  0,   0,   0,   0,   0,   0,  0,   0,
);

my @eg_pawn_table = (
	  0,   0,   0,   0,   0,   0,   0,   0,
	178, 173, 158, 134, 147, 132, 165, 187,
	 94, 100,  85,  67,  56,  53,  82,  84,
	 32,  24,  13,   5,  -2,   4,  17,  17,
	 13,   9,  -3,  -7,  -7,  -8,   3,  -1,
	  4,   7,  -6,   1,   0,  -5,  -1,  -8,
	 13,   8,   8,  10,  13,   0,   2,  -7,
	  0,   0,   0,   0,   0,   0,   0,   0,
);

my @mg_knight_table = (
	-167, -89, -34, -49,  61, -97, -15, -107,
	 -73, -41,  72,  36,  23,  62,   7,  -17,
	 -47,  60,  37,  65,  84, 129,  73,   44,
	  -9,  17,  19,  53,  37,  69,  18,   22,
	 -13,   4,  16,  13,  28,  19,  21,   -8,
	 -23,  -9,  12,  10,  19,  17,  25,  -16,
	 -29, -53, -12,  -3,  -1,  18, -14,  -19,
	-105, -21, -58, -33, -17, -28, -19,  -23,
);

my @eg_knight_table = (
	-58, -38, -13, -28, -31, -27, -63, -99,
	-25,  -8, -25,  -2,  -9, -25, -24, -52,
	-24, -20,  10,   9,  -1,  -9, -19, -41,
	-17,   3,  22,  22,  22,  11,   8, -18,
	-18,  -6,  16,  25,  16,  17,   4, -18,
	-23,  -3,  -1,  15,  10,  -3, -20, -22,
	-42, -20, -10,  -5,  -2, -20, -23, -44,
	-29, -51, -23, -15, -22, -18, -50, -64,
);

my @mg_bishop_table = (
	-29,   4, -82, -37, -25, -42,   7,  -8,
	-26,  16, -18, -13,  30,  59,  18, -47,
	-16,  37,  43,  40,  35,  50,  37,  -2,
	 -4,   5,  19,  50,  37,  37,   7,  -2,
	 -6,  13,  13,  26,  34,  12,  10,   4,
	  0,  15,  15,  15,  14,  27,  18,  10,
	  4,  15,  16,   0,   7,  21,  33,   1,
	-33,  -3, -14, -21, -13, -12, -39, -21,
);

my @eg_bishop_table = (
	-14, -21, -11,  -8, -7,  -9, -17, -24,
	 -8,  -4,   7, -12, -3, -13,  -4, -14,
	  2,  -8,   0,  -1, -2,   6,   0,   4,
	 -3,   9,  12,   9, 14,  10,   3,   2,
	 -6,   3,  13,  19,  7,  10,  -3,  -9,
	-12,  -3,   8,  10, 13,   3,  -7, -15,
	-14, -18,  -7,  -1,  4,  -9, -15, -27,
	-23,  -9, -23,  -5, -9, -16,  -5, -17,
);

my @mg_rook_table = (
     32,  42,  32,  51, 63,  9,  31,  43,
     27,  32,  58,  62, 80, 67,  26,  44,
     -5,  19,  26,  36, 17, 45,  61,  16,
    -24, -11,   7,  26, 24, 35,  -8, -20,
    -36, -26, -12,  -1,  9, -7,   6, -23,
    -45, -25, -16, -17,  3,  0,  -5, -33,
    -44, -16, -20,  -9, -1, 11,  -6, -71,
    -19, -13,   1,  17, 16,  7, -37, -26,
);

my @eg_rook_table = (
	13, 10, 18, 15, 12,  12,   8,   5,
	11, 13, 13, 11, -3,   3,   8,   3,
	 7,  7,  7,  5,  4,  -3,  -5,  -3,
	 4,  3, 13,  1,  2,   1,  -1,   2,
	 3,  5,  8,  4, -5,  -6,  -8, -11,
	-4,  0, -5, -1, -7, -12,  -8, -16,
	-6, -6,  0,  2, -9,  -9, -11,  -3,
	-9,  2,  3, -1, -5, -13,   4, -20,
);

my @mg_queen_table = (
	-28,   0,  29,  12,  59,  44,  43,  45,
	-24, -39,  -5,   1, -16,  57,  28,  54,
	-13, -17,   7,   8,  29,  56,  47,  57,
	-27, -27, -16, -16,  -1,  17,  -2,   1,
	 -9, -26,  -9, -10,  -2,  -4,   3,  -3,
	-14,   2, -11,  -2,  -5,   2,  14,   5,
	-35,  -8,  11,   2,   8,  15,  -3,   1,
	 -1, -18,  -9,  10, -15, -25, -31, -50,
);

my @eg_queen_table = (
	 -9,  22,  22,  27,  27,  19,  10,  20,
	-17,  20,  32,  41,  58,  25,  30,   0,
	-20,   6,   9,  49,  47,  35,  19,   9,
	  3,  22,  24,  45,  57,  40,  57,  36,
	-18,  28,  19,  47,  31,  34,  39,  23,
	-16, -27,  15,   6,   9,  17,  10,   5,
	-22, -23, -30, -16, -16, -23, -36, -32,
	-33, -28, -22, -43,  -5, -32, -20, -41,
);

my @mg_king_table = (
	-65,  23,  16, -15, -56, -34,   2,  13,
	 29,  -1, -20,  -7,  -8,  -4, -38, -29,
	 -9,  24,   2, -16, -20,   6,  22, -22,
	-17, -20, -12, -27, -30, -25, -14, -36,
	-49,  -1, -27, -39, -46, -44, -33, -51,
	-14, -14, -22, -46, -44, -30, -15, -27,
	  1,   7,  -8, -64, -43, -16,   9,   8,
	-15,  36,  12, -54,   8, -28,  24,  14,
);

my @eg_king_table = (
	-74, -35, -18, -18, -11,  15,   4, -17,
	-12,  17,  14,  17,  17,  38,  23,  11,
	 10,  17,  23,  15,  20,  45,  44,  13,
	 -8,  22,  24,  27,  26,  33,  26,   3,
	-18,  -4,  21,  24,  27,  23,   9, -11,
	-19,  -3,  11,  21,  23,  16,   7,  -9,
	-27, -11,   4,  13,  14,   4,  -5, -17,
	-53, -34, -21, -11, -28, -14, -24, -43
);

my @mg_pesto_table = (
	\@mg_pawn_table,
	\@mg_knight_table,
	\@mg_bishop_table,
	\@mg_rook_table,
	\@mg_queen_table,
	\@mg_king_table
);

my @eg_pesto_table = (
	\@eg_pawn_table,
	\@eg_knight_table,
	\@eg_bishop_table,
	\@eg_rook_table,
	\@eg_queen_table,
	\@eg_king_table
);

my @gamephaseInc = (0, 0, 1, 1, 1, 1, 2, 2, 4, 4, 0, 0);
my @mg_table;
my @eg_table;

# Init tables.
my ($p, $pc);
for ($p = PAWN, $pc = WHITE_PAWN; $p <= KING; $pc += 2, ++$p) {
	for (my $sq = 0; $sq < 64; ++$sq) {
		$mg_table[$pc]->[$sq] = $mg_value[$p] + $mg_pesto_table[$p]->[$sq];
		$eg_table[$pc]->[$sq] = $eg_value[$p] + $eg_pesto_table[$p]->[$sq];
		$mg_table[$pc + 1]->[$sq] = $mg_value[$p] + $mg_pesto_table[$p]->[FLIP($sq)];
		$eg_table[$pc + 1]->[$sq] = $eg_value[$p] + $eg_pesto_table[$p]->[FLIP($sq)];
	}
}

sub evaluate {
	my @mg;
	my @eg;
	my $gamePhase = 0;

	$mg[WHITE] = 0;
	$mg[BLACK] = 0;
	$eg[WHITE] = 0;
	$eg[BLACK] = 0;

	# evaluate each piece */
	for (my $sq = 0; $sq < 64; ++$sq) {
		my $pc = $board[$sq];
		if ($pc != EMPTY) {
			$mg[PCOLOR($pc)] += $mg_table[$pc]->[$sq];
			$eg[PCOLOR($pc)] += $eg_table[$pc]->[$sq];
			$gamePhase += $gamephaseInc[$pc];
		}
	}

	# tapered eval
	my $mgScore = $mg[$side2move] - $mg[OTHER($side2move)];
	my $egScore = $eg[$side2move] - $eg[OTHER($side2move)];
	my $mgPhase = $gamePhase;
	$mgPhase = 24 if $mgPhase > 24; # in case of early promotion.
	my $egPhase = 24 - $mgPhase;

	my $score = ($mgScore * $mgPhase + $egScore * $egPhase) / 24;

	return $score;
}
# End of original PeSTO evaluation function.

sub parse_fen {
	my ($fen) = @_;

	my ($pieces, $color, $castling, $ep_square, $hmc, $moveno)
			= split /[ \t]+/, $fen;

	if (!(defined $pieces && defined $color && defined $castling)) {
		die "Illegal FEN: Incomplete.\n";
	}

	@board = (EMPTY) x 64;
	my $shift = 0;
	my @chars = split //, $pieces;
	foreach my $char (@chars) {
		if ($shift >= 64) {
			die "illegal FEN";
		}
		if ('P' eq $char) {
			$board[$shift++] = WHITE_PAWN;
		} elsif ('p' eq $char) {
			$board[$shift++] = BLACK_PAWN;
		} elsif ('N' eq $char) {
			$board[$shift++] = WHITE_KNIGHT;
		} elsif ('n' eq $char) {
			$board[$shift++] = BLACK_KNIGHT;
		} elsif ('B' eq $char) {
			$board[$shift++] = WHITE_BISHOP;
		} elsif ('b' eq $char) {
			$board[$shift++] = BLACK_BISHOP;
		} elsif ('R' eq $char) {
			$board[$shift++] = WHITE_ROOK;
		} elsif ('r' eq $char) {
			$board[$shift++] = BLACK_ROOK;
		} elsif ('Q' eq $char) {
			$board[$shift++] = WHITE_QUEEN;
		} elsif ('q' eq $char) {
			$board[$shift++] = BLACK_QUEEN;
		} elsif ('K' eq $char) {
			$board[$shift++] = WHITE_KING;
		} elsif ('k' eq $char) {
			$board[$shift++] = BLACK_KING;
		} elsif ($char =~ /^[1-8]$/) {
			$shift += $char;
		} elsif ('/' eq $char) {
			# do nothing.
		} else {
			die "Illegal FEN: Illegal piece/number '$char'.\n";
		}
	}

	if ('w' eq lc $color) {
		$side2move = WHITE;
	} elsif ('b' eq lc $color) {
		$side2move = BLACK;
	} else {
		die "Illegal FEN: Side to move is neither 'w' nor 'b'.\n";
	}
}

plan tests => scalar @tests;

foreach my $test (@tests) {
	if ($test->{fen}) {
		parse_fen $test->{fen};
	} else {
		@board = @start_position;
	}

	my $position = Chess::Plisco::Engine::Position->new($test->{fen});
	is $position->evaluate, evaluate, "$test->{name}";
}