#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;

use Chess::Plisco qw(:all);

my @tests = (
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
		move => 'e1g1',
		san => 'O-O',
		piece => CP_KING,
	},
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
		move => 'e1c1',
		san => 'O-O-O',
		piece => CP_KING,
	},
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
		move => 'e8g8',
		san => 'O-O',
		piece => CP_KING,
	},
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
		move => 'e8c8',
		san => 'O-O-O',
		piece => CP_KING,
	},
	{
		fen => 'r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1',
		move => 'e8e7',
		san => 'Ke7',
		piece => CP_KING,
	},
	{
		fen => 'r6r/4k3/3R4/r6r/R6R/8/3RK3/R6R w - - 0 1',
		move => 'a1a3',
		san => 'R1a3',
		piece => CP_ROOK,
	},
	{
		fen => 'r6r/4k3/3R4/r6r/R6R/8/3RK3/R6R w - - 0 1',
		move => 'a1c1',
		san => 'Rac1',
		piece => CP_ROOK,
	},
	{
		fen => 'r6r/4k3/3R4/r6r/R6R/8/3RK3/R6R w - - 0 1',
		move => 'a4d4',
		san => 'Ra4d4',
		piece => CP_ROOK,
	},
	{
		fen => 'r6r/4k3/3R4/r6r/R6R/8/3RK3/R6R w - - 0 1',
		move => 'd6e6',
		san => 'Re6+',
		piece => CP_ROOK,
	},
	{
		fen => 'kr6/qn6/8/1N6/8/8/4K3/8 w - - 0 1',
		move => 'b5c7',
		san => 'Nc7#',
		piece => CP_KNIGHT,
	},
	{
		fen => 'kr1b4/qnN5/8/8/8/8/4K3/8 b - - 0 1',
		move => 'd8c7',
		san => 'Bxc7',
		piece => CP_BISHOP,
		captured => CP_KNIGHT,
	},
	{
		fen => '3k4/8/8/4p3/3P4/8/8/3K4 w - e6 0 1',
		move => 'd4e5',
		san => 'dxe5',
		piece => CP_PAWN,
		captured => CP_PAWN,
	},
	{
		fen => '3k4/8/8/4p3/3P1P2/8/8/3K4 w - e6 0 1',
		move => 'f4e5',
		san => 'fxe5',
		piece => CP_PAWN,
		captured => CP_PAWN,
	},
	{
		fen => '3k4/8/8/3Pp3/8/8/8/3K4 w - e6 0 1',
		move => 'd5e6',
		san => 'dxe6',
		piece => CP_PAWN,
		captured => CP_PAWN,
	},
	{
		fen => '3k4/8/8/3PpP2/8/8/8/3K4 w - e6 0 1',
		move => 'f5e6',
		san => 'fxe6',
		piece => CP_PAWN,
		captured => CP_PAWN,
	},
	{
		fen => '4n2k/3P4/8/8/8/8/8/K7 w - - 0 1',
		move => 'd7e8q',
		san => 'dxe8=Q+',
		promote => CP_QUEEN,
		piece => CP_PAWN,
		captured => CP_KNIGHT,
	},
	{
		fen => '7k/8/8/8/3Pp3/8/8/K7 b - d3 0 1',
		move => 'e4d3',
		san => 'exd3',
		piece => CP_PAWN,
		captured => CP_PAWN,
	},
);

plan tests => 10 * @tests;

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	ok $pos, "valid FEN $test->{fen}";
	my $move = $pos->parseMove($test->{move});
	ok $move, "valid move $test->{move}";
	is $pos->SAN($move), $test->{san}, "$test->{move} -> $test->{san}";
	my %pieces = (
		q => CP_QUEEN,
		r => CP_ROOK,
		b => CP_BISHOP,
		n => CP_KNIGHT,
	);
	$test->{move} =~ /^([a-h][0-8])([a-h][0-8])([qrbn])?/i or die;
	my ($from_square, $to_square) = ($1, $2);
	my $from = $pos->squareToShift($from_square);
	my $to = $pos->squareToShift($to_square);
	my $promote = $pieces{$3} || CP_NO_PIECE;
	my $captured = $test->{captured} || CP_NO_PIECE;
	my $piece = $test->{piece} or die;
	my $color = $pos->toMove;

	is($pos->moveFrom($move), $from, "$test->{san} from");
	is($pos->moveTo($move), $to, "$test->{san} to");
	is($pos->movePromote($move), $promote, "$test->{san} promote");
	is($pos->movePiece($move), $piece, "$test->{san} piece");
	is($pos->moveCaptured($move), $captured, "$test->{san} captured");
	is($pos->moveColor($move), $color, "$test->{san} color");
	ok $pos->moveLegal($move), "$test->{san} legal";
}