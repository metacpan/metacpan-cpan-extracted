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

# Winning because of en passant.
$pos = Chess::Plisco->new('8/8/8/k2Pp3/8/8/8/4K3 w - e6 0 2');
is $tb->__probeWdlTable($pos), 0;

# Without en passant, it is a draw.
is $tb->probeWdl($pos), 2;

done_testing;
