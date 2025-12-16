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

while ($target_mask) {
	my $to = cp_bitboard_count_trailing_zbits $t;
	my $base_move = $b | ($to << 15) | ($board[$to] << 3);
	# It is important for move ordering to sort from good to bad promotions.
	push @m,
		$b | (5 << 6), # Queen
		$b | (4 << 6), # Rook
		$b | (3 << 6), # Bishop
		$b | (2 << 6); # Knight
	$target_mask = cp_bitboard_clear_least_set $target_mask;
}
