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
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;
use Chess::Plisco::Engine::Position;

use lib 't/lib';

use TreeFactory;

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'white go for draw by repetition',
		fen => '1rrk4/7q/4N3/8/8/8/8/K7 b - - 1 1',
		moves => [qw(d8e8 e6g5 e8d8 g5e6 d8e8 e6g5 e8d8)],
		bm => [qw(g5e6)],
		depth => 3,
	},
	{
		name => 'white do not go for draw by repetition',
		fen => '1rrk4/7q/4N3/8/8/8/8/K7 b - - 1 1',
		moves => [qw(d8e8 e6g5 e8d8)],
		am => [qw(g5e6)],
		depth => 3,
	},
);

foreach my $test (@tests) {
	my $factory = TreeFactory->new(%$test);
	my $tree = $factory->tree;
	my $best_move = $tree->think;
	my $position = $factory->position;
	my $best_move_cn = $position->moveCoordinateNotation($best_move);

	if ($test->{bm}) {
		my $bms = $test->{bm};
		my $found;
		foreach my $san (@$bms) {
			my $move = $position->parseMove($san);
			my $bm = $position->moveCoordinateNotation($move);
			if ($bm eq $best_move_cn) {
				$found = 1;
				last;
			}
		}

		ok $found, "$test->{name}: engine found $best_move_cn";
	} elsif ($test->{am}) {
		my $ams = $test->{am};
		my $found;
		foreach my $san (@$ams) {
			my $move = $position->parseMove($san);
			my $am = $position->moveCoordinateNotation($move);
			if ($am eq $best_move_cn) {
				$found = 1;
				last;
			}
		}

		ok !$found, "$test->{name}: engine found $best_move_cn";
	}
}

done_testing;
