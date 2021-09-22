#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This is a macro that is not intended to run standalone.

## no critic (TestingAndDebugging::RequireUseStrict)

(do {
	my $c = cp_pos_info_to_move($i);
	my $kings = cp_pos_kings($p)
		& ($c ? cp_pos_black_pieces($p) : cp_pos_white_pieces($p));
	my $king_shift = cp_bitboard_count_isolated_trailing_zbits($kings);
	_cp_pos_info_set_king_shift($i, $king_shift);

	my $checkers = cp_pos_in_check($p) = _cp_pos_color_attacked $p, $c, $king_shift;

	if ($checkers) {
		# Check evasion strategy.  If in-check, the options are:
		#
		# 1. Move the king.
		# 2. Hit the piece that gives check unless multiple pieces give check.
		# 3. Move a piece in front of the king for protection unless a knight
		#    gives check or two pieces give check simultaneously.
		#
		# That leads to 3 different levels for the evasion strategy.  Option 1
		# is always valid. Option 2 only if only one piece gives check.  Option
		# 3 if only one piece gives check and the piece is bishop or rook.
		#
		# Pawn checks can be treated like knight checks because the pawn
		# always has direct contact with the king.
		#
		# For both options 2 and 3 we define an evasion bitboard of valid
		# target squares.  This information is then used in the legality check
		# for non-king moves to see whether the move prevents a check.  There
		# is no need to distinguish between the two cases in the legality check.
		# The difference is just the popcount of the evasion bitboard.

		if ($checkers & ($checkers - 1)) {
			_cp_pos_info_set_evasion($i, CP_EVASION_KING_MOVE);
		} elsif ($checkers & (cp_pos_knights($p) | (cp_pos_pawns($p)))) {
			_cp_pos_info_set_evasion($i, CP_EVASION_CAPTURE);
			cp_pos_evasion_squares($p) = $checkers;
		} else {
			_cp_pos_info_set_evasion($i, CP_EVASION_ALL);
			my $piece_shift = cp_bitboard_count_isolated_trailing_zbits $checkers;
			my ($attack_type, undef, $attack_ray) =
				@{$common_lines[$king_shift]->[$piece_shift]};
			if ($attack_ray) {
				cp_pos_evasion_squares($p) = $attack_ray;
			} else {
				cp_pos_evasion_squares($p) = $checkers;
			}
		}
	}

	cp_pos_info($p) = $i;
})
