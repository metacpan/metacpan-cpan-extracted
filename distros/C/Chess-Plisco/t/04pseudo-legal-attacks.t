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
	{
		name => 'promotion bug',
		fen => 'r5k1/2Q3p1/p1n1q1p1/3p2P1/P7/7P/3p2PK/3q4 b - - 0 34',
		captures => {
			e6h3 => CP_PAWN,
			d1a4 => CP_PAWN,
		},
	},
	{
		# White moves.
		name => 'start position',
	},
	{
		fen => '7k/8/4p3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures pawn',
		captures => { d5e6 => CP_PAWN },
	},
	{
		fen => '7k/8/4n3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures knight',
		captures => { d5e6 => CP_KNIGHT },
	},
	{
		fen => '7k/8/4b3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures bishop',
		captures => { d5e6 => CP_BISHOP },
	},
	{
		fen => '7k/8/4r3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures rook',
		captures => { d5e6 => CP_ROOK },
	},
	{
		fen => '7k/8/4q3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures queen',
		captures => { d5e6 => CP_QUEEN },
	},
	{
		fen => '7k/8/4p3/8/3N4/8/8/K7 w - - 0 1',
		name => 'white knight captures pawn',
		captures => { d4e6 => CP_PAWN },
	},
	{
		fen => '7k/8/4p3/3B4/8/8/8/K7 w - - 0 1',
		name => 'white bishop captures pawn',
		captures => { d5e6 => CP_PAWN },
	},
	{
		fen => '7k/8/4p3/4R3/8/8/8/K7 w - - 0 1',
		name => 'white rook captures pawn',
		captures => { e5e6 => CP_PAWN },
	},
	{
		fen => '6k1/8/4p3/4Q3/8/8/8/K7 w - - 0 1',
		name => 'white queen captures pawn',
		captures => { e5e6 => CP_PAWN },
	},
	{
		fen => '4k3/8/8/8/8/8/3pp3/4K3 w - - 0 1',
		name => 'white king captures pawn',
		captures => { e1d2 => CP_PAWN, e1e2 => CP_PAWN },
	},
	{
		fen => '3r2k1/2P5/8/8/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures rook with promotion',
		captures => {
			c7d8b => CP_ROOK,
			c7d8n => CP_ROOK,
			c7d8q => CP_ROOK,
			c7d8r => CP_ROOK,
		},
		promotions => {
			c7c8b => CP_BISHOP,
			c7c8n => CP_KNIGHT,
			c7c8q => CP_QUEEN,
			c7c8r => CP_ROOK,
			c7d8b => CP_BISHOP,
			c7d8n => CP_KNIGHT,
			c7d8q => CP_QUEEN,
			c7d8r => CP_ROOK,
		},
	},
	{
		fen => '6k1/8/8/3PpP2/8/8/8/K7 w - e6 0 1',
		name => 'white pawns capture pawn en passant',
		captures => { d5e6 => CP_PAWN, f5e6 => CP_PAWN },
		ep_moves => { d5e6 => 1, f5e6 => 1},
	},
	{
		fen => '4k3/8/8/8/8/8/P6P/R3K2R w KQ - 0 1',
		name => 'white castlings',
	},
	# Black moves.
	{
		fen => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
		name => 'After 1. e4',
	},
	{
		fen => '7k/8/8/8/4p3/3P4/8/K7 b - - 0 1',
		name => 'black pawn captures pawn',
		captures => { e4d3 => CP_PAWN },
	},
	{
		fen => '7k/8/8/8/4p3/3N4/8/K7 b - - 0 1',
		name => 'black pawn captures knight',
		captures => { e4d3 => CP_KNIGHT },
	},
	{
		fen => '7k/8/8/8/4p3/3B4/8/K7 b - - 0 1',
		name => 'black pawn captures bishop',
		captures => { e4d3 => CP_BISHOP },
	},
	{
		fen => '7k/8/8/8/4p3/3R4/8/K7 b - - 0 1',
		name => 'black pawn captures rook',
		captures => { e4d3 => CP_ROOK },
	},
	{
		fen => '7k/8/8/8/4p3/3Q4/8/K7 b - - 0 1',
		name => 'black pawn captures knight',
		captures => { e4d3 => CP_QUEEN },
	},
	{
		fen => '7k/8/4n3/8/3P4/8/8/K7 b - - 0 1',
		name => 'black knight captures pawn',
		captures => { e6d4 => CP_PAWN },
	},
	{
		fen => '7k/8/8/8/4b3/3P4/8/K7 b - - 0 1',
		name => 'black bishop captures pawn',
		captures => { e4d3 => CP_PAWN },
	},
	{
		fen => '7k/8/3r4/8/3P4/8/8/K7 b - - 0 1',
		name => 'black rook captures pawn',
		captures => { d6d4 => CP_PAWN },
	},
	{
		fen => '7k/8/3q4/8/3P4/8/8/K7 b - - 0 1',
		name => 'black queen captures pawn',
		captures => { d6d4 => CP_PAWN },
	},
	{
		fen => '4k3/3PP3/8/8/8/8/8/4K3 b - - 0 1',
		name => 'black king captures pawn',
		captures => { e8d7 => CP_PAWN, e8e7 => CP_PAWN },
	},
	{
		fen => '7k/8/8/8/8/8/4p3/K2N4 b - - 0 1',
		name => 'black pawn captures knight with promotion',
		captures => {
			e2d1b => CP_KNIGHT,
			e2d1n => CP_KNIGHT,
			e2d1q => CP_KNIGHT,
			e2d1r => CP_KNIGHT,
		},
		promotions => {
			e2d1b => CP_BISHOP,
			e2d1n => CP_KNIGHT,
			e2d1q => CP_QUEEN,
			e2d1r => CP_ROOK,
			e2e1b => CP_BISHOP,
			e2e1n => CP_KNIGHT,
			e2e1q => CP_QUEEN,
			e2e1r => CP_ROOK,
		},
	},
	{
		fen => '7k/8/8/8/3pPp2/8/8/K7 b - e3 0 1',
		name => 'black pawns capture pawn en passant',
		captures => { d4e3 => CP_PAWN, f4e3 => CP_PAWN },
		ep_moves => { d4e3 => 1, f4e3 => 1},
	},
	{
		fen => 'r3k2r/p6p/8/8/8/8/8/4K3 b kq - 0 1',
		name => 'black castlings',
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	my @moves = $pos->pseudoLegalAttacks;
	my %moves;
	foreach my $move (@moves) {
		my $cn = $pos->moveCoordinateNotation($move, 1);
		$moves{$cn} = $move,
	}
	my @cn = sort keys %moves;
	my $captures = $test->{captures} // {};
	my $promotions = $test->{promotions} // {};
	my $ep_moves = $test->{ep_moves} // {};
	my $exp_colour = $pos->toMove;

	foreach my $cn (@cn) {
		ok $captures->{$cn} || $promotions->{$cn}, "$test->{name} $cn is a capture or promotion";

		my $move = $moves{$cn};

		if ($captures->{$cn}) {
			my $got_captured = $pos->moveCaptured($move);
			my $exp_captured = $captures->{$cn} // CP_NO_PIECE;
			is $got_captured, $exp_captured, "$test->{name} $cn captured";
		}

		if ($promotions->{$cn}) {
			my $got_promote = $pos->movePromote($move);
			my $exp_promote = $promotions->{$cn} // CP_NO_PIECE;
			is $got_promote, $exp_promote, "$test->{name} $cn promote";
		}

		my $got_is_ep = $pos->moveEnPassant($move); 
		my $exp_is_ep = $ep_moves->{$cn} || 0;
		is $got_is_ep, $exp_is_ep, "$test->{name} $cn is en passant";

		my $got_colour = $pos->moveColour($move);
		is $got_colour, $exp_colour, "$test->{name} $cn colour";
	}
}

done_testing;
