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

use Test::More;

use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!
use Chess::Plisco::Engine::TranspositionTable;

my $tt = Chess::Plisco::Engine::TranspositionTable->new(1);
ok $tt, "create transposition table";

my $key = 0x415C0415C0415C0;
ok !$tt->probe($key), "failed probe on empty table";

my $test_ply = 3;
my $test_depth = 5;
my $test_flags = TT_SCORE_EXACT;
my $test_value = 2304;
my $test_move = 1303;

my $test_alpha = 0;
my $test_beta = 1;

$tt->store($key, $test_depth, $test_flags, $test_value, $test_move);

my $value = $tt->probe($key, 1, $test_depth - 1, $test_alpha, $test_beta);
ok ((defined $value), "table hit");
is $value, 2304, "value 2304";

$tt->resize(1);
ok ((!defined $tt->probe($key, 1, $test_depth - 1, $test_alpha, $test_beta)),
	"table should be empty after resize");

$tt->store($key, $test_depth, $test_flags, $test_value, $test_move);
ok defined $tt->probe($key, 1, $test_depth - 1, $test_alpha, $test_beta),
	"store again";

$tt->clear;
ok !defined $tt->probe($key, 1, $test_depth - 1, $test_alpha, $test_beta),
	"table should be empty after clear";

$tt->store($key, $test_depth, $test_flags, $test_value, $test_move);
ok defined $tt->probe($key, 1, $test_depth - 1, $test_alpha, $test_beta),
	"store again";
my $collision = $key % scalar @$tt;
ok !defined $tt->probe($collision, $test_ply, $test_depth - 1, $test_alpha, $test_beta),
	"type 2 collision";

$tt->clear;
my $real_move = 0;
my $from = CP_D7;
my $to = CP_E8;
my $promote = CP_ROOK;
(($real_move) = (($real_move) & ~0x7e00) | (($from)) << 9);
(($real_move) = (($real_move) & ~0x1f8000) | (($to)) << 15);
(($real_move) = (($real_move) & ~0x1c0) | (($promote)) << 6);

$tt->store($key, $test_depth, TT_SCORE_EXACT, $test_value, $real_move);

my $best_move;
my $value = $tt->probe($key, 1, $test_depth - 1, $test_alpha, $test_beta, \$best_move);
ok defined $value, "stored move retrieved";

ok defined $best_move, 'best move was returned';
is(((($best_move) >> 9) & 0x3f), $from, 'from square not tampered');
is(((($best_move) >> 15) & 0x3f), $to, 'to square not tampered');
is(((($best_move) >> 6) & 0x7), $promote, 'promote piece not tampered');

$tt->clear;
$tt->store($key, 0, TT_SCORE_EXACT, 42, $best_move);
ok !defined $tt->probe($key, $test_ply, 3, -100, 100, \$best_move),
	'table does not return quiescence entries during normal search';

# Mate handling.
my $mate_in_7 = Chess::Plisco::Engine::Tree::MATE + 7;
$tt->clear;
$tt->store($key, $test_depth, TT_SCORE_EXACT, Chess::Plisco::Engine::Tree::MATE,
	$best_move);
is $tt->probe($key, 7, $test_depth, -100, 100, \$best_move), $mate_in_7,
	'mate in 7';

done_testing;
