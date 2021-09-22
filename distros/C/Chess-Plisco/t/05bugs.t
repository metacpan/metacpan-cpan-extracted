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

my ($pos, $move, $undo_info, $before);

$pos = Chess::Plisco->new;
$move = $pos->parseMove('g1h3');
ok $move, 'parse g1h3';
ok $pos->doMove($move), '1. Nh3';
$move = $pos->parseMove('h7h6');
ok $move, 'parse h7h6';
$undo_info = $pos->doMove($move), '1. ...h6';
ok $undo_info, '1. ...h6';
ok $pos->[CP_POS_PAWNS] & (CP_H_MASK & CP_6_MASK),
	'1. ...h6, pawn should be on h6';
ok $pos->undoMove($undo_info);
ok $pos->[CP_POS_PAWNS] & (CP_H_MASK & CP_7_MASK),
	'undo 1. ...h6, pawn should be back on h7';

# Typo. In-check was not undone correctly.
$pos = Chess::Plisco->new('rnbqkb1r/pppppppp/7n/8/8/7N/PPPPPPPP/RNBQKB1R w KQkq - 2 2');
$before = $pos->copy;
$move = $pos->parseMove('b1c3');
ok $move, 'parse b1c3';
$undo_info = $pos->doMove($move);
ok $undo_info;
ok $pos->undoMove($undo_info);
is "$pos", "$before";
ok $pos->equals($before);

# Queen moves were not undone correctly.
$pos = Chess::Plisco->new('rnbqkb1r/pppppppp/7n/8/8/4P3/PPPP1PPP/RNBQKBNR w KQkq - 1 2');
$before = $pos->copy;
$move = $pos->parseMove('d1e2');
ok $move, 'parse d1e2';
$undo_info = $pos->doMove($move);
ok $undo_info;
ok $pos->undoMove($undo_info);
is "$pos", "$before";
ok $pos->equals($before);

# 2. ...Bxh3 is not undone correctly.
$pos = Chess::Plisco->new('rnbqkbnr/ppp1pppp/3p4/8/7P/7R/PPPPPPP1/RNBQKBN1 b kq - 0 2');
$before = $pos->copy;
$move = $pos->parseMove('c8h3');
ok $move, 'parse c8h3';
is(cp_move_piece($move), CP_BISHOP);
$undo_info = $pos->doMove($move);
ok $undo_info;
ok $pos->undoMove($undo_info);
is "$pos", "$before";
ok $pos->equals($before);

done_testing;
