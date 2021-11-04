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

use Test::More tests => 35;
use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!

my ($bitboard, $count);

$bitboard = 0x88;
{ my $_b = $bitboard; for ($count = 0; $_b; ++$count) { $_b &= $_b - 1; } };
is $count, 2, 'popcount 0x88';
is $bitboard, 0x88, 'popcount 0x88';

$bitboard = 0xffff_ffff_ffff_ffff;
{ my $_b = $bitboard; for ($count = 0; $_b; ++$count) { $_b &= $_b - 1; } };
is $count, 64, 'popcount 0xffff_ffff_ffff_ffff';
is $bitboard, 0xffff_ffff_ffff_ffff, 'popcount 0xffff_ffff_ffff_ffff';

$bitboard = 0x1;
is((($bitboard) & -($bitboard)), 0x1,
	"cp_bitboard_clear_but_least_set($bitboard)");

$bitboard = 0x3;
is((($bitboard) & -($bitboard)), 0x1,
	"cp_bitboard_clear_but_least_set($bitboard)");

$bitboard = 0x7;
is((($bitboard) & -($bitboard)), 0x1,
	"cp_bitboard_clear_but_least_set($bitboard)");

$bitboard = 0xf;
is((($bitboard) & -($bitboard)), 0x1,
	"cp_bitboard_clear_but_least_set($bitboard)");

$bitboard = 0x7fff_ffff_ffff_ffff;
is((($bitboard) & -($bitboard)), 0x1,
	"cp_bitboard_clear_but_least_set($bitboard)");

$bitboard = 0x8fff_ffff_ffff_ffff;
is((($bitboard) & -($bitboard)), 0x1,
	"cp_bitboard_clear_but_least_set($bitboard)");

$bitboard = 0xffff_ffff_ffff_ffff;
is((($bitboard) & -($bitboard)), 0x1,
	"cp_bitboard_clear_but_least_set($bitboard)");

