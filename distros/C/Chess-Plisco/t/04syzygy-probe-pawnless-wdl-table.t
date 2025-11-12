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

my $wdl = Chess::Plisco::Tablebase::Syzygy::WdlTable->new('./t/syzygy/KBNvK.rtbw');

my $pos;

$pos = Chess::Plisco->new('8/8/8/5N2/5K2/2kB4/8/8 b - - 0 1');
is $wdl->probeWdlTable($pos), -2;

$pos = Chess::Plisco->new('7B/5kNK/8/8/8/8/8/8 w - - 0 1');
is $wdl->probeWdlTable($pos), 2;

$pos = Chess::Plisco->new('N7/8/2k5/8/7K/8/8/B7 w - - 0 1');
is $wdl->probeWdlTable($pos), 2;

$pos = Chess::Plisco->new('8/8/1NkB4/8/7K/8/8/8 w - - 1 1');
is $wdl->probeWdlTable($pos), 0;

$pos = Chess::Plisco->new('8/8/8/2n5/2b1K3/2k5/8/8 w - - 0 1');
is $wdl->probeWdlTable($pos), -2;

done_testing;
