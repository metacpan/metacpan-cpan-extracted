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

use Chess::Opening::Book::ECO;
use Chess::Opening::ECO::Entry;
use POSIX;

BEGIN {
	delete $ENV{LANGUAGE};
	$ENV{LANG} = $ENV{LC_MESSAGES} = $ENV{LC_ALL} = 'C';
	POSIX::setlocale(POSIX::LC_ALL(), 'C');
}

my $book = Chess::Opening::Book::ECO->new;
ok $book;
ok $book->isa('Chess::Opening::Book');

my @test_cases = (
	{
		fen => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		moves => {
			'a2a3' => 'rnbqkbnr/pppppppp/8/8/8/P7/1PPPPPPP/RNBQKBNR b KQkq - 0 1',
			'a2a4' => 'rnbqkbnr/pppppppp/8/8/P7/8/1PPPPPPP/RNBQKBNR b KQkq a3 0 1',
			'b1a3' => 'rnbqkbnr/pppppppp/8/8/8/N7/PPPPPPPP/R1BQKBNR b KQkq - 1 1',
			'b1c3' => 'rnbqkbnr/pppppppp/8/8/8/2N5/PPPPPPPP/R1BQKBNR b KQkq - 1 1',
			'b2b3' => 'rnbqkbnr/pppppppp/8/8/8/1P6/P1PPPPPP/RNBQKBNR b KQkq - 0 1',
			'b2b4' => 'rnbqkbnr/pppppppp/8/8/1P6/8/P1PPPPPP/RNBQKBNR b KQkq b3 0 1',
			'c2c3' => 'rnbqkbnr/pppppppp/8/8/8/2P5/PP1PPPPP/RNBQKBNR b KQkq - 0 1',
			'c2c4' => 'rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR b KQkq c3 0 1',
			'd2d3' => 'rnbqkbnr/pppppppp/8/8/8/3P4/PPP1PPPP/RNBQKBNR b KQkq - 0 1',
			'd2d4' => 'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1',
			'e2e3' => 'rnbqkbnr/pppppppp/8/8/8/4P3/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
			'e2e4' => 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
			'f2f3' => 'rnbqkbnr/pppppppp/8/8/8/5P2/PPPPP1PP/RNBQKBNR b KQkq - 0 1',
			'f2f4' => 'rnbqkbnr/pppppppp/8/8/5P2/8/PPPPP1PP/RNBQKBNR b KQkq f3 0 1',
			'g1f3' => 'rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq - 1 1',
			'g1h3' => 'rnbqkbnr/pppppppp/8/8/8/7N/PPPPPPPP/RNBQKB1R b KQkq - 1 1',
			'g2g3' => 'rnbqkbnr/pppppppp/8/8/8/6P1/PPPPPP1P/RNBQKBNR b KQkq - 0 1',
			'g2g4' => 'rnbqkbnr/pppppppp/8/8/6P1/8/PPPPPP1P/RNBQKBNR b KQkq g3 0 1',
			'h2h3' => 'rnbqkbnr/pppppppp/8/8/8/7P/PPPPPPP1/RNBQKBNR b KQkq - 0 1',
			'h2h4' => 'rnbqkbnr/pppppppp/8/8/7P/8/PPPPPPP1/RNBQKBNR b KQkq h3 0 1',
		},
		eco => 'A00',
		xeco => 'A00a',
		variation => 'Start',
	},
	{
		fen => 'rnbqr1k1/pp3pbp/3p1np1/2pP4/4P3/2N2N2/PP2BPPP/R1BQ1RK1 w - - 6 10',
		moves => {
				'd1c2' => 'rnbqr1k1/pp3pbp/3p1np1/2pP4/4P3/2N2N2/PPQ1BPPP/R1B2RK1 b - - 7 10',
				'f3d2' => 'rnbqr1k1/pp3pbp/3p1np1/2pP4/4P3/2N5/PP1NBPPP/R1BQ1RK1 b - - 7 10',
		},
		eco => 'A76',
		xeco => 'A76',
		variation => 'Benoni: Classical, Main Line',
	},
);

foreach my $tc (@test_cases) {
	my $fen = $tc->{fen};

	my $entry = $book->lookupFEN($fen);
	ok $entry, "FEN: $fen";
	ok $entry->isa('Chess::Opening::ECO::Entry');

	is $entry->fen, $fen;
	is $entry->eco, $tc->{eco}, $fen;
	is $entry->xeco, $tc->{xeco}, $fen;
	is $entry->variation, $tc->{variation}, $fen;
	is $entry->counts,  scalar keys %{$tc->{moves}}, "FEN: $fen";
	is $entry->weights,  scalar keys %{$tc->{moves}}, "FEN: $fen";

	my $moves = $entry->moves;

	foreach my $move (keys %{$tc->{moves}}) {
		is $moves->{$move}->move, $move, "FEN: $fen";
		is $moves->{$move}->learn, 0, "FEN: $fen";
		is $moves->{$move}->count, 1, "FEN: $fen";
	}
}

done_testing;
