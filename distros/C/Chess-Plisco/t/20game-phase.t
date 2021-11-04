#! /usr/bin/env perl

# Copyright (C) 2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Analyze chess games in PGN format

use strict;

use Test::More;

use Chess::Plisco::Engine::Position;

my @tests = (
	{
		name => 'start position',
		move => 'e4',
	},
	{
		name => 'Ruy Lopez Exchange Variation',
		fen => 'r1bqkbnr/1ppp1ppp/p1n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1',
		move => 'Bxc6',
	},
	{
		name => 'Promotion',
		fen => '3k4/8/8/8/8/8/6p1/3K4 b - - 0 1',
		move => 'g1=q',
	},
	{
		name => 'Promotion with capture',
		fen => '3k3r/6P1/8/8/8/8/8/3K4 w - - 0 1',
		move => 'gxh8=r',
	},
	{
		name => 'Capture pawn',
		fen => '3k4/8/8/3p4/4B3/8/8/3K4 w - - 0 1',
		move => 'Bxd5',
	},
	{
		name => 'Capture knight',
		fen => '3k4/8/8/3n4/4B3/8/8/3K4 w - - 0 1',
		move => 'Bxd5',
	},
	{
		name => 'Capture bishop',
		fen => '3k4/8/8/3b4/4B3/8/8/3K4 w - - 0 1',
		move => 'Bxd5',
	},
	{
		name => 'Capture rook',
		fen => '3k4/8/8/3r4/4B3/8/8/3K4 w - - 0 1',
		move => 'Bxd5',
	},
	{
		name => 'Capture queen',
		fen => '3k4/8/8/3q4/4B3/8/8/3K4 w - - 0 1',
		move => 'Bxd5',
	},
	{
		name => 'Promote to queen',
		fen => 'K2k4/8/8/8/8/8/5p2/8 b - - 0 1',
		move => 'f1=q',
	},
	{
		name => 'Promote to rook',
		fen => 'K2k4/8/8/8/8/8/5p2/8 b - - 0 1',
		move => 'f1=r',
	},
	{
		name => 'Promote to bishop',
		fen => 'K2k4/8/8/8/8/8/5p2/8 b - - 0 1',
		move => 'f1=b',
	},
	{
		name => 'Promote to knight',
		fen => 'K2k4/8/8/8/8/8/5p2/8 b - - 0 1',
		move => 'f1=n',
	},
);

plan tests => 3 * scalar @tests;

my $cp_pos_game_phase = Chess::Plisco::Engine::Position::CP_POS_GAME_PHASE();

foreach my $test (@tests) {
	my $position = Chess::Plisco::Engine::Position->new($test->{fen});
	my $old_phase = $position->[$cp_pos_game_phase];
	my $state = $position->applyMove($test->{move});
	ok $state, "$test->{name}: apply move $test->{move}";
	my $new_position = Chess::Plisco::Engine::Position->new("$position");
	is $position->[$cp_pos_game_phase], $new_position->[$cp_pos_game_phase],
			"$test->{name}: $test->{move}: game phase";
	$position->unapplyMove($state);
	is $position->[$cp_pos_game_phase], $old_phase,
			"$test->{name}: unapply $test->{move}: game phase restored";
}
