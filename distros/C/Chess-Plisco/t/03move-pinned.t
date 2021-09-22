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
use Chess::Plisco::Macro;

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'white rook pinned by rook on same file',
		move => 'e4g4',
		fen => '8/4r2k/8/8/4R3/8/4K3/8 w - - 0 1',
		pinned => 1,
	},
	{
		name => 'pinned white rook capturing black rook on same file',
		move => 'e4e7',
		fen => '8/4r2k/8/8/4R3/8/4K3/8 w - - 0 1',
		pinned => 0,
	},
	{
		name => 'pinned white rook moving on same file',
		move => 'e4e3',
		fen => '8/4r2k/8/8/4R3/8/4K3/8 w - - 0 1',
		pinned => 0,
	},
	{
		name => 'black rook pinned by queen on same rank',
		move => 'd3d6',
		fen => '8/8/7K/8/8/1k1r2Q1/8/8 b - - 0 1',
		pinned => 1,
	},
	{
		name => 'pinned black rook capturing white queen on same rank',
		move => 'd3g3',
		fen => '8/8/7K/8/8/1k1r2Q1/8/8 b - - 0 1',
		pinned => 0,
	},
	{
		name => 'pinned black rook moving on same rank',
		move => 'd3c3',
		fen => '8/8/7K/8/8/1k1r2Q1/8/8 b - - 0 1',
		pinned => 0,
	},
	{
		name => 'white bishop pinned by bishop on same diagonal',
		move => 'd4f6',
		fen => '8/7k/1b6/8/3B4/8/5K2/8 w - - 0 1',
		pinned => 1,
	},
	{
		name => 'pinned white bishop capturing black bishop on same diagonal',
		move => 'd4b6',
		fen => '8/7k/1b6/8/3B4/8/5K2/8 w - - 0 1',
		pinned => 0,
	},
	{
		name => 'pinned white bishop moving on same diagonal',
		move => 'd4e3',
		fen => '8/7k/1b6/8/3B4/8/5K2/8 w - - 0 1',
		pinned => 0,
	},
	{
		name => 'black queen pinned by bishop on same diagonal',
		move => 'c5g5',
		fen => '8/4k3/8/2q5/8/B7/8/6K1 b - - 0 1',
		pinned => 1,
	},
	{
		name => 'pinned black queen capturing bishop on same diagonal',
		move => 'c5a3',
		fen => '8/4k3/8/2q5/8/B7/8/6K1 b - - 0 1',
		pinned => 0,
	},
	{
		name => 'pinned black queen moving on same diagonal',
		move => 'c5d6',
		fen => '8/4k3/8/2q5/8/B7/8/6K1 b - - 0 1',
		pinned => 0,
	},
	{
		name => 'knight not pinned by own bishop',
		move => 'd6e5',
		fen => '1B3b1R/2q4b/2nn1Kp1/3p2p1/r7/k6r/p1p1p1p1/2RN1B1N b - - 0 1',
		pinned => 0,
	},
	{
		name => 'black bishop pinned by queen',
		move => 'e7f6',
		fen => 'rnbq1k1r/pp1Pbppp/2pQ4/8/2B5/8/PPP1NnPP/RNB1K2R b KQ - 1 8',
		pinned => 1,
	}
);

plan tests => @tests << 1;

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	my $move = $pos->parseMove($test->{move});
	ok $move, "$test->{name}: parse $test->{move}";

	if ($test->{pinned}) {
		ok $pos->movePinned($move), $test->{name};
	} else {
		ok !$pos->movePinned($move), $test->{name};
	}
}
