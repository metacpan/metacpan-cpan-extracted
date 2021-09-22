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
		name => 'black king on f8 attacked by white queen on h8',
		move => 'e8f8',
		fen => 'r3k2Q/p1ppqp2/bn2p1pb/3PN3/1p2P3/2N4p/PPPBBPPP/R3K2R b KQq - 0 2',
		attacked => 1,
	},
	{
		name => 'black king on d8 attacked by white queen on h8',
		move => 'e8d8',
		fen => 'r3k2Q/p1ppqp2/bn2p1pb/3PN3/1p2P3/2N4p/PPPBBPPP/R3K2R b KQq - 0 2',
		attacked => 1,
	},
	{
		name => 'attacked by white king',
		move => 'd4e3',
		fen => '8/7p/p5pb/8/P1pk4/8/P2n1KPP/1r3R2 b - - 1 30',
		attacked => 1,
	},

);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	my $move = $pos->parseMove($test->{move});
	ok $move, "parse $test->{move}";

	if ($test->{attacked}) {
		ok $pos->moveAttacked($move), $test->{name};
	} else {
		ok !$pos->moveAttacked($move), $test->{name};
	}
}

done_testing;
