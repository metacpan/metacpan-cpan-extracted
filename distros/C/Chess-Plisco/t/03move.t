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

use Test::More tests => 13;
use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!

my ($pos, $move, $from, $to);

$pos = Chess::Plisco->new;

$move = 0;
$from = (((substr 'e2', 1) - 1) << 3) + ord('e2') - 97;
$to = (((substr 'e4', 1) - 1) << 3) + ord('e4') - 97;
(($move) = (($move) & ~0x7e00) | (($from)) << 9);
(($move) = (($move) & ~0x1f8000) | (($to)) << 15);
(($move) = (($move) & ~0x7) | (CP_PAWN));
is(((($move) >> 9) & 0x3f), $from, 'e2e4 from');
is(((($move) >> 15) & 0x3f), $to, 'e2e4 to');
is(((($move) >> 6) & 0x7), CP_NO_PIECE, 'e2e4 promote');
is(chr(97 + (((($move) >> 9) & 0x3f) & 0x7)) . (1 + (((($move) >> 9) & 0x3f) >> 3)) . chr(97 + (((($move) >> 15) & 0x3f) & 0x7)) . (1 + (((($move) >> 15) & 0x3f) >> 3)) . CP_PIECE_CHARS->[CP_BLACK]->[((($move) >> 6) & 0x7)], 'e2e4', 'e2e4');

$pos = Chess::Plisco->new('k7/8/8/8/8/8/3p1K2/4N3 b - - 0 1');

$move = 0;
$from = (((substr 'd2', 1) - 1) << 3) + ord('d2') - 97;
$to = (((substr 'e1', 1) - 1) << 3) + ord('e1') - 97;
(($move) = (($move) & ~0x7e00) | (($from)) << 9);
(($move) = (($move) & ~0x1f8000) | (($to)) << 15);
(($move) = (($move) & ~0x7) | (CP_PAWN));
(($move) = (($move) & ~0x1c0) | ((CP_QUEEN)) << 6);
is(((($move) >> 9) & 0x3f), $from, 'd2e1q from');
is(((($move) >> 15) & 0x3f), $to, 'd2e1q to');
is(((($move) >> 6) & 0x7), CP_QUEEN, 'd2e1q promote');

# Full move.
$from = CP_D5;
$to = CP_E4;
(($move) = (($move) & ~0x7e00) | (($from)) << 9);
(($move) = (($move) & ~0x1f8000) | (($to)) << 15);
(($move) = (($move) & ~0x1c0) | ((CP_NO_PIECE)) << 6);
(($move) = (($move) & ~0x7) | (CP_PAWN));
(($move) = (($move) & ~0x38) | ((CP_KNIGHT)) << 3);
(($move) = (($move) & ~0x200000) | ((CP_BLACK)) << 21);
is(((($move) >> 9) & 0x3f), CP_D5);
is(((($move) >> 15) & 0x3f), CP_E4);
is(((($move) >> 6) & 0x7), CP_NO_PIECE);
is((($move) & 0x7), CP_PAWN);
is(((($move) >> 3) & 0x7), CP_KNIGHT);
is(((($move) >> 21) & 0x1), CP_BLACK);
