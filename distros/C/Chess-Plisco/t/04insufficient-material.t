#! /usr/bin/env perl

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
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
# Macros from Chess::Plisco::Macro are already expanded here!

my @tests = (
	{
		name => 'nothing',
		fen => 'k7/8/8/8/8/8/8/7K w - - 10 20',
		draw => 1,
	},
	{
		name => 'white queen',
		fen => 'k7/8/8/8/8/8/8/6QK w - - 10 20',
		draw => 0,
	},
	{
		name => 'black queen',
		fen => 'kq6/8/8/8/8/8/8/7K w - - 10 20',
		draw => 0,
	},
	{
		name => 'white rook',
		fen => 'k7/8/8/8/8/8/8/6RK w - - 10 20',
		draw => 0,
	},
	{
		name => 'black rook',
		fen => 'kr6/8/8/8/8/8/8/7K w - - 10 20',
		draw => 0,
	},
	{
		name => 'white pawn',
		fen => 'k7/p7/8/8/8/8/8/7K w - - 10 20',
		draw => 0,
	},
	{
		name => 'black pawn',
		fen => 'k7/8/8/8/8/8/7p/7K w - - 10 20',
		draw => 0,
	},
	{
		fen => '7k/8/8/8/8/8/8/KBB5 w - - 10 20',
		name => 'KBB vs. k',
		draw => 0,
	},
	{
		fen => '5bbk/8/8/8/8/8/8/K7 w - - 10 20',
		name => 'K vs. kbb',
		draw => 0,
	},
	{
		fen => '7k/8/8/8/8/8/8/KNN5 w - - 10 20',
		name => 'KNN vs. k',
		draw => 0,
	},
	{
		fen => '7k/8/8/8/8/8/8/KNN5 w - - 10 20',
		name => 'KNN vs. k',
		forcible => 1,
		draw => 1,
	},
	{
		fen => '5nnk/8/8/8/8/8/8/K7 w - - 10 20',
		name => 'K vs. knn',
		draw => 0,
	},
	{
		fen => '5nnk/8/8/8/8/8/8/K7 w - - 10 20',
		name => 'K vs. knn',
		forcible => 1,
		draw => 1,
	},
	{
		fen => '5bnk/8/8/8/8/8/8/KBN5 w - - 10 20',
		name => 'KBN vs. kbn',
		draw => 0,
	},
	{
		fen => '5bnk/8/8/8/8/8/8/K1N5 w - - 10 20',
		name => 'KN vs. kbn',
		draw => 0,
	},
	{
		fen => '5bnk/8/8/8/8/8/8/KB6 w - - 10 20',
		name => 'KB vs. kbn',
		draw => 0,
	},
	{
		fen => '5bnk/8/8/8/8/8/8/K7 w - - 10 20',
		name => 'K vs. kbn',
		draw => 0,
	},
	{
		fen => '6nk/8/8/8/8/8/8/KBN5 w - - 10 20',
		name => 'KBN vs. kn',
		draw => 0,
	},
	{
		fen => '6nk/8/8/8/8/8/8/K1N5 w - - 10 20',
		name => 'KN vs. kn',
		draw => 0,
	},
	{
		fen => '6nk/8/8/8/8/8/8/KB6 w - - 10 20',
		name => 'KB vs. kn',
		draw => 0,
	},
	{
		fen => '6nk/8/8/8/8/8/8/K7 w - - 10 20',
		name => 'K vs. kn',
		draw => 1,
	},
	{
		fen => '5b1k/8/8/8/8/8/8/KBN5 w - - 10 20',
		name => 'KBN vs. kb',
		draw => 0,
	},
	{
		fen => '5b1k/8/8/8/8/8/8/K1N5 w - - 10 20',
		name => 'KN vs. kb',
		draw => 0,
	},
	{
		fen => '5b1k/8/8/8/8/8/8/KB6 w - - 10 20',
		name => 'KB vs. kb (different-coloured bishop pair)',
		draw => 0,
	},
	{
		fen => '6bk/8/8/8/8/8/8/KB6 w - - 10 20',
		name => 'KB vs. kb (same-coloured bishop pair)',
		draw => 1,
	},
	{
		fen => '6bk/8/8/8/8/8/8/K1B5 w - - 10 20',
		name => 'KB vs. kb',
		draw => 0,
	},
	{
		fen => '5b1k/8/8/8/8/8/8/K1B5 w - - 10 20',
		name => 'KB vs. kb',
		draw => 1,
	},
	{
		fen => '5b1k/8/8/8/8/8/8/K7 w - - 10 20',
		name => 'K vs. kb',
		draw => 1,
	},
	{
		fen => '7k/8/8/8/8/8/8/KBN5 w - - 10 20',
		name => 'KBN vs. k',
		draw => 0,
	},
	{
		fen => '7k/8/8/8/8/8/8/K1N5 w - - 10 20',
		name => 'KN vs. k',
		draw => 1,
	},
	{
		fen => '7k/8/8/8/8/8/8/KB6 w - - 10 20',
		name => 'KB vs. k',
		draw => 1,
	},
	{
		fen => '7k/8/8/8/8/8/8/K7 w - - 10 20',
		name => 'K vs. k',
		draw => 1,
	},

	# Edge cases.
	{
		fen => '7k/8/8/3N4/3N4/4K3/8/8 w - - 0 1',
		name => 'KN vs. Kn (forcible)',
		forcible => 1, # Non-forcible already tested.
		draw => 1,
	},
	{
		fen => '3bk3/8/8/8/8/8/8/3BK3 w - - 0 1',
		name => 'KB vs. Kb (different-coloured, forcible)',
		forcible => 1, # Non-forcible already tested.
		draw => 1,
	},
	{
		fen => '7k/8/8/3B4/8/3BK3/8/8 w - - 0 1',
		name => 'KBB vs. K (same-coloured bishopss)',
		draw => 1,
	},
	{
		fen => '7k/8/8/3B4/8/3BK3/8/8 w - - 0 1',
		name => 'KBB vs. K (same-coloured bishopss)',
		forcible => 1,
		draw => 1,
	},
	{
		fen => '2b4k/1b1b4/8/3B4/8/3BK3/2B5/8 w - - 0 1',
		name => 'KBBB vs. Kbbb (same-coloured bishops)',
		draw => 1,
	},
	{
		fen => '2b4k/1b1b4/8/3B4/8/3BK3/2B5/8 w - - 0 1',
		name => 'KBBB vs. Kbbb (same-coloured bishops)',
		draw => 1,
		forcible => 1,
	},
	{
		fen => '8/1K6/1b6/8/8/4n3/2k5/8 b - - 0 1',
		name => 'KBN vs. K',
		draw => 0,
	},
	{
		fen => '8/1K6/1b6/8/8/4n3/2k5/8 b - - 0 1',
		name => 'KBN vs. K (forcible)',
		draw => 0,
		forcible => 1,
	}
);

plan tests => scalar @tests;

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});
	my $forcible = $test->{forcible} ? ' (forcible)' : '';
	if ($test->{draw}) {
		ok $pos->insufficientMaterial($test->{forcible}), "$test->{name} should be draw$forcible";
	} else {
		ok !$pos->insufficientMaterial($test->{forcible}), "$test->{name} should not be draw$forcible";
	}
}

