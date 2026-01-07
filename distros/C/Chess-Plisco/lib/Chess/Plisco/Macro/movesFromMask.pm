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

while ($target_mask) {
	my $to = cp_bitboard_count_trailing_zbits $t;
	push @m, $b | ($to << 15) | ($board[$to] << 3);
	$target_mask = cp_bitboard_clear_least_set $target_mask;
}
