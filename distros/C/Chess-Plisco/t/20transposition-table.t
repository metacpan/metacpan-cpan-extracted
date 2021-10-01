#! /usr/bin/env perl

# Copyright (C) 2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Analyze chess games in PGN format

use strict;

use Test::More tests => 9;

use Chess::Plisco::Engine::TranspositionTable;

my $tt = Chess::Plisco::Engine::TranspositionTable->new(1);
ok $tt, "create transposition table";

my $key = 0x415C0415C0415C0;
ok !$tt->probe($key), "failed probe on empty table";

my $test_depth = 5;
my $test_flags = TT_SCORE_EXACT;
my $test_value = 2304;
my $test_move = 1303;

my $test_alpha = 0;
my $test_beta = 1;

$tt->store($key, $test_depth, $test_flags, $test_value, $test_move);

my $value = $tt->probe($key, $test_depth - 1, $test_alpha, $test_beta);
ok ((defined $value), "table hit");
is $value, 2304, "value 2304";

$tt->resize(1);
ok ((!defined $tt->probe($key, $test_depth - 1, $test_alpha, $test_beta)),
	"table should be empty after resize");

$tt->store($key, $test_depth, $test_flags, $test_value, $test_move);
ok defined $tt->probe($key, $test_depth - 1, $test_alpha, $test_beta),
	"store again";

$tt->clear;
ok !defined $tt->probe($key, $test_depth - 1, $test_alpha, $test_beta),
	"table should be empty after clear";

$tt->store($key, $test_depth, $test_flags, $test_value, $test_move);
ok defined $tt->probe($key, $test_depth - 1, $test_alpha, $test_beta),
	"store again";
my $collision = $key % scalar @$tt;
ok !defined $tt->probe($collision, $test_depth - 1, $test_alpha, $test_beta),
	"type 2 collision";