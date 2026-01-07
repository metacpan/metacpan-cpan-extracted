#! /bin/false

# Copyright (C) 2021-2026 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This is a macro that is not intended to run standalone.

## no critic (TestingAndDebugging::RequireUseStrict)

(do {
	my $her_colour = !$c;
	my $her_pieces = $p->[CP_POS_WHITE_PIECES + $her_colour];
	my $occupancy = $p->[CP_POS_WHITE_PIECES + $c] | $her_pieces;
	my $queens = cp_pos_queens($p);
	$her_pieces
		& (($pawn_masks[$c]->[2]->[$shift] & cp_pos_pawns($p))
			| ($knight_attack_masks[$shift] & cp_pos_knights($p))
			| ($king_attack_masks[$shift] & cp_pos_kings($p))
			| (cp_mm_bmagic($shift, $occupancy) & ($queens | cp_pos_bishops($p)))
			| (cp_mm_rmagic($shift, $occupancy) & ($queens | cp_pos_rooks($p))));
})
