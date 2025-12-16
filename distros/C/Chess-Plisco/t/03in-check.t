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
use Data::Dumper;
use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!

my ($pos, @moves, @expect);

my @tests = (
	{
		name => 'start position',
	},
	{
		name => 'check by black knight',
		fen => '4k3/8/8/8/8/4n3/8/3K4 w - - 0 1',
		check => 1,
	},
	# FIXME! Add more tests here.
);

foreach my $test (@tests) {
	my $pos = Chess::Plisco->new($test->{fen});

	my @check_info = $pos->inCheck;

	if ($test->{check}) {
		ok $check_info[0];
	} else {
		ok !$check_info[0];
	}
}

done_testing;
