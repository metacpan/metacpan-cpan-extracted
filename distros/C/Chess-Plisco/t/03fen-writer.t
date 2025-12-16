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
use Data::Dumper;
use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!

my ($pos, @moves, @expect);

my @tests = (
	# Basic functionality.
	{
		name => 'start position, round-trip',
		pos => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		fen => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
	},
	# En-passant.
	{
		name => 'en-passant not possible from start after 1. e4',
		premoves => [qw(e2e4)],
		fen => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
		fen_force_ep => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
	},
	{
		name => 'en-passant possible',
		pos => 'rnbqkbnr/pppp1ppp/4p3/4P3/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 2',
		premoves => [qw(d7d5)],
		fen => 'rnbqkbnr/ppp2ppp/4p3/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
		fen_force_ep => 'rnbqkbnr/ppp2ppp/4p3/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
	},
	{
		name => 'capture reveals check',
		pos => '8/8/8/8/R2p3k/8/4P3/K7 w - - 0 1',
		premoves => [qw(e2e4)],
		fen => '8/8/8/8/R2pP2k/8/8/K7 b - - 0 1',
		fen_force_ep => '8/8/8/8/R2pP2k/8/8/K7 b - e3 0 1',
	},
	{
		name => 'repair illegal ep square',
		pos => '8/8/8/8/R2pP2k/8/8/K7 b - e3 0 1',
		fen => '8/8/8/8/R2pP2k/8/8/K7 b - - 0 1',
		fen_force_ep => '8/8/8/8/R2pP2k/8/8/K7 b - e3 0 1',
	}
);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{pos});
	foreach my $movestr (@{$test->{premoves} || []}) {
		my $move = $pos->parseMove($movestr);
		ok $move, "$test->{name}: parse $movestr";
		ok $pos->doMove($move), "$test->{name}: premove $movestr should be legal";
	}

	is $pos->toFEN, $test->{fen}, "$test->{name}: resulting FEN";
	if ($test->{fen_force_ep}) {
		is $pos->toFEN(force_en_passant_square => 1), $test->{fen_force_ep},
			"$test->{name}: resulting FEN with forced ep square";
	}
}

done_testing;
