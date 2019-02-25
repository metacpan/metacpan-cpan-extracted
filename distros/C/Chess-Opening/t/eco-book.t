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
		fen => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq',
		moves => [
			'a2a3',
			'a2a4',
			'b1a3',
			'b1c3',
			'b2b3',
			'b2b4',
			'c2c3',
			'c2c4',
			'd2d3',
			'd2d4',
			'e2e3',
			'e2e4',
			'f2f3',
			'f2f4',
			'g1f3',
			'g1h3',
			'g2g3',
			'g2g4',
			'h2h3',
			'h2h4',
		],
		eco => 'A00',
		xeco => 'A00a',
		variation => 'Start',
	},
	{
		fen => 'rnbqkbnr/pppp1ppp/8/4p3/8/5P2/PPPPP1PP/RNBQKBNR w KQkq',
		moves => [
			'e1f2',
		],
		eco => 'A00',
		xeco => 'A00b',
		variation => 'Barnes Opening',
	},
	{
		fen => 'rnbqr1k1/pp3pbp/3p1np1/2pP4/4P3/2N2N2/PP2BPPP/R1BQ1RK1 w -',
		moves => [
				'd1c2',
				'f3d2',
		],
		eco => 'A76',
		xeco => 'A76',
		variation => 'Benoni: Classical, Main Line',
	},
);

foreach my $tc (@test_cases) {
	my $fen = $tc->{fen};

	my $entry = $book->lookupFEN($fen);
	ok $entry, "FEN: $fen";
	ok ref $entry;
	ok $entry->isa('Chess::Opening::ECO::Entry');

	is $entry->eco, $tc->{eco}, $fen;
	is $entry->xeco, $tc->{xeco}, $fen;
	is $entry->variation, $tc->{variation}, $fen;
	is $entry->counts,  scalar @{$tc->{moves}}, "FEN: $fen";
	is $entry->weights,  scalar @{$tc->{moves}}, "FEN: $fen";

	my $moves = $entry->moves;
	foreach my $move (@{$tc->{moves}}) {
		is $moves->{$move}->move, $move, "FEN: $fen";
		is $moves->{$move}->learn, 0, "FEN: $fen";
		is $moves->{$move}->count, 1, "FEN: $fen";
	}
}

done_testing;
