#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::Position;
$Chess::Plisco::Engine::Position::VERSION = 'v0.7.0';
use strict;
use integer;

use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!
use Chess::Plisco::Engine::Tree;

use base qw(Chess::Plisco);

use constant CP_POS_GAME_PHASE => 14;
use constant CP_POS_OPENING_SCORE => 15;
use constant CP_POS_ENDGAME_SCORE => 16;

use constant PAWN_PHASE => 0;
use constant KNIGHT_PHASE => 1;
use constant BISHOP_PHASE => 1;
use constant ROOK_PHASE => 2;
use constant QUEEN_PHASE => 4;
use constant TOTAL_PHASE => PAWN_PHASE * 16
	+ KNIGHT_PHASE * 4 + BISHOP_PHASE * 4
	+ ROOK_PHASE * 4 + QUEEN_PHASE * 2;
use constant PHASE_INC => [
	0,
	PAWN_PHASE,
	KNIGHT_PHASE,
	BISHOP_PHASE,
	ROOK_PHASE,
	QUEEN_PHASE,
	0,
];


my @op_value = (0, 82, 337, 365, 477, 1025, 0);
my @eg_value = (0, 94, 281, 297, 512, 936, 0);

# piece/sq tables
# values from Rofchade: http://www.talkchess.com/forum3/viewtopic.php?f=2&t=68311&start=19

