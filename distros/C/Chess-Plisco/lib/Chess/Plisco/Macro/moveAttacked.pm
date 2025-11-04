#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This is a macro that is not intended to run standalone.

## no critic (TestingAndDebugging::RequireUseStrict)

(do {
	# FIXME! Pass the color in to the macro!
	my $my_color = cp_pos_to_move($p);
	my $her_pieces = $p->[CP_POS_WHITE_PIECES + !$my_color];
	my $occupancy = ($p->[CP_POS_WHITE_PIECES + $my_color] | $her_pieces) & ~(1 << $from);
	my $queens = cp_pos_queens($p);
	$her_pieces
		& (($pawn_masks[$my_color]->[2]->[$to] & cp_pos_pawns($p))
			| ($knight_attack_masks[$to] & cp_pos_knights($p))
			| ($king_attack_masks[$to] & cp_pos_kings($p))
			| (cp_mm_bmagic($to, $occupancy) & ($queens | cp_pos_bishops($p)))
			| (cp_mm_rmagic($to, $occupancy) & ($queens | cp_pos_rooks($p))));
})
