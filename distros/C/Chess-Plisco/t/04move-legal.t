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
use Time::HiRes qw(gettimeofday);

sub make_move;

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'e4 after start position',
		before => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		move => 'e2e4',
		legal => 1,
	},
	{
		name => 'Bc4 from start position',
		before => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		move => 'f1c4',
		legal => 0,
	},
	{
		name => 'king must move, no capture',
		before => '5k2/2r5/8/8/6N1/4b3/8/2K2N1r w - - 0 1',
		move => 'g4e3',
		legal => 0,
	},
	{
		name => 'knight is pinned',
		before => '5k2/8/8/8/8/6b1/8/2K2N1r w - - 0 1',
		move => 'f1g3',
		legal => 0,
	},
);

plan tests => @tests << 1;

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{before});
	my $move = make_move $pos, $test->{move};
	ok $move, "$test->{name}: parse $test->{move}";

	if ($test->{legal}) {
		ok $pos->moveLegal($move), "$test->{name}: $test->{move} legal";
	} else {
		ok !$pos->moveLegal($move), "$test->{name}: $test->{move} illegal";
	}
}

sub make_move {
	my ($pos, $coordinates) = @_;

	return if $coordinates !~ /^([a-h][1-8])([a-h][1-8])([qrbn])?$/;

	my ($from_square, $to_square, $promote) = ($1, $2, $3);
	my $move = 0;
	cp_move_set_from($move, $pos->squareToShift($from_square));
	cp_move_set_to($move, $pos->squareToShift($to_square));
	if ($promote) {
		my %pieces = (
			q => CP_QUEEN,
			r => CP_ROOK,
			b => CP_BISHOP,
			n => CP_KNIGHT,
		);
		cp_move_set_promote($move, $pieces{$promote});
	}

	cp_move_set_piece($move, $pos->pieceAtSquare($from_square));

	return $move;
}
