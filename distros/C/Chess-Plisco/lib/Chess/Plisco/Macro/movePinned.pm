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

( do {
	my $pinned;

	# If the piece to move is on a common line with the king, it may be pinned.
	my $king_ray = $common_lines[$from]->[$ks];
	if ($king_ray) {
		my ($is_rook, $ray_mask) = @$king_ray;

		# If the destination square is on the same line, the piece cannot be
		# pinned.  That also covers the case that the piece that moves captures
		# the piece that pins.
		if (!((1 << $to) & $ray_mask)) {
			if ($is_rook) {
				my $rmagic = cp_mm_rmagic($from, ($mp | $hp)) & $ray_mask;
				$pinned = ($rmagic & (1 << $ks))
						&& ($rmagic & $hp
							& (cp_pos_queens($p) | cp_pos_rooks($p)));
			} else {
				my $bmagic = cp_mm_bmagic($from, ($mp | $hp)) & $ray_mask;
				$pinned = ($bmagic & (1 << $ks))
						&& ($bmagic & $hp
							& (cp_pos_queens($p) | cp_pos_bishops($p)));
			}
		}
	}

	$pinned;
})
