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

use Test::More tests => 13;
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

my ($pos, $move, $from, $to);

$pos = Chess::Plisco->new;

$move = 0;
$from = cp_square_to_shift 'e2';
$to = cp_square_to_shift 'e4';
cp_move_set_from $move, $from;
cp_move_set_to $move, $to;
cp_move_set_piece $move, CP_PAWN;
is(cp_move_from($move), $from, 'e2e4 from');
is(cp_move_to($move), $to, 'e2e4 to');
is(cp_move_promote($move), CP_NO_PIECE, 'e2e4 promote');
is(cp_move_coordinate_notation($move), 'e2e4', 'e2e4');

$pos = Chess::Plisco->new('k7/8/8/8/8/8/3p1K2/4N3 b - - 0 1');

$move = 0;
$from = cp_square_to_shift 'd2';
$to = cp_square_to_shift 'e1';
cp_move_set_from $move, $from;
cp_move_set_to $move, $to;
cp_move_set_piece $move, CP_PAWN;
cp_move_set_promote $move, CP_QUEEN;
is(cp_move_from($move), $from, 'd2e1q from');
is(cp_move_to($move), $to, 'd2e1q to');
is(cp_move_promote($move), CP_QUEEN, 'd2e1q promote');

# Full move.
$from = CP_D5;
$to = CP_E4;
cp_move_set_from $move, $from;
cp_move_set_to $move, $to;
cp_move_set_promote $move, CP_NO_PIECE;
cp_move_set_piece $move, CP_PAWN;
cp_move_set_captured $move, CP_KNIGHT;
cp_move_set_color $move, CP_BLACK;
is(cp_move_from($move), CP_D5);
is(cp_move_to($move), CP_E4);
is(cp_move_promote($move), CP_NO_PIECE);
is(cp_move_piece($move), CP_PAWN);
is(cp_move_captured($move), CP_KNIGHT);
is(cp_move_color($move), CP_BLACK);
