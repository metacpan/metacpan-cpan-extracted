#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

my $fen;

my $pos = Chess::Plisco->new;

# Regular white piece move.
is $pos->moveCoordinateNotation($pos->parseMove("Nc3")), "b1c3", "Nc3";
is $pos->moveCoordinateNotation($pos->parseMove("b1c3")), "b1c3", "b1c3";
is $pos->moveCoordinateNotation($pos->parseMove("Nb1-c3")), "b1c3", "Nb1-c3";

# Pawn double step.
is $pos->moveCoordinateNotation($pos->parseMove("e4")), "e2e4", "e4";
is $pos->moveCoordinateNotation($pos->parseMove("e2e4")), "e2e4", "e2e4";
is $pos->moveCoordinateNotation($pos->parseMove("e2-e4")), "e2e4", "e2-e4";

# Pawn single step.
is $pos->moveCoordinateNotation($pos->parseMove("e3")), "e2e3", "e4";
is $pos->moveCoordinateNotation($pos->parseMove("e2e3")), "e2e3", "e2e3";
is $pos->moveCoordinateNotation($pos->parseMove("e2-e3")), "e2e3", "e2-e3";

# For the black moves, move first e4.
my $legal = $pos->doMove($pos->parseMove("e2e4"));
ok defined $legal, "do_move e2e4";

# Regular black piece move.
is $pos->moveCoordinateNotation($pos->parseMove("Nf6")), "g8f6", "Nf6";
is $pos->moveCoordinateNotation($pos->parseMove("g8f6")), "g8f6", "g8f6";
is $pos->moveCoordinateNotation($pos->parseMove("Ng8-f6")), "g8f6", "Ng8-f6";

# Pawn double step.
is $pos->moveCoordinateNotation($pos->parseMove("e5")), "e7e5", "e5";
is $pos->moveCoordinateNotation($pos->parseMove("e7e5")), "e7e5", "e7e5";
is $pos->moveCoordinateNotation($pos->parseMove("e7-e5")), "e7e5", "e7-e5";

# Pawn single step.
is $pos->moveCoordinateNotation($pos->parseMove("e6")), "e7e6", "e6";
is $pos->moveCoordinateNotation($pos->parseMove("e7e6")), "e7e6", "e7e6";
is $pos->moveCoordinateNotation($pos->parseMove("e7-e6")), "e7e6", "e7-e6";

# Test the castling from this position.
#
#      a   b   c   d   e   f   g   h
#    +---+---+---+---+---+---+---+---+
#  8 | r |   |   |   | k |   |   | r | En passant not possible.
#    +---+---+---+---+---+---+---+---+ White king castle: yes.
#  7 | p | p | p |   | q | p | p | p | White queen castle: yes.
#    +---+---+---+---+---+---+---+---+ Black king castle: yes.
#  6 |   |   | n | b | b | n |   |   | Black queen castle: yes.
#    +---+---+---+---+---+---+---+---+ Half move clock (50 moves): 0.
#  5 |   |   |   | p | p |   |   |   | Half moves: 0.
#    +---+---+---+---+---+---+---+---+ Next move: white.
#  4 |   |   |   | P | P |   |   |   | Material: +0.
#    +---+---+---+---+---+---+---+---+ Black has castled: no.
#  3 |   |   | N | B | B | N |   |   | White has castled: no.
#    +---+---+---+---+---+---+---+---+
#  2 | P | P | P |   | Q | P | P | P |
#    +---+---+---+---+---+---+---+---+
#  1 | R |   |   |   | K |   |   | R |
#    +---+---+---+---+---+---+---+---+
#      a   b   c   d   e   f   g   h
#
$fen = "r3k2r/ppp1qppp/2nbbn2/3pp3/3PP3/2NBBN2/PPP1QPPP/R3K2R w KQkq - 0 1";
$pos = Chess::Plisco->new($fen);

is $pos->moveCoordinateNotation($pos->parseMove("O-O")), "e1g1", "white O-O";
is $pos->moveCoordinateNotation($pos->parseMove("0-o-O")), "e1c1", "white 0-o-O";

# Switch sides.
$fen = "r3k2r/ppp1qppp/2nbbn2/3pp3/3PP3/2NBBN2/PPP1QPPP/R3K2R b KQkq - 0 1";
$pos = Chess::Plisco->new($fen);

is $pos->moveCoordinateNotation($pos->parseMove("O-O")), "e8g8", "black O-O";
is $pos->moveCoordinateNotation($pos->parseMove("0-o-O")), "e8c8", "black 0-o-O";

# Parse promotions with captures.  That should cover everything.  The
# stress test is done, when parsing the moves from the PGN.
#
#      a   b   c   d   e   f   g   h
#    +---+---+---+---+---+---+---+---+
#  8 |   |   |   | R |   |   |   |   | En passant not possible.
#    +---+---+---+---+---+---+---+---+ White king castle: no.
#  7 |   |   | p |   |   |   |   | K | White queen castle: no.
#    +---+---+---+---+---+---+---+---+ Black king castle: no.
#  6 |   |   |   |   |   |   |   |   | Black queen castle: no.
#    +---+---+---+---+---+---+---+---+ Half move clock (50 moves): 0.
#  5 |   |   |   |   |   |   |   |   | Half moves: 0.
#    +---+---+---+---+---+---+---+---+ Next move: white.
#  4 |   |   |   |   |   |   |   |   | Material: -4.
#    +---+---+---+---+---+---+---+---+ Black has castled: no.
#  3 |   |   |   |   |   |   |   |   | White has castled: no.
#    +---+---+---+---+---+---+---+---+
#  2 | k |   |   |   |   | P |   |   |
#    +---+---+---+---+---+---+---+---+
#  1 |   |   |   |   |   |   | q |   |
#    +---+---+---+---+---+---+---+---+
#      a   b   c   d   e   f   g   h
#
$fen = "3q4/2P4k/8/8/8/8/K4p2/4R3 w - - 0 1";
$pos = Chess::Plisco->new($fen);

is $pos->moveCoordinateNotation($pos->parseMove("cxd8=Q")), "c7d8q", "cxd=Q";

$pos->doMove($pos->parseMove("c7d8q"));

# This is not officially SAN but can still be parsed successfully.
is $pos->moveCoordinateNotation($pos->parseMove("feb")), "f2e1b", "feb";

# Bug from pgn:
$fen = 'r4rk1/1p3pp1/1q2b2p/1B2R3/1Q2n3/1K2PN2/1PP3PP/7R w - - 3 22';
$pos = Chess::Plisco->new($fen);
is $pos->moveCoordinateNotation($pos->parseMove('c4')), 'c2c4', 'c4';

# En-passant notated.
$fen = '1b2q3/k7/p7/NpP5/4B3/6P1/5B1P/6K1 w - b6';
$pos = Chess::Plisco->new($fen);
is $pos->moveCoordinateNotation($pos->parseMove('cxb6ep#')), 'c5b6', 'cxb6ep#';

done_testing;
