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
	my $B = $bb & -$bb;
	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);
	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);
	my $n = $C + ($C >> 32);
	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);
	$n = ($n & 0xffff) + ($n >> 16);
	$n = ($n & 0xff) + ($n >> 8);
})
