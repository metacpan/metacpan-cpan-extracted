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
use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!

my @tests = (
	{
		name => 'white queen',
		fen => 'k7/8/8/8/8/8/8/6QK w - - 10 20',
		state => 0,
	},
	{
		name => "scholar's mate",
		fen => 'r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4',
		state => CP_GAME_OVER | CP_GAME_WHITE_WINS,
	},
	{
		name => "fool's mate",
		fen => 'rnb1kbnr/pppp1ppp/4p3/8/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
		state => CP_GAME_OVER | CP_GAME_BLACK_WINS,
	},
	{
		name => 'fastest stalemate',
		fen => '5bnr/4p1pq/4Qpkr/7p/7P/4P3/PPPP1PP1/RNB1KBNR b KQ - 2 10',
		state => CP_GAME_OVER | CP_GAME_STALEMATE,
	},
	{
		name => 'Ushenina vs. Girya',
		fen => '8/8/8/5B2/8/4K3/1N6/3k4 b - - 100 122',
		state => CP_GAME_OVER | CP_GAME_FIFTY_MOVES,
	},
	# Edge cases:
	# KBvKB is a draw if the two bishops are on square of different colour.
	# Otherwise, a mate is possible if the other side cooperates.
	# Same goes for KBvKN and KNvKB.
	# If we have more material, a mate can be forced.
);

plan tests => scalar @tests;

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	my $state = $pos->gameOver;

	is $state, $test->{state}, "$test->{name} should have state '$state'";
}