$bitboard = 0x2;
is((do {	my $A = $bitboard - 1 - ((($bitboard - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);}), 1,
	"cp_bitboard_count_isolated_trailing_zbits($bitboard)");

$bitboard = 0x8000;
is((do {	my $A = $bitboard - 1 - ((($bitboard - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);}), 15,
	"cp_bitboard_count_isolated_trailing_zbits($bitboard)");

$bitboard = 0x8000_0000_0000_0000;
is((do {	my $A = $bitboard - 1 - ((($bitboard - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);}), 63,
	"cp_bitboard_count_isolated_trailing_zbits($bitboard)");

$bitboard = 0x1;
is((do {	my $A = $bitboard - 1 - ((($bitboard - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);}), 0,
	"cp_bitboard_count_isolated_trailing_zbits($bitboard)");

$bitboard = 0x3;
is((($bitboard) & (($bitboard) - 1)), 0x2,
	"cp_bitboard_clear_least_set($bitboard)");

$bitboard = 0xffff_ffff_ffff_ffff;
is((($bitboard) & (($bitboard) - 1)), -2,
	"cp_bitboard_clear_least_set($bitboard)");

is((do {	my $mask = 2304 >> CP_INT_SIZE * CP_CHAR_BIT - 1;	(2304 + $mask) ^ $mask;}), 2304, "cp_abs(2304)");
is((do {	my $mask = -2304 >> CP_INT_SIZE * CP_CHAR_BIT - 1;	(-2304 + $mask) ^ $mask;}), 2304, "cp_abs(-2304)");

is((((2304) > (1303)) ? (2304) : (1303)), 2304, "cp_max(2304, 1303)");
is((((-2304) > (-1303)) ? (-2304) : (-1303)), -1303, "cp_max(-2304, -1303)");
is((((2304) < (1303)) ? (2304) : (1303)), 1303, "cp_min(2304, 1303)");
is((((-2304) < (-1303)) ? (-2304) : (-1303)), -2304, "cp_min(-2304, -1303)");

$bitboard = 0xf;
is((do {	my $B = $bitboard;	if ($B & 0x8000_0000_0000_0000) {		0x8000_0000_0000_0000;	} else {		$B |= $B >> 1;		$B |= $B >> 2;		$B |= $B >> 4;		$B |= $B >> 8;		$B |= $B >> 16;		$B |= $B >> 32;		$B - ($B >> 1);	}}), 0x8, "cp_bitboard_clear_but_most_set($bitboard)");

$bitboard = 0xffff_ffff_ffff_ffff;
is((do {	my $B = $bitboard;	if ($B & 0x8000_0000_0000_0000) {		0x8000_0000_0000_0000;	} else {		$B |= $B >> 1;		$B |= $B >> 2;		$B |= $B >> 4;		$B |= $B >> 8;		$B |= $B >> 16;		$B |= $B >> 32;		$B - ($B >> 1);	}}), 0x8000_0000_0000_0000,
	"cp_bitboard_clear_but_most_set($bitboard)");

$bitboard = 0x0000_0000_0000_0088;
is((do {	my $B = $bitboard;	if ($B & 0x8000_0000_0000_0000) {		0x8000_0000_0000_0000;	} else {		$B |= $B >> 1;		$B |= $B >> 2;		$B |= $B >> 4;		$B |= $B >> 8;		$B |= $B >> 16;		$B |= $B >> 32;		$B - ($B >> 1);	}}), 0x0000_0000_0000_0080,
	"cp_bitboard_clear_but_most_set($bitboard)");

$bitboard = 0x0000_0000_0000_8800;
is((do {	my $B = $bitboard;	if ($B & 0x8000_0000_0000_0000) {		0x8000_0000_0000_0000;	} else {		$B |= $B >> 1;		$B |= $B >> 2;		$B |= $B >> 4;		$B |= $B >> 8;		$B |= $B >> 16;		$B |= $B >> 32;		$B - ($B >> 1);	}}), 0x0000_0000_0000_8000,
	"cp_bitboard_clear_but_most_set($bitboard)");

$bitboard = 0x8800_0000_0000_0000;
is((do {	my $B = $bitboard;	if ($B & 0x8000_0000_0000_0000) {		0x8000_0000_0000_0000;	} else {		$B |= $B >> 1;		$B |= $B >> 2;		$B |= $B >> 4;		$B |= $B >> 8;		$B |= $B >> 16;		$B |= $B >> 32;		$B - ($B >> 1);	}}), 0x8000_0000_0000_0000,
	"cp_bitboard_clear_but_most_set($bitboard)");

$bitboard = 0x8000_0000_0000_0000;
is((do {	my $B = $bitboard;	if ($B & 0x8000_0000_0000_0000) {		0x8000_0000_0000_0000;	} else {		$B |= $B >> 1;		$B |= $B >> 2;		$B |= $B >> 4;		$B |= $B >> 8;		$B |= $B >> 16;		$B |= $B >> 32;		$B - ($B >> 1);	}}), 0x8000_0000_0000_0000,
	"cp_bitboard_clear_but_most_set($bitboard)");

$bitboard = 0x0000_0010_0000_0000;
is((do {	my $B = $bitboard;	if ($B & 0x8000_0000_0000_0000) {		0x8000_0000_0000_0000;	} else {		$B |= $B >> 1;		$B |= $B >> 2;		$B |= $B >> 4;		$B |= $B >> 8;		$B |= $B >> 16;		$B |= $B >> 32;		$B - ($B >> 1);	}}), 0x0000_0010_0000_0000,
	"cp_bitboard_clear_but_most_set($bitboard)");

$bitboard = 0x0000_0000_0000_0000;
ok(!($bitboard && ($bitboard & ($bitboard - 1))),
	"!cp_bitboard_more_than_one_set($bitboard)");

$bitboard = 0x0000_0100_0000_0000;
ok(!($bitboard && ($bitboard & ($bitboard - 1))),
	"!cp_bitboard_more_than_one_set($bitboard)");

$bitboard = 0x8000_0000_0000_0000;
ok(!($bitboard && ($bitboard & ($bitboard - 1))),
	"!cp_bitboard_more_than_one_set($bitboard)");

$bitboard = 0x8000_0100_0000_0000;
ok(($bitboard && ($bitboard & ($bitboard - 1))),
	"cp_bitboard_more_than_one_set($bitboard)");

$bitboard = 0x0000_0100_0000_0001;
ok(($bitboard && ($bitboard & ($bitboard - 1))),
	"cp_bitboard_more_than_one_set($bitboard)");
