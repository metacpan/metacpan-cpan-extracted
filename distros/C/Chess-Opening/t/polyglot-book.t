#! /usr/bin/env perl

# Copyright (C) 2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use common::sense;

use Test::More;

use Chess::Opening::Book::Polyglot;
use Chess::Opening::Book::Entry;

# This opening book comes from a collection of 998 games of Salo Flohr
# with a maximum depth of 4 plies.  It is for testing only!
my $book_file = 't/flohr.bin';

my $book = Chess::Opening::Book::Polyglot->new($book_file);
ok $book;
ok $book->isa('Chess::Opening::Book');

my @test_cases = (
	{
		fen => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		moves => [
			{
				move => 'd2d4',
				count => 612,
			},
			{
				move => 'e2e4',
				count => 185,
			},
			{
				move => 'g1f3',
				count => 167,
			},
			{
				move => 'c2c4',
				count => 103,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1',
		moves => [
			{
				move => 'g8f6',
				count => 232,
			},
			{
				move => 'd7d5',
				count => 198,
			},
			{
				move => 'e7e6',
				count => 29,
			},
			{
				move => 'f7f5',
				count => 11,
			},
			{
				move => 'd7d6',
				count => 3,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
		moves => [
			{
				move => 'c7c6',
				count => 146,
			},
			{
				move => 'e7e5',
				count => 34,
			},
			{
				move => 'c7c5',
				count => 32,
			},
			{
				move => 'g8f6',
				count => 19,
			},
			{
				move => 'e7e6',
				count => 16,
			},
			{
				move => 'b8c6',
				count => 5,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq - 1 1',
		moves => [
			{
				move => 'g8f6',
				count => 50,
			},
			{
				move => 'd7d5',
				count => 47,
			},
			{
				move => 'e7e6',
				count => 5,
			},
			{
				move => 'c7c5',
				count => 4,
			},
			{
				move => 'g7g6',
				count => 4,
			},
			{
				move => 'd7d6',
				count => 1,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR b KQkq c3 0 1',
		moves => [
			{
				move => 'e7e5',
				count => 28,
			},
			{
				move => 'g8f6',
				count => 19,
			},
			{
				move => 'c7c5',
				count => 4,
			},
			{
				move => 'e7e6',
				count => 2,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/3P4/8/PPP1PPPP/RNBQKBNR w KQkq - 1 2',
		moves => [
			{
				move => 'c2c4',
				count => 269,
			},
			{
				move => 'g1f3',
				count => 48,
			},
		],
	},
	{
		fen => 'rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w KQkq d6 0 2',
		moves => [
			{
				move => 'c2c4',
				count => 192,
			},
			{
				move => 'g1f3',
				count => 61,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/3P4/8/PPP1PPPP/RNBQKBNR w KQkq - 0 2',
		moves => [
			{
				move => 'c2c4',
				count => 17,
			},
			{
				move => 'e2e4',
				count => 3,
			},
			{
				move => 'b1d2',
				count => 3,
			},
			{
				move => 'g1f3',
				count => 2,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/2p5/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
		moves => [
			{
				move => 'd2d4',
				count => 61,
			},
			{
				move => 'b1c3',
				count => 26,
			},
			{
				move => 'g1f3',
				count => 10,
			},
			{
				move => 'c2c4',
				count => 6,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
		moves => [
			{
				move => 'g1f3',
				count => 28,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2',
		moves => [
			{
				move => 'g1f3',
				count => 12,
			},
			{
				move => 'b1c3',
				count => 4,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 1 2',
		moves => [
			{
				move => 'e4e5',
				count => 7,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
		moves => [
			{
				move => 'd2d4',
				count => 24,
			},
		],
	},
	{
		fen => 'r1bqkbnr/pppppppp/2n5/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 1 2',
		moves => [
			{
				move => 'd2d4',
				count => 5,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/8/5N2/PPPPPPPP/RNBQKB1R w KQkq - 2 2',
		moves => [
			{
				move => 'c2c4',
				count => 73,
			},
			{
				move => 'g2g3',
				count => 1,
			},
		],
	},
	{
		fen => 'rnbqkbnr/ppp1pppp/8/3p4/8/5N2/PPPPPPPP/RNBQKB1R w KQkq d6 0 2',
		moves => [
			{
				move => 'd2d4',
				count => 21,
			},
			{
				move => 'e2e3',
				count => 17,
			},
			{
				move => 'c2c4',
				count => 11,
			},
			{
				move => 'g2g3',
				count => 3,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/8/5N2/PPPPPPPP/RNBQKB1R w KQkq - 0 2',
		moves => [
			{
				move => 'c2c4',
				count => 4,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/8/2p5/8/5N2/PPPPPPPP/RNBQKB1R w KQkq c6 0 2',
		moves => [
			{
				move => 'c2c4',
				count => 6,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppppp1p/6p1/8/8/5N2/PPPPPPPP/RNBQKB1R w KQkq - 0 2',
		moves => [
			{
				move => 'd2d4',
				count => 6,
			},
			{
				move => 'c2c4',
				count => 6,
			},
		],
	},
	{
		fen => 'rnbqkbnr/ppp1pppp/3p4/8/8/5N2/PPPPPPPP/RNBQKB1R w KQkq - 0 2',
		moves => [
			{
				move => 'd2d4',
				count => 5,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/8/4p3/2P5/8/PP1PPPPP/RNBQKBNR w KQkq e6 0 2',
		moves => [
			{
				move => 'b1c3',
				count => 25,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/2P5/8/PP1PPPPP/RNBQKBNR w KQkq - 1 2',
		moves => [
			{
				move => 'b1c3',
				count => 30,
			},
			{
				move => 'g1f3',
				count => 8,
			},
			{
				move => 'd2d4',
				count => 4,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/8/2p5/2P5/8/PP1PPPPP/RNBQKBNR w KQkq c6 0 2',
		moves => [
			{
				move => 'g1f3',
				count => 3,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/2P5/8/PP1PPPPP/RNBQKBNR w KQkq - 0 2',
		moves => [
			{
				move => 'b1c3',
				count => 12,
			},
			{
				move => 'g1f3',
				count => 5,
			},
			{
				move => 'd2d4',
				count => 5,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2',
		moves => [
			{
				move => 'e7e6',
				count => 97,
			},
			{
				move => 'g7g6',
				count => 79,
			},
			{
				move => 'd7d6',
				count => 15,
			},
			{
				move => 'c7c6',
				count => 8,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq - 2 2',
		moves => [
			{
				move => 'e7e6',
				count => 11,
			},
			{
				move => 'd7d5',
				count => 8,
			},
			{
				move => 'c7c5',
				count => 6,
			},
			{
				move => 'g7g6',
				count => 2,
			},
		],
	},
	{
		fen => 'rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2',
		moves => [
			{
				move => 'c7c6',
				count => 55,
			},
			{
				move => 'd5c4',
				count => 50,
			},
			{
				move => 'e7e6',
				count => 34,
			},
		],
	},
	{
		fen => 'rnbqkbnr/ppp1pppp/8/3p4/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq - 1 2',
		moves => [
			{
				move => 'g8f6',
				count => 56,
			},
			{
				move => 'e7e6',
				count => 8,
			},
			{
				move => 'c7c6',
				count => 6,
			},
			{
				move => 'c7c5',
				count => 3,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2',
		moves => [
			{
				move => 'f7f5',
				count => 14,
			},
			{
				move => 'g8f6',
				count => 4,
			},
			{
				move => 'f8b4',
				count => 2,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/3PP3/8/PPP2PPP/RNBQKBNR b KQkq e3 0 2',
		moves => [
			{
				move => 'd7d5',
				count => 17,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/3P4/8/PPPNPPPP/R1BQKBNR b KQkq - 1 2',
		moves => [
			{
				move => 'd7d5',
				count => 3,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq - 1 2',
		moves => [
			{
				move => 'f7f5',
				count => 6,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/2p5/8/3PP3/8/PPP2PPP/RNBQKBNR b KQkq d3 0 2',
		moves => [
			{
				move => 'd7d5',
				count => 93,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/2p5/8/4P3/2N5/PPPP1PPP/R1BQKBNR b KQkq - 1 2',
		moves => [
			{
				move => 'd7d5',
				count => 32,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/2p5/8/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
		moves => [
			{
				move => 'd7d5',
				count => 6,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/2p5/8/2P1P3/8/PP1P1PPP/RNBQKBNR b KQkq c3 0 2',
		moves => [
			{
				move => 'e7e6',
				count => 5,
			},
			{
				move => 'd7d5',
				count => 4,
			},
			{
				move => 'e7e5',
				count => 3,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
		moves => [
			{
				move => 'b8c6',
				count => 32,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
		moves => [
			{
				move => 'b8c6',
				count => 17,
			},
			{
				move => 'e7e6',
				count => 4,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/8/2p5/4P3/2N5/PPPP1PPP/R1BQKBNR b KQkq - 1 2',
		moves => [
			{
				move => 'b8c6',
				count => 6,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/4P3/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 2',
		moves => [
			{
				move => 'f6d5',
				count => 12,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/3PP3/8/PPP2PPP/RNBQKBNR b KQkq d3 0 2',
		moves => [
			{
				move => 'd7d5',
				count => 17,
			},
		],
	},
	{
		fen => 'r1bqkbnr/pppppppp/2n5/8/3PP3/8/PPP2PPP/RNBQKBNR b KQkq d3 0 2',
		moves => [
			{
				move => 'd7d5',
				count => 5,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/2P5/5N2/PP1PPPPP/RNBQKB1R b KQkq c3 0 2',
		moves => [
			{
				move => 'e7e6',
				count => 18,
			},
			{
				move => 'g7g6',
				count => 13,
			},
			{
				move => 'c7c6',
				count => 7,
			},
			{
				move => 'b7b6',
				count => 3,
			},
			{
				move => 'd7d6',
				count => 2,
			},
			{
				move => 'c7c5',
				count => 2,
			},
		],
	},
	{
		fen => 'rnbqkbnr/ppp1pppp/8/3p4/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq d3 0 2',
		moves => [
			{
				move => 'g8f6',
				count => 56,
			},
			{
				move => 'e7e6',
				count => 8,
			},
			{
				move => 'c7c6',
				count => 6,
			},
			{
				move => 'c7c5',
				count => 3,
			},
		],
	},
	{
		fen => 'rnbqkbnr/ppp1pppp/8/3p4/8/4PN2/PPPP1PPP/RNBQKB1R b KQkq - 0 2',
		moves => [
			{
				move => 'g8f6',
				count => 7,
			},
		],
	},
	{
		fen => 'rnbqkbnr/ppp1pppp/8/3p4/2P5/5N2/PP1PPPPP/RNBQKB1R b KQkq c3 0 2',
		moves => [
			{
				move => 'd5d4',
				count => 14,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/2P5/5N2/PP1PPPPP/RNBQKB1R b KQkq c3 0 2',
		moves => [
			{
				move => 'f7f5',
				count => 2,
			},
			{
				move => 'g8f6',
				count => 1,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/8/2p5/2P5/5N2/PP1PPPPP/RNBQKB1R b KQkq c3 0 2',
		moves => [
			{
				move => 'b8c6',
				count => 3,
			},
			{
				move => 'g8f6',
				count => 3,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppppp1p/6p1/8/2P5/5N2/PP1PPPPP/RNBQKB1R b KQkq c3 0 2',
		moves => [
			{
				move => 'f8g7',
				count => 2,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/8/4p3/2P5/2N5/PP1PPPPP/R1BQKBNR b KQkq - 1 2',
		moves => [
			{
				move => 'g8f6',
				count => 21,
			},
			{
				move => 'b8c6',
				count => 4,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/2P5/2N5/PP1PPPPP/R1BQKBNR b KQkq - 2 2',
		moves => [
			{
				move => 'e7e5',
				count => 6,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/2P5/5N2/PP1PPPPP/RNBQKB1R b KQkq - 2 2',
		moves => [
			{
				move => 'e7e6',
				count => 18,
			},
			{
				move => 'g7g6',
				count => 13,
			},
			{
				move => 'c7c6',
				count => 7,
			},
			{
				move => 'b7b6',
				count => 3,
			},
			{
				move => 'd7d6',
				count => 2,
			},
			{
				move => 'c7c5',
				count => 2,
			},
		],
	},
	{
		fen => 'rnbqkb1r/pppppppp/5n2/8/2PP4/8/PP2PPPP/RNBQKBNR b KQkq d3 0 2',
		moves => [
			{
				move => 'e7e6',
				count => 97,
			},
			{
				move => 'g7g6',
				count => 79,
			},
			{
				move => 'd7d6',
				count => 15,
			},
			{
				move => 'c7c6',
				count => 8,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pp1ppppp/8/2p5/2P5/5N2/PP1PPPPP/RNBQKB1R b KQkq - 1 2',
		moves => [
			{
				move => 'b8c6',
				count => 3,
			},
			{
				move => 'g8f6',
				count => 3,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/2P5/5N2/PP1PPPPP/RNBQKB1R b KQkq - 1 2',
		moves => [
			{
				move => 'f7f5',
				count => 2,
			},
			{
				move => 'g8f6',
				count => 1,
			},
		],
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/4p3/8/2PP4/8/PP2PPPP/RNBQKBNR b KQkq d3 0 2',
		moves => [
			{
				move => 'f7f5',
				count => 14,
			},
			{
				move => 'g8f6',
				count => 4,
			},
			{
				move => 'f8b4',
				count => 2,
			},
		],
	},
);

foreach my $tc (@test_cases) {
	my $fen = $tc->{fen};
	my $book_entry = Chess::Opening::Book::Entry->new($fen);

	foreach my $move (@{$tc->{moves}}) {
		$book_entry->addMove(%$move);
	}

	my $entry = $book->lookupFEN($fen);
	ok $entry, $fen;
	ok $entry->isa('Chess::Opening::Book::Entry');
	$tc->{got} = $entry;
	$tc->{wanted} = $book_entry;
	is_deeply $entry, $book_entry, $fen;
}

done_testing;
