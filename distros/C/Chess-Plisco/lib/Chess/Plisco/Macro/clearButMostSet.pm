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

# This is a variation of the well-known algorithm.  The if branch is
# necessary because under the integer pragma, all operands and results of
# the bitwise operators are treated as signed.
#
# At first glance, it looks like this will slow down things.  But with evenly
# distributed input, the opposite is true.  For about half of the possible
# input values, it is a lot faster, for the other half it is a little slower
# All in all, it is faster but ...
#
# Alas, our input is not evenly distributed because we are working on bitboards
# representing the position of chess pieces.  The most densely populated
# bitboard that I can think of is the bitboard of all pieces.  It has 32 of
# 64 bits set.  The odds that the left-most bit is set are therefore
# 0.5  The less pieces a bitboard represents (pawns, knights, bishops, ...
# kings), the less likely it is that the left-most bit is set, and then the
# extra branch becomes less and less useful, thus more and more expensive.
#
# In other words, yes, it is less efficient than the unodified algorithm.
(do {
	my $B = $bb;
	if ($B & 0x8000_0000_0000_0000) {
		0x8000_0000_0000_0000;
	} else {
		$B |= $B >> 1;
		$B |= $B >> 2;
		$B |= $B >> 4;
		$B |= $B >> 8;
		$B |= $B >> 16;
		$B |= $B >> 32;
		$B - ($B >> 1);
	}
})
