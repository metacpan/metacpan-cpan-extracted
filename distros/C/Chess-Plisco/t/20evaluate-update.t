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

use Test::More;
use Data::Dumper;
use Chess::Plisco qw(:all);
use Chess::Plisco::Engine::Position;

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'Lone white king moves',
		fen => '7k/8/8/8/8/8/8/K7 w - - 0 1',
		san => 'Kb1',
	},
	{
		name => 'Lone black king moves',
		fen => '7k/8/8/8/8/8/8/K7 b - - 0 1',
		san => 'Kg8',
	},
	{
		name => 'Start position 1. e4',
		san => 'e4',
	},
	{
		name => 'Remove ep shift after 1. e4',
		fen => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
		san => 'Nf6',
	},
	{
		name => 'White queen-side castling',
		fen => '7k/8/8/8/8/8/8/R3K3 w Q - 0 1',
		san => 'O-O-O',
	},
	{
		name => 'White king-side castling',
		fen => 'k7/8/8/8/8/8/8/4K2R w K - 0 1',
		san => 'O-O',
	},
	{
		name => 'Black queen-side castling',
		fen => 'r3k3/8/8/8/8/8/8/7K b q - 0 1',
		san => 'O-O-O',
	},
	{
		name => 'Black king-side castling',
		fen => '4k2r/8/8/8/8/8/8/K7 b k - 0 1',
		san => 'O-O',
	},
	{
		name => 'Black king captures rook',
		fen => '7k/6R1/8/8/8/8/8/4K3 b - - 0 1',
		san => 'Kxg7',
	},
	{
		name => 'White promotes to queen',
		fen => '7k/4P3/8/8/8/8/8/4K3 w - - 0 1',
		san => 'e8=Q',
	},
	{
		name => 'White promotes to queen and captures',
		fen => '5q1k/4P3/8/8/8/8/8/4K3 w - - 0 1',
		san => 'exf8=Q',
	},
	{
		name => 'Simple white pawn capture',
		fen => '7k/8/8/8/8/1p6/P7/K7 w - - 0 1',
		san => 'axb3',
	},
	{
		name => 'Simple black pawn capture',
		fen => '7k/p7/1P6/8/8/8/8/K7 b - - 0 1',
		san => 'axb6',
	},
	{
		name => 'Flohr - Poisl, Kautsky mem4, 1927',
		fen => 'r2q1rk1/pbpnbpp1/1p1p3p/4p3/2PPP1nP/P1NB1N2/1P1BQPP1/R3K2R b KQ - 1 12',
		san => 'exd4',
	},
	{
		name => '1. c4 Nh6 2. Qa4',
		fen => 'rnbqkb1r/pppppppp/7n/8/2P5/8/PP1PPPPP/RNBQKBNR w KQkq - 1 2',
		san => 'Qa4',
	},
);

plan tests => 4 * @tests;

foreach my $test (@tests) {
	my $pos = Chess::Plisco::Engine::Position->new($test->{fen});
	my $score_before = $pos->evaluate;
	my $move = $pos->parseMove($test->{san});
	ok $move, "$test->{name}: parse $test->{san}";
	my $state = $pos->doMove($move);
	ok $state, "$test->{name}: do $test->{san}";
	my $score_updated = $pos->evaluate;
	my $fen = $pos->toFEN;
	$pos = Chess::Plisco::Engine::Position->new($fen);
	is $score_updated, $pos->evaluate, "$test->{name}: score updated";
	$pos->undoMove($state);
	is $pos->evaluate, $score_before, "$test->{name}: score reverted";
}