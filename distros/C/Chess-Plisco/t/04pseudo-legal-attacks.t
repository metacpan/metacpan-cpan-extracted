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
# Macros from Chess::Plisco::Macro are already expanded here!

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'promotion bug',
		fen => 'r5k1/2Q3p1/p1n1q1p1/3p2P1/P7/7P/3p2PK/3q4 b - - 0 34',
		moves => [qw(e6h3 d1a4)],
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	foreach my $movestr (@{$test->{premoves} || []}) {
		my $move = $pos->parseMove($movestr);
		ok $move, "$test->{name}: parse $movestr";
		ok $pos->doMove($move), "$test->{name}: premove $movestr should be legal";
	}
	my @moves = sort map { chr(97 + ((($_ >> 6) & 0x3f) & 0x7)) . (1 + ((($_ >> 6) & 0x3f) >> 3)) . chr(97 + ((($_) & 0x3f) & 0x7)) . (1 + ((($_) & 0x3f) >> 3)) . CP_PIECE_CHARS->[CP_BLACK]->[(($_ >> 12) & 0x7)] } $pos->pseudoLegalAttacks;
	my @expect = sort @{$test->{moves}};
	is(scalar(@moves), scalar(@expect), "number of moves $test->{name}");
	is_deeply \@moves, \@expect, $test->{name};
	if (@moves != @expect) {
		diag Dumper [sort @moves];
	}

	foreach my $move ($pos->pseudoLegalMoves) {
		# Check the correct piece.
		my $from_mask = 1 << ((($move >> 6) & 0x3f));
		my $got_piece = (($move >> 15) & 0x7);
		my $piece;
		if ($from_mask & $pos->[CP_POS_PAWNS]) {
			$piece = CP_PAWN;
		} elsif ($from_mask & $pos->[CP_POS_KNIGHTS]) {
			$piece = CP_KNIGHT;
		} elsif ($from_mask & $pos->[CP_POS_BISHOPS]) {
			$piece = CP_BISHOP;
		} elsif ($from_mask & $pos->[CP_POS_ROOKS]) {
			$piece = CP_ROOK;
		} elsif ($from_mask & $pos->[CP_POS_QUEENS]) {
			$piece = CP_QUEEN;
		} elsif ($from_mask & $pos->[CP_POS_KINGS]) {
			$piece = CP_KING;
		} else {
			die "Move $move piece is $got_piece, but no match with bitboards\n";
		}

		my $movestr = chr(97 + ((($move >> 6) & 0x3f) & 0x7)) . (1 + ((($move >> 6) & 0x3f) >> 3)) . chr(97 + ((($move) & 0x3f) & 0x7)) . (1 + ((($move) & 0x3f) >> 3)) . CP_PIECE_CHARS->[CP_BLACK]->[(($move >> 12) & 0x7)];
		is((($move >> 15) & 0x7), $piece, "correct piece for $movestr");
	}
}

done_testing;
