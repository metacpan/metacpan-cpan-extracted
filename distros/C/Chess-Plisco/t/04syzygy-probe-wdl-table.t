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

my $wdl = Chess::Plisco::Tablebase::Syzygy::WdlTable->new('./t/syzygy/KRvKP.rtbw');

my $pos;

$pos = Chess::Plisco->new('8/8/2K5/4P3/8/8/8/3r3k b - - 1 1');
is $wdl->probeWdlTable($pos), 0;

$pos = Chess::Plisco->new('8/8/2K5/8/4P3/8/8/3r3k b - - 1 1');
is $wdl->probeWdlTable($pos), 2;

# Blessed win. Happened to Magnus Carlson.
#$pos = Chess::Plisco->new('8/8/4k3/8/4K2p/7N/8/6N1 w - - 0 1');
#is $tb->probeWdlTable($pos), 1;

# Blessed loss.
#$pos = Chess::Plisco->new('8/6B1/8/8/B7/8/K1pk4/8 b - - 0 1');
#is $tb->probeWdl($pos), -1;

# Black escapes into a blessed loss with an underpromotion.
#$pos->applyMove('c1=N+');
#is $tb->probeWdl($pos), 1;

done_testing;
