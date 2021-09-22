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

use Test::More tests => 11;
use Chess::Plisco qw(:all);

ok 1, 'used';

my $pos = Chess::Plisco->new;
ok $pos, 'instantiated';

my $color = $pos->toMove;
is $color, CP_WHITE, 'white to move';

# The array is laid out in a way that allows efficient access to the
# pieces of the side to move and the side not to move and ...
is $pos->[CP_POS_WHITE_PIECES + $color], $pos->whitePieces, 'own pieces';
is $pos->[CP_POS_WHITE_PIECES + !$color], $pos->blackPieces, 'opponent pieces';

# ... and allows to use the type of a piece as an index into the instance
# for getting the corresponding bitboard of the piece without knowing the type.
is $pos->[CP_PAWN], $pos->pawns, 'pawns bitboard';
is $pos->[CP_KNIGHT], $pos->knights, 'knights bitboard';
is $pos->[CP_BISHOP], $pos->bishops, 'bishops bitboard';
is $pos->[CP_ROOK], $pos->rooks, 'rooks bitboard';
is $pos->[CP_QUEEN], $pos->queens, 'queens bitboard';
is $pos->[CP_KING], $pos->kings, 'kings bitboard';
