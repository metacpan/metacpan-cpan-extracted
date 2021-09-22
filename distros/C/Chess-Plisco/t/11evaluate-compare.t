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

# All these tests are for symmetrical positions, where an improvement happens
# between bad and good.
my @tests = (
	{
		name => 'white knight not on edge',
		bad => 'rnbqkbnr/pppppppp/8/8/8/N7/PPPPPPPP/R1BQKBNR b KQkq - 0 1',
		good => 'rnbqkbnr/pppppppp/8/8/8/2N5/PPPPPPPP/R1BQKBNR b KQkq - 0 1',
	},
	{
		name => 'black knight not on edge',
		bad => 'r1bqkbnr/pppppppp/n7/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		good => 'r1bqkbnr/pppppppp/2n5/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
	},
);

plan tests => scalar @tests;

foreach my $test (@tests) {
	my $bad = Chess::Plisco::Engine::Position->new($test->{bad});
	my $score_bad = $bad->evaluate;
	my $good = Chess::Plisco::Engine::Position->new($test->{good});
	my $score_good = -$good->evaluate;
	ok $score_good > $score_bad,
		"$test->{name}: improvement ($score_bad -> $score_good)";
}