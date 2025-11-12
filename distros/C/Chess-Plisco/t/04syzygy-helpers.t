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

use Chess::Plisco;
use Chess::Plisco::Tablebase::Syzygy;

my $pos = Chess::Plisco->new('8/8/8/5N2/5K2/2kB4/8/8 b - - 0 1');
is (Chess::Plisco::Tablebase::Syzygy::Testing->calc_key($pos), 'KBNvK', 'calc_key');

$pos = Chess::Plisco->new;
is(Chess::Plisco::Tablebase::Syzygy::Testing->calc_key($pos), 'KQRRBBNNPPPPPPPPvKQRRBBNNPPPPPPPP', 'initial key');
is(Chess::Plisco::Tablebase::Syzygy::Testing->calc_key($pos), 'KQRRBBNNPPPPPPPPvKQRRBBNNPPPPPPPP', 'initial key mirrored');

$pos = Chess::Plisco->new('8/8/5k2/8/3K4/2Q5/8/8 w - - 0 1');
is(Chess::Plisco::Tablebase::Syzygy::Testing->calc_key($pos), 'KQvK', 'regular key order');
is(Chess::Plisco::Tablebase::Syzygy::Testing->calc_key($pos, 1), 'KvKQ', 'mirrored key order');

is(Chess::Plisco::Tablebase::Syzygy::Testing->normalise_tablename('PNBRQKvK'), 'KQRBNPvK', 'normalise_tablename');
is(Chess::Plisco::Tablebase::Syzygy::Testing->normalise_tablename('PNBRQKvK', 1), 'KvKQRBNP', 'normalise_tablename mirrored');

is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(0), 0, 'offdiag(0)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(1), -1, 'offdiag(1)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(2), -2, 'offdiag(2)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(3), -3, 'offdiag(3)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(4), -4, 'offdiag(4)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(5), -5, 'offdiag(5)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(6), -6, 'offdiag(6)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(7), -7, 'offdiag(7)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(8), 1, 'offdiag(8)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(9), 0, 'offdiag(9)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(10), -1, 'offdiag(10)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(11), -2, 'offdiag(11)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(12), -3, 'offdiag(12)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(13), -4, 'offdiag(13)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(14), -5, 'offdiag(14)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(15), -6, 'offdiag(15)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(16), 2, 'offdiag(16)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(17), 1, 'offdiag(17)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(18), 0, 'offdiag(18)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(19), -1, 'offdiag(19)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(20), -2, 'offdiag(20)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(21), -3, 'offdiag(21)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(22), -4, 'offdiag(22)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(23), -5, 'offdiag(23)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(24), 3, 'offdiag(24)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(25), 2, 'offdiag(25)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(26), 1, 'offdiag(26)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(27), 0, 'offdiag(27)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(28), -1, 'offdiag(28)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(29), -2, 'offdiag(29)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(30), -3, 'offdiag(30)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(31), -4, 'offdiag(31)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(32), 4, 'offdiag(32)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(33), 3, 'offdiag(33)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(34), 2, 'offdiag(34)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(35), 1, 'offdiag(35)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(36), 0, 'offdiag(36)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(37), -1, 'offdiag(37)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(38), -2, 'offdiag(38)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(39), -3, 'offdiag(39)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(40), 5, 'offdiag(40)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(41), 4, 'offdiag(41)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(42), 3, 'offdiag(42)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(43), 2, 'offdiag(43)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(44), 1, 'offdiag(44)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(45), 0, 'offdiag(45)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(46), -1, 'offdiag(46)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(47), -2, 'offdiag(47)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(48), 6, 'offdiag(48)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(49), 5, 'offdiag(49)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(50), 4, 'offdiag(50)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(51), 3, 'offdiag(51)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(52), 2, 'offdiag(52)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(53), 1, 'offdiag(53)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(54), 0, 'offdiag(54)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(55), -1, 'offdiag(55)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(56), 7, 'offdiag(56)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(57), 6, 'offdiag(57)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(58), 5, 'offdiag(58)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(59), 4, 'offdiag(59)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(60), 3, 'offdiag(60)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(61), 2, 'offdiag(61)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(62), 1, 'offdiag(62)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->offdiag(63), 0, 'offdiag(63)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(0), 0, 'flipdiag(0)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(1), 8, 'flipdiag(1)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(2), 16, 'flipdiag(2)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(3), 24, 'flipdiag(3)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(4), 32, 'flipdiag(4)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(5), 40, 'flipdiag(5)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(6), 48, 'flipdiag(6)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(7), 56, 'flipdiag(7)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(8), 1, 'flipdiag(8)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(9), 9, 'flipdiag(9)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(10), 17, 'flipdiag(10)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(11), 25, 'flipdiag(11)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(12), 33, 'flipdiag(12)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(13), 41, 'flipdiag(13)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(14), 49, 'flipdiag(14)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(15), 57, 'flipdiag(15)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(16), 2, 'flipdiag(16)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(17), 10, 'flipdiag(17)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(18), 18, 'flipdiag(18)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(19), 26, 'flipdiag(19)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(20), 34, 'flipdiag(20)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(21), 42, 'flipdiag(21)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(22), 50, 'flipdiag(22)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(23), 58, 'flipdiag(23)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(24), 3, 'flipdiag(24)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(25), 11, 'flipdiag(25)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(26), 19, 'flipdiag(26)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(27), 27, 'flipdiag(27)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(28), 35, 'flipdiag(28)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(29), 43, 'flipdiag(29)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(30), 51, 'flipdiag(30)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(31), 59, 'flipdiag(31)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(32), 4, 'flipdiag(32)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(33), 12, 'flipdiag(33)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(34), 20, 'flipdiag(34)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(35), 28, 'flipdiag(35)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(36), 36, 'flipdiag(36)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(37), 44, 'flipdiag(37)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(38), 52, 'flipdiag(38)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(39), 60, 'flipdiag(39)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(40), 5, 'flipdiag(40)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(41), 13, 'flipdiag(41)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(42), 21, 'flipdiag(42)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(43), 29, 'flipdiag(43)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(44), 37, 'flipdiag(44)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(45), 45, 'flipdiag(45)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(46), 53, 'flipdiag(46)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(47), 61, 'flipdiag(47)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(48), 6, 'flipdiag(48)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(49), 14, 'flipdiag(49)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(50), 22, 'flipdiag(50)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(51), 30, 'flipdiag(51)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(52), 38, 'flipdiag(52)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(53), 46, 'flipdiag(53)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(54), 54, 'flipdiag(54)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(55), 62, 'flipdiag(55)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(56), 7, 'flipdiag(56)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(57), 15, 'flipdiag(57)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(58), 23, 'flipdiag(58)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(59), 31, 'flipdiag(59)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(60), 39, 'flipdiag(60)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(61), 47, 'flipdiag(61)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(62), 55, 'flipdiag(62)');
is(Chess::Plisco::Tablebase::Syzygy::Testing->flipdiag(63), 63, 'flipdiag(63)');

done_testing;
