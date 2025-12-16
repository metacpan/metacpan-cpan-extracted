#! /usr/bin/env perl

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More;

use Chess::Plisco;
# Macros from Chess::Plisco::Macro are already expanded here!

# The array elements are:
#
# - in
# - lo
# - hi
# - out
my @tests = (
	[127, 128, 255, 128],
	[128, 128, 255, 128],
	[129, 128, 255, 129],
	[254, 128, 255, 254],
	[255, 128, 255, 255],
	[256, 128, 255, 255],
	[-129, -128, -127, -128],
	[-128, -128, -127, -128],
	[-127, -128, -127, -127],
	[-126, -128, -127, -127],
);

plan tests => scalar @tests;

foreach my $test (@tests) {
	my ($v, $lo, $hi, $expected) = @$test;
	my $test_case = join ', ', @$test;

	my $got = ($v) < ($lo) ? ($lo) : ($v) > ($hi) ? ($hi) : ($v);
	is $got, $expected, "cp_clamp $test_case";
}
