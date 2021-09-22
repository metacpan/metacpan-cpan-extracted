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
	# Castlings.
	{
		name => 'white pawn checks on f5',
		fen => '8/8/4k3/5P2/8/8/8/4K3 b - - 0 1',
		checkers => [(1 << (CP_F_MASK & CP_5_MASK))],
	},
	{
		name => 'black pawn checks on d5',
		fen => '8/8/3p4/2K5/8/8/6k1/8 w - - 0 1',
		checkers => [(1 << (CP_D_MASK & CP_5_MASK))],
	},
	{
		name => 'black knight checks on e6',
		fen => '8/8/3p4/2K5/8/8/6k1/8 w - - 0 1',
		checkers => [(1 << (CP_E_MASK & CP_6_MASK))],
	},
	{
		name => 'white bishop checks on c3',
		fen => '8/6q1/8/4k3/8/2B5/4K3/8 b - - 0 1',
		checkers => [(1 << (CP_C_MASK & CP_3_MASK))],
	},
	{
		name => 'black queen checks on g5',
		fen => '8/8/8/R2K2q1/8/8/5k2/8 w - - 0 1',
		checkers => [(1 << (CP_G_MASK & CP_5_MASK))],
	},
);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	ok cp_pos_in_check($pos), "$test->{name} wrong checkers mask"
}

done_testing;
