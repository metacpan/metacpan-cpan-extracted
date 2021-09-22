#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::Position;
$Chess::Plisco::Engine::Position::VERSION = '0.2';
use strict;
use integer;

use Chess::Position qw(:all);
use Chess::Position::Macro;

use base qw(Chess::Position);

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

	# We count the number of pieces, 1 for each pawn and 2 for minor pieces,
	# 3 for the rooks, and 5 for the queens.  That makes per side 8 + 2 * 4
	# + 2 * 3 + 5 = 27 or 54 in total.  Only one queen per side is counted,
	# so that promotions do not change the value in the wrong direction.
	#
	# FIXME! All this is better updated in doMove() and undoMove().
	my $weighted_popcount = 0;

	while ($white_pawns) {
		my $shift = cp_bb_count_trailing_zbits $white_pawns;
		$score += $pawn_square_table[63 - $shift];
		$white_pawns = cp_bb_clear_least_set $white_pawns;
		++$weighted_popcount;
	}

	while ($black_pawns) {
		my $shift = cp_bb_count_trailing_zbits $black_pawns;
		$score -= $pawn_square_table[$shift];
		$black_pawns = cp_bb_clear_least_set $black_pawns;
		++$weighted_popcount;
	}

	while ($white_knights) {
		my $shift = cp_bb_count_trailing_zbits $white_knights;
		$score += $knight_square_table[63 - $shift];
		$white_knights = cp_bb_clear_least_set $white_knights;
		$weighted_popcount += 2;
	}

	while ($black_knights) {
		my $shift = cp_bb_count_trailing_zbits $black_knights;
		$score -= $knight_square_table[$shift];
		$black_knights = cp_bb_clear_least_set $black_knights;
		$weighted_popcount += 2;
	}

	while ($white_bishops) {
		my $shift = cp_bb_count_trailing_zbits $white_bishops;
		$score += $bishop_square_table[63 - $shift];
		$white_bishops = cp_bb_clear_least_set $white_bishops;
		$weighted_popcount += 2;
	}

	while ($black_bishops) {
		my $shift = cp_bb_count_trailing_zbits $black_bishops;
		$score -= $bishop_square_table[$shift];
		$black_bishops = cp_bb_clear_least_set $black_bishops;
		$weighted_popcount += 2;
	}

	while ($white_rooks) {
		my $shift = cp_bb_count_trailing_zbits $white_rooks;
		$score += $rook_square_table[63 - $shift];
		$white_rooks = cp_bb_clear_least_set $white_rooks;
		$weighted_popcount += 3;
	}

	while ($black_rooks) {
		my $shift = cp_bb_count_trailing_zbits $black_rooks;
		$score -= $rook_square_table[$shift];
		$black_rooks = cp_bb_clear_least_set $black_rooks;
		$weighted_popcount += 3;
	}

	# FIXME! For kings and queens there is no need to count them for the
	# weighted popcount. We can therefore mask out those squares that have
	# a value of 0 if we precalculate a mask for the other squares.
	$weighted_popcount += 5 if $white_queens;
	while ($white_queens) {
		my $shift = cp_bb_count_trailing_zbits $white_queens;
		$score += $queen_square_table[63 - $shift];
		$white_queens = cp_bb_clear_least_set $white_queens;
	}

	$weighted_popcount += 5 if $black_queens;
	while ($black_queens) {
		my $shift = cp_bb_count_trailing_zbits $black_queens;
		$score -= $queen_square_table[$shift];
		$black_queens = cp_bb_clear_least_set $black_queens;
	}

	my $middle_game_weight = $weighted_popcount;
	my $end_game_weight = 54 - $middle_game_weight;
	my $white_king_shift = cp_bb_count_trailing_zbits $white_kings;
	my $black_king_shift = cp_bb_count_trailing_zbits $black_kings;
	$score += ($middle_game_weight
		* $king_middle_game_square_table[63 - $white_king_shift] / 54);
	$score -= ($middle_game_weight
		* $king_middle_game_square_table[$black_king_shift] / 54);
	$score += ($end_game_weight
		* $king_end_game_square_table[63 - $white_king_shift] / 54);
	$score -= ($end_game_weight
		* $king_end_game_square_table[$black_king_shift] / 54);

	$score += $self->material;

	return (cp_pos_to_move($self)) ? -$score : $score;
}

# __END_MACROS__

1;
