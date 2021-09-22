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
		name => 'initial position, 1. e4',
		move => 'e4',
		result => '+',
	},
	{
		name => 'initial position from FEN, 1. e4 ',
		fen => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		move => 'e4',
		result => '+',
	},
	{
		name => 'initial position, 1. d4',
		move => 'd4',
		result => '+',
	},
	{
		name => 'initial position, 1. Nc3',
		move => 'Nc3',
		result => '+',
	},
	{
		name => 'open game, 1. ...e5',
		fen => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
		move => 'e5',
		result => '+',
	},
	{
		name => 'white king-side castling',
		fen => 'r3k2r/pbpq1ppp/1pnp1n2/2b1p3/2B1P3/1PNP1N2/PBPQ1PPP/R3K2R w KQkq - 0 1',
		move => 'O-O',
		result => '+',
	},
	{
		name => 'white queen-side castling',
		fen => 'r3k2r/pbpq1ppp/1pnp1n2/2b1p3/2B1P3/1PNP1N2/PBPQ1PPP/R3K2R w KQkq - 0 1',
		move => 'O-O-O',
		result => '+',
	},
	{
		name => 'black king-side castling',
		fen => 'r3k2r/pbpq1ppp/1pnp1n2/2b1p3/2B1P3/1PNP1N2/PBPQ1PPP/R3K2R b KQkq - 0 1',
		move => 'O-O',
		result => '+',
	},
	{
		name => 'black queen-side castling',
		fen => 'r3k2r/pbpq1ppp/1pnp1n2/2b1p3/2B1P3/1PNP1N2/PBPQ1PPP/R3K2R b KQkq - 0 1',
		move => 'O-O-O',
		result => '+',
	},
);

plan tests => 1 + 2 * scalar @tests;

is(Chess::Plisco::Engine::Position->new->evaluate, 0, "score of initial position");

foreach my $test (@tests) {
	my $position = Chess::Plisco::Engine::Position->new($test->{fen});
	my $score_before = $position->evaluate;
	ok $position->applyMove($test->{move}), "$test->{name}: move $test->{move}";
	my $score_after = -$position->evaluate;
	if ($test->{result} eq '+') {
		ok $score_after > $score_before,
			"$test->{name}: improvement after move $test->{move}";
	} else {
		ok $score_after < $score_before,
			"$test->{name}: deterioration for black after move $test->{move}";
	}
}