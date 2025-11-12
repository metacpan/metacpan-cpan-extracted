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

use Chess::Plisco::EPD;
use Chess::Plisco::Tablebase::Syzygy;

my $epd = Chess::Plisco::EPD->new('./t/epd/endgame.epd');
if ($ENV{AUTHOR_TESTING}) {
	my $epd_large = Chess::Plisco::EPD->new('./t/epd/endgame-large.epd');
	push @$epd, @$epd_large;
}

my $tb = Chess::Plisco::Tablebase::Syzygy->new('./t/syzygy');

foreach my $record (@$epd) {
	my $pos = $record->position;
	my $wanted_wdl_table = $record->operation('wdl_table');
	my $wanted_wdl = $record->operation('wdl');
	my $wanted_dtz = $record->operation('dtz');

	is $tb->__probeWdlTable($pos), $wanted_wdl_table, "probeWdlTable: $pos";
	is $tb->probeWdl($pos), $wanted_wdl, "probeWdl: $pos";
	is $tb->probeDtz($pos), $wanted_dtz, "probeDtz: $pos";
}

done_testing;
