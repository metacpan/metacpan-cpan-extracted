#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More tests => 9;
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

my $pos = Chess::Plisco->new;
ok $pos, 'created';
is($pos->kingShift, CP_E1, 'initial white');
my $move = $pos->parseMove('e4');
ok $move, 'move e4';
ok $pos->doMove($move), 'doMove e4';
is($pos->kingShift, CP_E8, 'after 1. e4');

$pos = Chess::Plisco->new('8/8/4k3/5P2/8/8/8/K7 w - - 0 1');
ok $pos, 'created';
is($pos->kingShift, CP_A1, 'white king on a1');

$pos = Chess::Plisco->new('8/8/4k3/5P2/8/8/8/K7 b - - 0 1');
ok $pos, 'created';
is($pos->kingShift, CP_E6, 'black king on e6');
