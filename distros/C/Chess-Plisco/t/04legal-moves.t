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
		name => 'legal moves bug 1',
		fen => '1B3b1R/2q4b/2nn1Kp1/3p2p1/r7/k6r/p1p1p1p1/2RN1B1N b - - 0 1',
		moves => [qw(
			a2a1q a2a1r a2a1b a2a1n c2d1q c2d1r
			c2d1b c2d1n e2e1q e2e1r e2e1b e2e1n
			e2f1q e2f1r e2f1b e2f1n e2d1q e2d1r
			e2d1b e2d1n g2g1q g2g1r g2g1b g2g1n
			g2h1q g2h1r g2h1b g2h1n g2f1q g2f1r
			g2f1b g2f1n a3b4 a3b3 h3h4 h3h5
			h3h6 h3h2 h3h1 h3g3 h3f3 h3e3
			h3d3 h3c3 h3b3 a4b4 a4c4 a4d4
			a4e4 a4f4 a4g4 a4h4 a4a5 a4a6
			a4a7 a4a8 d5d4 g5g4 c6b8 c6d8
			c6a7 c6e7 c6a5 c6e5 c6b4 c6d4
			d6c8 d6e8 d6b7 d6f7 d6b5 d6f5
			d6c4 d6e4 c7d7 c7e7 c7f7 c7g7
			c7c8 c7b7 c7a7 c7b8 c7d8 c7b6
			c7a5 h7g8 f8g7 f8h6 f8e7
		)],
	},
	{
		name => 'allow king to evade check',
		fen => 'r3k2r/p1ppqpb1/1n2pnp1/3PN3/1p2P3/2N2Q1p/PPPBbPPP/R4K1R w KQkq - 0 1',
		moves => [qw(c3e2 f1e1 f1g1 f3e2 f1e2)],
	},
	{
		name => 'perft bug chessprogramming.org position 5',
		fen => 'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
		premoves => [qw(d1d6)],
		moves => [qw(
			c6c5 a7a6 b7b6 f7f6 g7g6 h7h6 a7a5 b7b5 f7f5 g7g5 h7h5 f2d1 f2h1
			f2d3 f2h3 f2e4 f2g4 b8a6 b8d7 f8g8 d8e8 e7d6 d8d7 c8d7 h8g8 d8a5
			d8b6 d8c7
		)],
	},
	{
		name => 'discovered rook check through en passant',
		fen => '8/2p5/3p4/KP5r/1R3pPk/8/4P3/8 b - g3 0 1',
		# Capturing en passant f4g3 exposes the own king to check by a rook
		# FIXME! Create a simplified version of the test and one that
		# does the same for a bishop attack.
		moves => [qw(
			f4f3 d6d5 c7c6 c7c5 h5b5 h5c5 h5d5 h5e5 h5f5 h5g5 h5h6 h5h7 h5h8
			h4g3 h4h3 h4g4 h4g5
		)],
	},
	{
		name => 'discovered rook check through en passant simplified',
		fen => '8/8/8/K7/1R3p1k/8/6P1/8 w - - 0 1',
		premoves => [qw(g2g4)],
		moves => [qw(h4g5 h4g4 h4g3 h4h3 f4f3)],
	},
	{
		name => 'discovered bishop check through en passant simplified',
		fen => '8/8/7k/K7/4pP2/8/8/2B5 b - g3 0 1',
		moves => [qw(h6h7 h6g7 h6g6 h6h5 e4e3)],
	},
	{
		name => 'queen check must be blocked',
		fen => 'r3k2Q/p1ppqp2/bn2p1pb/3PN3/1p2P3/2N4p/PPPBBPPP/R3K2R b KQq - 0 2',
		moves => [qw(h6f8 e7f8)],
	},
	{
		name => 'capture queen giving check',
		fen => 'r4rk1/p1ppqpbQ/bn2pnp1/3PN3/1p2P3/2N5/PPPBBPPP/R3K2R b KQ - 1 2',
		moves => [qw(g8h7 f6h7)],
	},
	{
		name => 'kiwipete perft bug',
		fen => 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
		premoves => [qw(e1f1 h3g2 f1e1)],
		moves => [qw(b4b3 g6g5 c7c6 d7d6 c7c5 g2h1q g2h1r g2h1b g2h1n g2g1q
			g2g1r g2g1b g2g1n e6d5 b4c3 b6a4 b6c4 b6d5 b6c8 f6e4 f6g4 f6d5
			f6h5 f6h7 f6g8 a6e2	a6d3 a6c4 a6b5 a6b7 a6c8 g7h6 g7f8 a8b8 a8c8
			a8d8 h8h2 h8h3 h8h4 h8h5 h8h6 h8h7 h8f8 h8g8 e7c5 e7d6 e7d8 e7f8
			e8d8 e8f8 e8g8 e8c8)],
	},
	{
		name => 'white pawn covers check',
		fen => 'r4rk1/1p3pp1/1q2b2p/1B2R3/1Q2n3/1K2PN2/1PP3PP/7R w - - 3 22',
		moves => [qw(e5e6 e5d5 b4c4 b5c4 c2c4)],
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	foreach my $movestr (@{$test->{premoves} || []}) {
		my $move = $pos->parseMove($movestr);
		ok $move, "$test->{name}: parse $movestr";
		ok $pos->doMove($move), "$test->{name}: premove $movestr should be legal";
	}
	my @moves = sort map { cp_move_coordinate_notation($_) } $pos->legalMoves;
	my @expect = sort @{$test->{moves}};
	is(scalar(@moves), scalar(@expect), "number of moves $test->{name}");
	is_deeply \@moves, \@expect, "$test->{name} same moves";
	if (@moves != @expect) {
		diag Dumper [sort @moves];
	}

	foreach my $move ($pos->legalMoves) {
		# Check the correct piece.
		my $from_mask = 1 << (cp_move_from $move);
		my $got_piece = cp_move_piece $move;
		my $piece;
		if ($from_mask & cp_pos_pawns($pos)) {
			$piece = CP_PAWN;
		} elsif ($from_mask & cp_pos_knights($pos)) {
			$piece = CP_KNIGHT;
		} elsif ($from_mask & cp_pos_bishops($pos)) {
			$piece = CP_BISHOP;
		} elsif ($from_mask & cp_pos_rooks($pos)) {
			$piece = CP_ROOK;
		} elsif ($from_mask & cp_pos_queens($pos)) {
			$piece = CP_QUEEN;
		} elsif ($from_mask & cp_pos_kings($pos)) {
			$piece = CP_KING;
		} else {
			die "Move $move piece is $got_piece, but no match with bitboards\n";
		}

		my $movestr = cp_move_coordinate_notation $move;
		is(cp_move_piece($move), $piece,
			"$test->{name} correct piece for $movestr");

		my $her_pieces = $pos->[CP_POS_WHITE_PIECES + !$pos->toMove];
		my $to = cp_move_to $move;
		my $to_mask = 1 << (cp_move_to $move);
		my $ep_shift = $pos->enPassantShift;
		# Check that the captured piece is set.
		if ($to_mask & $her_pieces
		    || ($ep_shift && $ep_shift == $to && $piece == CP_PAWN)) {
			ok(cp_move_captured($move),
				"$test->{name}: correct captured piece for $movestr");
		} else {
			ok(!cp_move_captured($move),
				"$test->{name}: no captured piece for $movestr");
		}

		is(cp_move_color($move), $pos->toMove,
			"$test->{name} correct color for $movestr");
	}
}

done_testing;
