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

my $pos = Chess::Plisco->new('kqrb4/8/8/8/8/8/8/4BRQK w - - 0 1');

ok !defined $tb->safeProbeWdl($pos), 'safe WDL probe';
ok !defined $tb->safeProbeDtz($pos), 'safe DTZ probe';
is $tb->safeProbeWdl($pos, 42), 42, 'safe WDL probe default value';
is $tb->safeProbeDtz($pos, 2304), 2304, 'safe DTZ probe default value';

done_testing;
