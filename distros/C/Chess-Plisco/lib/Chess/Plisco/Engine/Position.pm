#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::Position;
$Chess::Plisco::Engine::Position::VERSION = '0.3';
use strict;
use integer;

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

use base qw(Chess::Plisco);

# Slightly different piece values.
use constant CP_POS_KNIGHT_VALUE => 320;
use constant CP_POS_BISHOP_VALUE => 330;

# Piece-square tables.  There are always from black's perspective.
my @pawn_square_table = (
	 0,  0,  0,  0,  0,  0,  0,  0,
	50, 50, 50, 50, 50, 50, 50, 50,
	10, 10, 20, 30, 30, 20, 10, 10,
	 5,  5, 10, 25, 25, 10,  5,  5,
	 0,  0,  0, 20, 20,  0,  0,  0,
	 5, -5,-10,  0,  0,-10, -5,  5,
	 5, 10, 10,-20,-20, 10, 10,  5,
	 0,  0,  0,  0,  0,  0,  0,  0,
);

my @knight_square_table = (
	-50,-40,-30,-30,-30,-30,-40,-50,
	-40,-20,  0,  0,  0,  0,-20,-40,
	-30,  0, 10, 15, 15, 10,  0,-30,
	-30,  5, 15, 20, 20, 15,  5,-30,
	-30,  0, 15, 20, 20, 15,  0,-30,
	-30,  5, 10, 15, 15, 10,  5,-30,
	-40,-20,  0,  5,  5,  0,-20,-40,
	-50,-40,-30,-30,-30,-30,-40,-50,
);

my @bishop_square_table = (
	-20,-10,-10,-10,-10,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5, 10, 10,  5,  0,-10,
	-10,  5,  5, 10, 10,  5,  5,-10,
	-10,  0, 10, 10, 10, 10,  0,-10,
	-10, 10, 10, 10, 10, 10, 10,-10,
	-10,  5,  0,  0,  0,  0,  5,-10,
	-20,-10,-10,-10,-10,-10,-10,-20,
);

my @rook_square_table = (
	 0,  0,  0,  0,  0,  0,  0,  0,
	 5, 10, 10, 10, 10, 10, 10,  5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	 0,  0,  0,  5,  5,  0,  0,  0,
);

my @queen_square_table = (
	-20,-10,-10, -5, -5,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5,  5,  5,  5,  0,-10,
	 -5,  0,  5,  5,  5,  5,  0, -5,
	  0,  0,  5,  5,  5,  5,  0, -5,
	-10,  5,  5,  5,  5,  5,  0,-10,
	-10,  0,  5,  0,  0,  0,  0,-10,
	-20,-10,-10, -5, -5,-10,-10,-20,
);

my @king_middle_game_square_table = (
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-20,-30,-30,-40,-40,-30,-30,-20,
	-10,-20,-20,-20,-20,-20,-20,-10,
	 20, 20,  0,  0,  0,  0, 20, 20,
	 20, 30, 10,  0,  0, 10, 30, 20,
);

my @king_end_game_square_table = (
	-50,-40,-30,-20,-20,-30,-40,-50,
	-30,-20,-10,  0,  0,-10,-20,-30,
	-30,-10, 20, 30, 30, 20,-10,-30,
	-30,-10, 30, 40, 40, 30,-10,-30,
	-30,-10, 30, 40, 40, 30,-10,-30,
	-30,-10, 20, 30, 30, 20,-10,-30,
	-30,-30,  0,  0,  0,  0,-30,-30,
	-50,-30,-30,-30,-30,-30,-30,-50,
);

# __BEGIN_MACROS__

use constant PAWN_PHASE => 0;
use constant KNIGHT_PHASE => 1;
use constant BISHOP_PHASE => 1;
use constant ROOK_PHASE => 2;
use constant QUEEN_PHASE => 4;
use constant TOTAL_PHASE => PAWN_PHASE * 16
	+ KNIGHT_PHASE * 4 + BISHOP_PHASE * 4
	+ ROOK_PHASE * 4 + QUEEN_PHASE * 2;

