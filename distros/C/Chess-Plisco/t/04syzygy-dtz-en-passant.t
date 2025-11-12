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

my $tb = Chess::Plisco::Tablebase::Syzygy->new('./t/syzygy');

my $pos;

# Loss without en passant.
$pos = Chess::Plisco->new('8/8/8/8/2pP4/2K5/4k3/8 b - d3 0 1');
is $tb->__probeDtzNoEP($pos), -1;

# Win with en passant.
is $tb->probeDtz($pos), 1;

done_testing;
