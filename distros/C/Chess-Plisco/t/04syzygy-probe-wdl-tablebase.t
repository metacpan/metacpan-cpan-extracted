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

my $tb = Chess::Plisco::Tablebase::Syzygy->new('./t/syzygy', max_fds => 2);

my $pos;

$pos = Chess::Plisco->new('7k/6b1/6K1/8/8/8/8/3R4 b - - 12 7');
is $tb->probeWdl($pos), -2;

$pos = Chess::Plisco->new('7k/8/8/4K3/3B4/4B3/8/8 b - - 12 7"');
is $tb->probeWdl($pos), 0;

$pos = Chess::Plisco->new('7k/8/8/4K2B/8/4B3/8/8 w - - 12 7');
is $tb->probeWdl($pos), 2;

done_testing;
