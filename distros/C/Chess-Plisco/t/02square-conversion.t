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

use Test::More tests => 12 * 64;
use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!

# The array elements are:
#
# - square
# - file (0 .. 7)
# - rank (0 .. 7)
# - shift (0 .. 63)
my @tests = (
	# 1st rank.
	['a1', 0, 0, 0],
	['b1', 1, 0, 1],
	['c1', 2, 0, 2],
	['d1', 3, 0, 3],
	['e1', 4, 0, 4],
	['f1', 5, 0, 5],
	['g1', 6, 0, 6],
	['h1', 7, 0, 7],
	# 2st rank.
	['a2', 0, 1, 8],
	['b2', 1, 1, 9],
	['c2', 2, 1, 10],
	['d2', 3, 1, 11],
	['e2', 4, 1, 12],
	['f2', 5, 1, 13],
	['g2', 6, 1, 14],
	['h2', 7, 1, 15],
	# 3rd rank.
	['a3', 0, 2, 16],
	['b3', 1, 2, 17],
	['c3', 2, 2, 18],
	['d3', 3, 2, 19],
	['e3', 4, 2, 20],
	['f3', 5, 2, 21],
	['g3', 6, 2, 22],
	['h3', 7, 2, 23],
	# 4th rank.
	['a4', 0, 3, 24],
	['b4', 1, 3, 25],
	['c4', 2, 3, 26],
	['d4', 3, 3, 27],
	['e4', 4, 3, 28],
	['f4', 5, 3, 29],
	['g4', 6, 3, 30],
	['h4', 7, 3, 31],
	# 5th rank.
	['a5', 0, 4, 32],
	['b5', 1, 4, 33],
	['c5', 2, 4, 34],
	['d5', 3, 4, 35],
	['e5', 4, 4, 36],
	['f5', 5, 4, 37],
	['g5', 6, 4, 38],
	['h5', 7, 4, 39],
	# 6th rank.
	['a6', 0, 5, 40],
	['b6', 1, 5, 41],
	['c6', 2, 5, 42],
	['d6', 3, 5, 43],
	['e6', 4, 5, 44],
	['f6', 5, 5, 45],
	['g6', 6, 5, 46],
	['h6', 7, 5, 47],
	# 7th rank.
	['a7', 0, 6, 48],
	['b7', 1, 6, 49],
	['c7', 2, 6, 50],
	['d7', 3, 6, 51],
	['e7', 4, 6, 52],
	['f7', 5, 6, 53],
	['g7', 6, 6, 54],
	['h7', 7, 6, 55],
	# 8th rank.
	['a8', 0, 7, 56],
	['b8', 1, 7, 57],
	['c8', 2, 7, 58],
	['d8', 3, 7, 59],
	['e8', 4, 7, 60],
	['f8', 5, 7, 61],
	['g8', 6, 7, 62],
	['h8', 7, 7, 63],
);

my $class = 'Chess::Plisco';
foreach my $test (@tests) {
	my ($square, $file, $rank, $shift) = @$test;

	# Methods.
	is $class->shiftToSquare($shift), $square,
		"shiftToSquare $square";
	is $class->squareToShift($square), $shift,
		"squareToShift $square";
	is $class->coordinatesToSquare($file, $rank), $square,
		"coordinatesToSquare $square";
	is $class->coordinatesToShift($file, $rank), $shift,
		"coordinatesToShift $square";
	is_deeply [$class->shiftToCoordinates($shift)], [$file, $rank],
		"shiftToCoordinates $shift";
	is_deeply [$class->squareToCoordinates($square)], [$file, $rank],
		"squareToCoordinates $shift";
	
	# Macros.
	is(chr(97 + ($shift & 0x7)) . (1 + ($shift >> 3)), $square,
		"cp_shift_to_square $square");
	is((((substr $square, 1) - 1) << 3) + ord($square) - 97, $shift,
		"cp_square_to_shift $square");
	is(chr(97 + $file) . (1 + $rank), $square,
		"cp_coordinates_to_square $square");
	is((($rank << 3) + $file), $shift,
		"cp_coordinates_to_shift $square");
	is_deeply([($shift & 0x7, $shift >> 3)], [$file, $rank],
		"cp_shift_to_coordinates $shift");
	is_deeply([(ord($square) - 97, -1 + substr $square, 1)], [$file, $rank],
		"cp_square_to_coordinates $shift");
}
