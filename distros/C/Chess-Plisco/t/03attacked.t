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
		name => 'attacked by white pawn',
		square => 'd4',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 b - - 0 1',
		attacked => 1,
	},
	{
		name => 'reachable by white pawn',
		square => 'c4',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 b - - 0 1',
		attacked => 0,
	},
	{
		name => 'attacked by black pawn',
		square => 'd5',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 w - - 0 1',
		attacked => 1,
	},
	{
		name => 'reachable by black pawn',
		square => 'c5',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 w - - 0 1',
		attacked => 0,
	},
	{
		name => 'attacked by white bishop',
		square => 'd5',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 b - - 0 1',
		attacked => 1,
	},
	{
		name => 'captured by white bishop',
		square => 'c6',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 b - - 0 1',
		attacked => 1,
	},
	{
		name => 'not attacked by white bishop',
		square => 'b7',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 b - - 0 1',
		attacked => 0,
	},
	{
		name => 'attacked by black knight',
		square => 'd5',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 w - - 0 1',
		attacked => 1,
	},
	{
		name => 'captured by black knight',
		square => 'e6',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 w - - 0 1',
		attacked => 1,
	},
	{
		name => 'attacked by white rook',
		square => 'd6',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 b - - 0 1',
		attacked => 1,
	},
	{
		name => 'captured by white rook',
		square => 'c6',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 b - - 0 1',
		attacked => 1,
	},
	{
		name => 'not attacked by white rook',
		square => 'b6',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 b - - 0 1',
		attacked => 0,
	},
	{
		name => 'attacked by black queen',
		square => 'h3',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 w - - 0 1',
		attacked => 1,
	},
	{
		name => 'captured by black queen',
		square => 'f3',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 w - - 0 1',
		attacked => 1,
	},
	{
		name => 'not attacked by black queen',
		square => 'e3',
		fen => '7k/2n5/2p1R3/8/8/2P2Bq1/2K5/8 w - - 0 1',
		attacked => 0,
	},
	{
		name => 'attacked by white king',
		square => 'e3',
		fen => '8/7p/p5pb/8/P1pk4/8/P2n1KPP/1r3R2 b - - 1 30',
		attacked => 1,
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	my $shift = $pos->squareToShift($test->{square});

	if ($test->{attacked}) {
		ok $pos->attacked($shift), $test->{name};
	} else {
		ok !$pos->attacked($shift), $test->{name};
	}
}

done_testing;
