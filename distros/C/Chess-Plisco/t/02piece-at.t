#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More tests => 6 * 64;
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

# The array elements are:
#
# - square
# - file (0 .. 7)
# - rank (0 .. 7)
# - shift (0 .. 63)
my @tests = (
	# 1st rank.
	['a1', 0, 0, 0, CP_ROOK, CP_WHITE],
	['b1', 1, 0, 1, CP_KNIGHT, CP_WHITE],
	['c1', 2, 0, 2, CP_BISHOP, CP_WHITE],
	['d1', 3, 0, 3, CP_QUEEN, CP_WHITE],
	['e1', 4, 0, 4, CP_KING, CP_WHITE],
	['f1', 5, 0, 5, CP_BISHOP, CP_WHITE],
	['g1', 6, 0, 6, CP_KNIGHT, CP_WHITE],
	['h1', 7, 0, 7, CP_ROOK, CP_WHITE],
	# 2st rank.
	['a2', 0, 1, 8, CP_PAWN, CP_WHITE],
	['b2', 1, 1, 9, CP_PAWN, CP_WHITE],
	['c2', 2, 1, 10, CP_PAWN, CP_WHITE],
	['d2', 3, 1, 11, CP_PAWN, CP_WHITE],
	['e2', 4, 1, 12, CP_PAWN, CP_WHITE],
	['f2', 5, 1, 13, CP_PAWN, CP_WHITE],
	['g2', 6, 1, 14, CP_PAWN, CP_WHITE],
	['h2', 7, 1, 15, CP_PAWN, CP_WHITE],
	# 3rd rank.
	['a3', 0, 2, 16, CP_NO_PIECE, undef],
	['b3', 1, 2, 17, CP_NO_PIECE, undef],
	['c3', 2, 2, 18, CP_NO_PIECE, undef],
	['d3', 3, 2, 19, CP_NO_PIECE, undef],
	['e3', 4, 2, 20, CP_NO_PIECE, undef],
	['f3', 5, 2, 21, CP_NO_PIECE, undef],
	['g3', 6, 2, 22, CP_NO_PIECE, undef],
	['h3', 7, 2, 23, CP_NO_PIECE, undef],
	# 4th rank.
	['a4', 0, 3, 24, CP_NO_PIECE, undef],
	['b4', 1, 3, 25, CP_NO_PIECE, undef],
	['c4', 2, 3, 26, CP_NO_PIECE, undef],
	['d4', 3, 3, 27, CP_NO_PIECE, undef],
	['e4', 4, 3, 28, CP_NO_PIECE, undef],
	['f4', 5, 3, 29, CP_NO_PIECE, undef],
	['g4', 6, 3, 30, CP_NO_PIECE, undef],
	['h4', 7, 3, 31, CP_NO_PIECE, undef],
	# 5th rank.
	['a5', 0, 4, 32, CP_NO_PIECE, undef],
	['b5', 1, 4, 33, CP_NO_PIECE, undef],
	['c5', 2, 4, 34, CP_NO_PIECE, undef],
	['d5', 3, 4, 35, CP_NO_PIECE, undef],
	['e5', 4, 4, 36, CP_NO_PIECE, undef],
	['f5', 5, 4, 37, CP_NO_PIECE, undef],
	['g5', 6, 4, 38, CP_NO_PIECE, undef],
	['h5', 7, 4, 39, CP_NO_PIECE, undef],
	# 6th rank.
	['a6', 0, 5, 40, CP_NO_PIECE, undef],
	['b6', 1, 5, 41, CP_NO_PIECE, undef],
	['c6', 2, 5, 42, CP_NO_PIECE, undef],
	['d6', 3, 5, 43, CP_NO_PIECE, undef],
	['e6', 4, 5, 44, CP_NO_PIECE, undef],
	['f6', 5, 5, 45, CP_NO_PIECE, undef],
	['g6', 6, 5, 46, CP_NO_PIECE, undef],
	['h6', 7, 5, 47, CP_NO_PIECE, undef],
	# 7th rank.
	['a7', 0, 6, 48, CP_PAWN, CP_BLACK],
	['b7', 1, 6, 49, CP_PAWN, CP_BLACK],
	['c7', 2, 6, 50, CP_PAWN, CP_BLACK],
	['d7', 3, 6, 51, CP_PAWN, CP_BLACK],
	['e7', 4, 6, 52, CP_PAWN, CP_BLACK],
	['f7', 5, 6, 53, CP_PAWN, CP_BLACK],
	['g7', 6, 6, 54, CP_PAWN, CP_BLACK],
	['h7', 7, 6, 55, CP_PAWN, CP_BLACK],
	# 8th rank.
	['a8', 0, 7, 56, CP_ROOK, CP_BLACK],
	['b8', 1, 7, 57, CP_KNIGHT, CP_BLACK],
	['c8', 2, 7, 58, CP_BISHOP, CP_BLACK],
	['d8', 3, 7, 59, CP_QUEEN, CP_BLACK],
	['e8', 4, 7, 60, CP_KING, CP_BLACK],
	['f8', 5, 7, 61, CP_BISHOP, CP_BLACK],
	['g8', 6, 7, 62, CP_KNIGHT, CP_BLACK],
	['h8', 7, 7, 63, CP_ROOK, CP_BLACK],
);

my $pos = Chess::Plisco->new;
foreach my $test (@tests) {
	my ($square, $file, $rank, $shift, $wanted_piece, $wanted_color) = @$test;

	my ($got_piece, $got_color);

	($got_piece, $got_color) = $pos->pieceAtSquare($square);
	is $got_piece, $wanted_piece, "pieceAtSquare($square): piece";
	is $got_color, $wanted_color, "pieceAtSquare($square): color";

	($got_piece, $got_color) = $pos->pieceAtCoordinates($file, $rank);
	is $got_piece, $wanted_piece, "pieceAtCoordinates($file, $rank): piece";
	is $got_color, $wanted_color, "pieceAtCoordinates($file, $rank): color";

	($got_piece, $got_color) = $pos->pieceAtShift($shift);
	is $got_piece, $wanted_piece, "pieceAtShift($shift): piece";
	is $got_color, $wanted_color, "pieceAtShift($shift): color";
}
