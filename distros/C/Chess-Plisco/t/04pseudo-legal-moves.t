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
		# White moves.
		name => 'start position',
		moves => [qw(
			a2a3 a2a4
			b1a3 b1c3 b2b3 b2b4
			c2c3 c2c4
			d2d3 d2d4
			e2e3 e2e4
			f2f3 f2f4
			g1f3 g1h3 g2g3 g2g4
			h2h3 h2h4
		)],
	},
	{
		fen => '7k/8/4p3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures pawn',
		moves => [qw(
			a1a2 a1b1 a1b2
			d5d6 d5e6
		)],
		captures => { d5e6 => CP_PAWN },
	},
	{
		fen => '7k/8/4n3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures knight',
		moves => [qw(
			a1a2 a1b1 a1b2
			d5d6 d5e6
		)],
		captures => { d5e6 => CP_KNIGHT },
	},
	{
		fen => '7k/8/4b3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures bishop',
		moves => [qw(
			a1a2 a1b1 a1b2
			d5d6 d5e6
		)],
		captures => { d5e6 => CP_BISHOP },
	},
	{
		fen => '7k/8/4r3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures rook',
		moves => [qw(
			a1a2 a1b1 a1b2
			d5d6 d5e6
		)],
		captures => { d5e6 => CP_ROOK },
	},
	{
		fen => '7k/8/4q3/3P4/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures queen',
		moves => [qw(
			a1a2 a1b1 a1b2
			d5d6 d5e6
		)],
		captures => { d5e6 => CP_QUEEN },
	},
	{
		fen => '7k/8/4p3/8/3N4/8/8/K7 w - - 0 1',
		name => 'white knight captures pawn',
		moves => [qw(
			a1a2 a1b1 a1b2
			d4b3 d4b5 d4c2 d4c6
			d4e2 d4e6 d4f3 d4f5
		)],
		captures => { d4e6 => CP_PAWN },
	},
	{
		fen => '7k/8/4p3/3B4/8/8/8/K7 w - - 0 1',
		name => 'white bishop captures pawn',
		moves => [qw(
			a1a2 a1b1 a1b2 d5a2 d5a8 d5b3 d5b7
			d5c4 d5c6 d5e4 d5e6 d5f3 d5g2 d5h1
		)],
		captures => { d5e6 => CP_PAWN },
	},
	{
		fen => '7k/8/4p3/4R3/8/8/8/K7 w - - 0 1',
		name => 'white rook captures pawn',
		moves => [qw(
			a1a2 a1b1 a1b2
			e5a5 e5b5 e5c5 e5d5
			e5e1 e5e2 e5e3 e5e4 e5e6
			e5f5 e5g5 e5h5

		)],
		captures => { e5e6 => CP_PAWN },
	},
	{
		fen => '6k1/8/4p3/4Q3/8/8/8/K7 w - - 0 1',
		name => 'white queen captures pawn',
		moves => [qw(
			a1a2 a1b1 a1b2
			e5a5 e5b2 e5b5 e5b8
			e5c3 e5c5 e5c7
			e5d4 e5d5 e5d6
			e5e1 e5e2 e5e3 e5e4 e5e6
			e5f4 e5f5 e5f6
			e5g3 e5g5 e5g7
			e5h2 e5h5 e5h8

		)],
		captures => { e5e6 => CP_PAWN },
	},
	{
		fen => '4k3/8/8/8/8/8/3pp3/4K3 w - - 0 1',
		name => 'white king captures pawn',
		moves => [qw(
			e1d1 e1d2 e1e2 e1f1 e1f2
		)],
		captures => { e1d2 => CP_PAWN, e1e2 => CP_PAWN },
	},
	{
		fen => '3r2k1/2P5/8/8/8/8/8/K7 w - - 0 1',
		name => 'white pawn captures rook with promotion',
		moves => [qw(
			a1a2 a1b1 a1b2
			c7c8b c7c8n c7c8q c7c8r
			c7d8b c7d8n c7d8q c7d8r
		)],
		captures => {
			c7d8b => CP_ROOK,
			c7d8n => CP_ROOK,
			c7d8q => CP_ROOK,
			c7d8r => CP_ROOK,
		},
	},
	{
		fen => '6k1/8/8/3PpP2/8/8/8/K7 w - e6 0 1',
		name => 'white pawns capture pawn en passant',
		moves => [qw(
			a1a2 a1b1 a1b2
			d5d6 d5e6
			f5e6 f5f6
		)],
		captures => { d5e6 => CP_PAWN, f5e6 => CP_PAWN },
		ep_moves => { d5e6 => 1, f5e6 => 1},
	},
	{
		fen => '4k3/8/8/8/8/8/P6P/R3K2R w KQ - 0 1',
		name => 'white castlings',
		moves => [qw(
			a1b1 a1c1 a1d1 a2a3 a2a4
			e1c1 e1d1 e1d2 e1e2 e1f1 e1f2 e1g1
			h1f1 h1g1 h2h3 h2h4
		)],
	},
	# Black moves.
	{
		fen => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
		name => 'After 1. e4',
		moves => [qw(
			a7a5 a7a6 b7b5 b7b6 b8a6 b8c6
			c7c5 c7c6 d7d5 d7d6
			e7e5 e7e6 f7f5 f7f6
			g7g5 g7g6 g8f6 g8h6 h7h5 h7h6
		)],
	},
	{
		fen => '7k/8/8/8/4p3/3P4/8/K7 b - - 0 1',
		name => 'black pawn captures pawn',
		moves => [qw(
			e4d3 e4e3 h8g7 h8g8 h8h7
		)],
		captures => { e4d3 => CP_PAWN },
	},
	{
		fen => '7k/8/8/8/4p3/3N4/8/K7 b - - 0 1',
		name => 'black pawn captures knight',
		moves => [qw(
			e4d3 e4e3 h8g7 h8g8 h8h7
		)],
		captures => { e4d3 => CP_KNIGHT },
	},
	{
		fen => '7k/8/8/8/4p3/3B4/8/K7 b - - 0 1',
		name => 'black pawn captures bishop',
		moves => [qw(
			e4d3 e4e3 h8g7 h8g8 h8h7
		)],
		captures => { e4d3 => CP_BISHOP },
	},
	{
		fen => '7k/8/8/8/4p3/3R4/8/K7 b - - 0 1',
		name => 'black pawn captures rook',
		moves => [qw(
			e4d3 e4e3 h8g7 h8g8 h8h7
		)],
		captures => { e4d3 => CP_ROOK },
	},
	{
		fen => '7k/8/8/8/4p3/3Q4/8/K7 b - - 0 1',
		name => 'black pawn captures knight',
		moves => [qw(
			e4d3 e4e3 h8g7 h8g8 h8h7
		)],
		captures => { e4d3 => CP_QUEEN },
	},
	{
		fen => '7k/8/4n3/8/3P4/8/8/K7 b - - 0 1',
		name => 'black knight captures pawn',
		moves => [qw(
			e6c5 e6c7 e6d4 e6d8 e6f4 e6f8 e6g5 e6g7 h8g7 h8g8 h8h7
		)],
		captures => { e6d4 => CP_PAWN },
	},
	{
		fen => '7k/8/8/8/4b3/3P4/8/K7 b - - 0 1',
		name => 'black bishop captures pawn',
		moves => [qw(
			e4a8 e4b7 e4c6 e4d3 e4d5 e4f3 e4f5
			e4g2 e4g6 e4h1 e4h7 h8g7 h8g8 h8h7
		)],
		captures => { e4d3 => CP_PAWN },
	},
	{
		fen => '7k/8/3r4/8/3P4/8/8/K7 b - - 0 1',
		name => 'black rook captures pawn',
		moves => [qw(
			d6a6 d6b6 d6c6 d6d4 d6d5 d6d7 d6d8
			d6e6 d6f6 d6g6 d6h6 h8g7 h8g8 h8h7

		)],
		captures => { d6d4 => CP_PAWN },
	},
	{
		fen => '7k/8/3q4/8/3P4/8/8/K7 b - - 0 1',
		name => 'black queen captures pawn',
		moves => [qw(
			d6a3 d6a6 d6b4 d6b6 d6b8 d6c5 d6c6 d6c7
			d6d4 d6d5 d6d7 d6d8 d6e5 d6e6 d6e7 d6f4
			d6f6 d6f8 d6g3 d6g6 d6h2 d6h6
			h8g7 h8g8 h8h7
		)],
		captures => { d6d4 => CP_PAWN },
	},
	{
		fen => '4k3/3PP3/8/8/8/8/8/4K3 b - - 0 1',
		name => 'black king captures pawn',
		moves => [qw(
			e8d7 e8d8 e8e7 e8f7 e8f8
		)],
		captures => { e8d7 => CP_PAWN, e8e7 => CP_PAWN },
	},
	{
		fen => '7k/8/8/8/8/8/4p3/K2N4 b - - 0 1',
		name => 'black pawn captures knight with promotion',
		moves => [qw(
			e2d1b e2d1n e2d1q e2d1r e2e1b e2e1n e2e1q e2e1r h8g7 h8g8 h8h7
		)],
		captures => {
			e2d1b => CP_KNIGHT,
			e2d1n => CP_KNIGHT,
			e2d1q => CP_KNIGHT,
			e2d1r => CP_KNIGHT,
		},
	},
	{
		fen => '7k/8/8/8/3pPp2/8/8/K7 b - e3 0 1',
		name => 'black pawns capture pawn en passant',
		moves => [qw(
			d4d3 d4e3 f4e3 f4f3
			h8g7 h8g8 h8h7
		)],
		captures => { d4e3 => CP_PAWN, f4e3 => CP_PAWN },
		ep_moves => { d4e3 => 1, f4e3 => 1},
	},
	{
		fen => 'r3k2r/p6p/8/8/8/8/8/4K3 b kq - 0 1',
		name => 'black castlings',
		moves => [qw(
			a7a5 a7a6 a8b8 a8c8 a8d8
			e8c8 e8d7 e8d8 e8e7 e8f7 e8f8 e8g8
			h7h5 h7h6 h8f8 h8g8
		)],
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	my @moves = $pos->pseudoLegalMoves;
	my %moves;
	foreach my $move (@moves) {
		my $cn = $pos->moveCoordinateNotation($move, 1);
		$moves{$cn} = $move,
	}
	my @cns = sort keys %moves;
	is_deeply \@cns, $test->{moves}, "$test->{name} all moves";
	my $captures = $test->{captures} // {};
	my $ep_moves = $test->{ep_moves} // {};
	my $exp_colour = $pos->toMove;

	foreach my $cn (@cns) {
		my $move = $moves{$cn};

		my $got_captured = $pos->moveCaptured($move);
		my $exp_captured = $captures->{$cn} // CP_NO_PIECE;
		is $got_captured, $exp_captured, "$test->{name} $cn captured";

		my $got_is_ep = $pos->moveEnPassant($move); 
		my $exp_is_ep = $ep_moves->{$cn} || 0;
		is $got_is_ep, $exp_is_ep, "$test->{name} $cn is en passant";

		my $got_colour = $pos->moveColour($move);
		is $got_colour, $exp_colour, "$test->{name} $cn colour";
	}
}

done_testing;