sub evaluate {
	my ($self) = @_;

	my $score = 0;
	my $white_pieces = $self->[CP_POS_WHITE_PIECES];
	my $black_pieces = $self->[CP_POS_BLACK_PIECES];
	my $white_pawns = $white_pieces & $self->[CP_POS_PAWNS];
	my $black_pawns = $black_pieces & $self->[CP_POS_PAWNS];
	my $white_knights = $white_pieces & $self->[CP_POS_KNIGHTS];
	my $black_knights = $black_pieces & $self->[CP_POS_KNIGHTS];
	my $white_bishops = $white_pieces & $self->[CP_POS_BISHOPS];
	my $black_bishops = $black_pieces & $self->[CP_POS_BISHOPS];
	my $white_rooks = $white_pieces & $self->[CP_POS_ROOKS];
	my $black_rooks = $black_pieces & $self->[CP_POS_ROOKS];
	my $white_queens = $white_pieces & $self->[CP_POS_QUEENS];
	my $black_queens = $black_pieces & $self->[CP_POS_QUEENS];
	my $white_kings = $white_pieces & $self->[CP_POS_KINGS];
	my $black_kings = $black_pieces & $self->[CP_POS_KINGS];

	my $phase = TOTAL_PHASE;

	while ($white_pawns) {
		my $shift = cp_bitboard_count_trailing_zbits $white_pawns;
		$score += $pawn_square_table[63 - $shift];
		$white_pawns = cp_bitboard_clear_least_set $white_pawns;
		$phase -= PAWN_PHASE;
	}

	while ($black_pawns) {
		my $shift = cp_bitboard_count_trailing_zbits $black_pawns;
		$score -= $pawn_square_table[$shift];
		$black_pawns = cp_bitboard_clear_least_set $black_pawns;
		$phase -= PAWN_PHASE;
	}

	while ($white_knights) {
		my $shift = cp_bitboard_count_trailing_zbits $white_knights;
		$score += $knight_square_table[63 - $shift];
		$white_knights = cp_bitboard_clear_least_set $white_knights;
		$phase -= KNIGHT_PHASE;
	}

	while ($black_knights) {
		my $shift = cp_bitboard_count_trailing_zbits $black_knights;
		$score -= $knight_square_table[$shift];
		$black_knights = cp_bitboard_clear_least_set $black_knights;
		$phase -= KNIGHT_PHASE;
	}

	while ($white_bishops) {
		my $shift = cp_bitboard_count_trailing_zbits $white_bishops;
		$score += $bishop_square_table[63 - $shift];
		$white_bishops = cp_bitboard_clear_least_set $white_bishops;
		$phase -= BISHOP_PHASE;
	}

	while ($black_bishops) {
		my $shift = cp_bitboard_count_trailing_zbits $black_bishops;
		$score -= $bishop_square_table[$shift];
		$black_bishops = cp_bitboard_clear_least_set $black_bishops;
		$phase -= BISHOP_PHASE;
	}

	while ($white_rooks) {
		my $shift = cp_bitboard_count_trailing_zbits $white_rooks;
		$score += $rook_square_table[63 - $shift];
		$white_rooks = cp_bitboard_clear_least_set $white_rooks;
		$phase -= ROOK_PHASE;
	}

	while ($black_rooks) {
		my $shift = cp_bitboard_count_trailing_zbits $black_rooks;
		$score -= $rook_square_table[$shift];
		$black_rooks = cp_bitboard_clear_least_set $black_rooks;
		$phase -= ROOK_PHASE;
	}

	# Count them only once.
	$phase -= QUEEN_PHASE if $white_queens;
	while ($white_queens) {
		my $shift = cp_bitboard_count_trailing_zbits $white_queens;
		$score += $queen_square_table[63 - $shift];
		$white_queens = cp_bitboard_clear_least_set $white_queens;
	}

	# Count them only once.
	$phase -= QUEEN_PHASE if $black_queens;
	while ($black_queens) {
		my $shift = cp_bitboard_count_trailing_zbits $black_queens;
		$score -= $queen_square_table[$shift];
		$black_queens = cp_bitboard_clear_least_set $black_queens;
	}

	$phase = 0 if $phase < 0;
	$phase = ($phase * 256 + (TOTAL_PHASE / 2)) / TOTAL_PHASE;

	my $white_king_shift = cp_bitboard_count_trailing_zbits $white_kings;
	my $black_king_shift = cp_bitboard_count_trailing_zbits $black_kings;
	my $opening_score = $score + $king_middle_game_square_table[63 - $white_king_shift]
		- $king_middle_game_square_table[$black_king_shift];
	my $endgame_score = $score + $king_end_game_square_table[63 - $black_king_shift]
		- $king_end_game_square_table[$black_king_shift];
	$score = (($opening_score * (TOTAL_PHASE - $phase))
			+ ($endgame_score * $phase)) / TOTAL_PHASE
		+ $self->material;

	return (cp_pos_to_move($self)) ? -$score : $score;
}

# __END_MACROS__

1;