my @op_pawn_table = (
	  0,   0,   0,   0,   0,   0,  0,   0,
	 98, 134,  61,  95,  68, 126, 34, -11,
	 -6,   7,  26,  31,  65,  56, 25, -20,
	-14,  13,   6,  21,  23,  12, 17, -23,
	-27,  -2,  -5,  12,  17,   6, 10, -25,
	-26,  -4,  -4, -10,   3,   3, 33, -12,
	# 47, 81, 62, 59, 67, 106, 120, 60
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

my @op_knight_table = (
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

my @op_bishop_table = (
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

my @op_rook_table = (
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

my @op_queen_table = (
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

my @op_king_table = (
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

my @op_pesto_table = (
	undef,
	\@op_pawn_table,
	\@op_knight_table,
	\@op_bishop_table,
	\@op_rook_table,
	\@op_queen_table,
	\@op_king_table
);

my @eg_pesto_table = (
	undef,
	\@eg_pawn_table,
	\@eg_knight_table,
	\@eg_bishop_table,
	\@eg_rook_table,
	\@eg_queen_table,
	\@eg_king_table
);

my @op_table;
my @eg_table;

# Init tables.
for (my $piece = CP_PAWN; $piece <= CP_KING; ++$piece) {
	for (my $shift = 0; $shift < 64; ++$shift) {
		my $windex = (CP_WHITE << 9) | ($piece << 6) | $shift;
		my $bindex = (CP_BLACK << 9) | ($piece << 6) | $shift;
		$op_table[$windex] = $op_value[$piece] + $op_pesto_table[$piece]->[$shift ^ 56];
		$eg_table[$windex] = $eg_value[$piece] + $eg_pesto_table[$piece]->[$shift ^ 56];
		$op_table[$bindex] = $op_value[$piece] + $op_pesto_table[$piece]->[$shift];
		$eg_table[$bindex] = $eg_value[$piece] + $eg_pesto_table[$piece]->[$shift];
	}
}

my @pieces = (' ', 'P', 'N', 'B', 'R', 'Q', 'K');
for (my $i = 0; $i < @op_table; ++$i) {
	my $op_score = $op_table[$i];
	next if !defined $op_score;
	my $eg_score = $eg_table[$i];
	my $shift = $i & 0x3f;
	my $piece = ($i >> 6) & 0x7;
	my $color = ($i >> 9);
	my $piece_char = $pieces[$piece];
	$piece_char = lc $piece_char if $color;
	my $square = Chess::Plisco->shiftToSquare($shift);
}

# For all combinations of victim and promotion piece, calculate the change in
# game phase.  These values are positive and meant to be added to the phase;
my @move_phase_deltas = (0) x 369;
foreach my $victim (CP_NO_PIECE, CP_PAWN .. CP_QUEEN) {
	foreach my $promote (CP_NO_PIECE, CP_KNIGHT .. CP_QUEEN) {
		next if $promote && $victim == CP_PAWN;
		next if !$victim && !$promote;
		my $delta = -PHASE_INC->[$victim];
		if ($promote) {
			$delta -= (Chess::Plisco::Engine::Position::PAWN_PHASE
				- PHASE_INC->[$promote]);
		}
		$move_phase_deltas[($victim << 3) | $promote] = $delta;
	}
}

# Lookup tables for the resulting opening and endgame scores for each
# possible move.
my @opening_deltas;
my @endgame_deltas;

foreach my $move (Chess::Plisco->moveNumbers) {
	my $is_ep;
	my $color = 1 & ($move >> 21);
	my $captured = 0x7 & ($move >> 18);
	if ($captured == CP_KING) {
		$captured = CP_PAWN;
		$is_ep = 1;
	}
	my ($to, $from, $promote, $piece) = (
		Chess::Plisco->moveTo($move),
		Chess::Plisco->moveFrom($move),
		Chess::Plisco->movePromote($move),
		Chess::Plisco->movePiece($move),
	);

	my $from_index = ($color << 9) | ($piece << 6) | $from;
	my $to_index = ($color << 9) | ($piece << 6) | $to;
	my $opening_delta = $op_table[$from_index] - $op_table[$to_index];
	my $endgame_delta = $eg_table[$from_index] - $eg_table[$to_index];
	if ($is_ep) {
		my $ep_to;
		if ($color == CP_WHITE) {
			$ep_to = $to - 8;
		} else {
			$ep_to = $to + 8;
		}
		my $ep_index = ($color << 9) | (CP_PAWN) << 6 | $ep_to;
		$opening_delta -= $op_table[$ep_index];
		$endgame_delta -= $eg_table[$ep_index];
	} elsif ($captured) {
		# The captured piece must be viewed from the other side.
		my $captured_index = ((!$color) << 9) | ($captured << 6) | $to;
		$opening_delta -= $op_table[$captured_index];
		$endgame_delta -= $eg_table[$captured_index];
	}

	if ($promote) {
		my $promote_index = ($color << 9) | ($promote << 6) | $to;
		my $promote_pawn_index = ($color << 9) | (CP_PAWN << 6) | $to;
		$opening_delta -= $op_table[$promote_index]
			- $op_table[$promote_pawn_index];
		$endgame_delta -= $eg_table[$promote_index]
			- $eg_table[$promote_pawn_index];
	}

	# Handle castlings.
	if (CP_KING == $piece && CP_E8 == $from) {
		if (CP_C8 == $to) {
			my $rook_a8_index = (CP_BLACK << 9) | (CP_ROOK << 6) | CP_A8;
			my $rook_d8_index = (CP_BLACK << 9) | (CP_ROOK << 6) | CP_D8;
			$opening_delta -= $op_table[$rook_d8_index]
				- $op_table[$rook_a8_index];
			$endgame_delta -= $eg_table[$rook_d8_index]
				- $eg_table[$rook_a8_index];
		} elsif (CP_G8 == $to) {
			my $rook_h8_index = (CP_BLACK << 9) | (CP_ROOK << 6) | CP_H8;
			my $rook_f8_index = (CP_BLACK << 9) | (CP_ROOK << 6) | CP_F8;
			$opening_delta -= $op_table[$rook_f8_index]
				- $op_table[$rook_h8_index];
			$endgame_delta -= $eg_table[$rook_f8_index]
				- $eg_table[$rook_h8_index];
		}
	} elsif (CP_KING == $piece && CP_E1 == $from) {
		if (CP_C1 == $to) {
			my $rook_a1_index = (CP_WHITE << 9) | (CP_ROOK << 6) | CP_A1;
			my $rook_d1_index = (CP_WHITE << 9) | (CP_ROOK << 6) | CP_D1;
			$opening_delta -= $op_table[$rook_d1_index]
				- $op_table[$rook_a1_index];
			$endgame_delta -= $eg_table[$rook_d1_index]
				- $eg_table[$rook_a1_index];
		} elsif (CP_G1 == $to) {
			my $rook_h1_index = (CP_WHITE << 9) | (CP_ROOK << 6) | CP_H1;
			my $rook_f1_index = (CP_WHITE << 9) | (CP_ROOK << 6) | CP_F1;
			$opening_delta -= $op_table[$rook_f1_index]
				- $op_table[$rook_h1_index];
			$endgame_delta -= $eg_table[$rook_f1_index]
				- $eg_table[$rook_h1_index];
		}
	}

	$opening_deltas[$move] = $color ? $opening_delta : -$opening_delta;
	$endgame_deltas[$move] = $color ? $endgame_delta : -$endgame_delta;
}



sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);

	my $op_phase = 0;
	my $op_score = 0;
	my $eg_score = 0;
	my $white = $self->[CP_POS_WHITE_PIECES];
	my $black = $self->[CP_POS_BLACK_PIECES];

	foreach my $piece (CP_PAWN .. CP_KING) {
		my $pieces = $self->[$piece];
		my $white_pieces = $pieces & $white;
		my $black_pieces = $pieces & $black;
		my $phase_inc = PHASE_INC->[$piece];
		while ($white_pieces) {
			my $shift = (do {	my $B = $white_pieces & -$white_pieces;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
			my $idx = (CP_WHITE << 9) | ($piece << 6) | $shift;
			$op_score += $op_table[$idx];
			$eg_score += $eg_table[$idx];
			$white_pieces = (($white_pieces) & (($white_pieces) - 1));
			$op_phase += $phase_inc;
		}
		while ($black_pieces) {
			my $shift = (do {	my $B = $black_pieces & -$black_pieces;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
			my $idx = (CP_BLACK << 9) | ($piece << 6) | $shift;
			$op_score -= $op_table[$idx];
			$eg_score -= $eg_table[$idx];
			$black_pieces = (($black_pieces) & (($black_pieces) - 1));
			$op_phase += $phase_inc;
		}
	}

	$self->[CP_POS_OPENING_SCORE] = $op_score;
	$self->[CP_POS_ENDGAME_SCORE] = $eg_score;

	$self->[CP_POS_GAME_PHASE] = $op_phase;

	return $self;
}

sub doMove {
	my ($self, $move) = @_;

	my $state = $self->SUPER::doMove($move) or return;
	($move) = @$state;
	$self->[CP_POS_GAME_PHASE] += $move_phase_deltas[
		((($move >> 18) & 0x7) << 3) | (($move >> 12) & 0x7)
	];
	my $score_index = ($move & 0x1fffff) | (!(((($self->[CP_POS_INFO] & (1 << 4)) >> 4))) << 21);
	$self->[CP_POS_OPENING_SCORE] += $opening_deltas[$score_index];
	$self->[CP_POS_ENDGAME_SCORE] += $endgame_deltas[$score_index];

	return $state;
}

sub evaluate {
	my ($self) = @_;

	my $material = (($self->[CP_POS_INFO] >> 19));
	my $white_pieces = $self->[CP_POS_WHITE_PIECES];
	my $black_pieces = $self->[CP_POS_BLACK_PIECES];
	my $pawns = $self->[CP_POS_PAWNS];
	my $knights = $self->[CP_POS_KNIGHTS];
	my $bishops = $self->[CP_POS_BISHOPS];
	my $rooks = $self->[CP_POS_ROOKS];
	my $queens = $self->[CP_POS_QUEENS];
	my $kings = $self->[CP_POS_KINGS];

	# We simply assume that a position without pawns is in general a draw.
	# If one side is a minor piece ahead, it is considered a draw, when there
	# are no rooks or queens on the board.  Important exception is KBB vs KN.
	# But in that case the material delta is B + B - N which is greater
	# than B.  On the other hand KBB vs KB is a draw and the material balance
	# in that case is exactly one bishop.
	# These simple formulas do not take into account that there may be more
	# than two knights or bishops for one side on the board but in the
	# exceptional case that this happens, the result would be close enough
	# anyway.
	if (!$pawns) {
		my $delta = (do {	my $mask = $material >> CP_INT_SIZE * CP_CHAR_BIT - 1;	($material + $mask) ^ $mask;});
		if ($delta < CP_PAWN_VALUE
		    || (!$rooks && !$queens
		        && (($delta <= CP_BISHOP_VALUE)
		            || ($delta == 2 * CP_KNIGHT_VALUE)
			        || ($delta == CP_KNIGHT_VALUE + CP_BISHOP_VALUE)))) {
			return Chess::Plisco::Engine::Tree::DRAW();
		}
	}

	my $op_phase = $self->[CP_POS_GAME_PHASE];

	$op_phase = TOTAL_PHASE if $op_phase > TOTAL_PHASE;
	my $eg_phase = TOTAL_PHASE - $op_phase;

	my $score = ($self->[CP_POS_OPENING_SCORE] * $op_phase
		+ $self->[CP_POS_ENDGAME_SCORE] * $eg_phase) / TOTAL_PHASE;

	return (((($self->[CP_POS_INFO] & (1 << 4)) >> 4))) ? -$score : $score;
}



sub openingDelta {
	my ($self, $index) = @_;

	return $opening_deltas[$index];
}

sub endgameDelta {
	my ($self, $index) = @_;

	return $endgame_deltas[$index];
}

1;
