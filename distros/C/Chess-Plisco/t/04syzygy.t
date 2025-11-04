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

use Chess::Plisco::Tablebase::Syzygy;

is(Chess::Plisco::Tablebase::Syzygy->normalizeTablename('PRPBKQvRKQB'),
   'KQRBPPvKQRB', ('normalize: order pieces'));
is(Chess::Plisco::Tablebase::Syzygy->normalizeTablename('KQvK'), 'KQvK',
	('normalize: KvQK -> KQvK'));

ok(!Chess::Plisco::Tablebase::Syzygy->__isTablename('KvK'),
	'__isTablename(KvK)');
ok(Chess::Plisco::Tablebase::Syzygy->__isTablename('KQvK'),
	'__isTablename(KQvK)');
ok(!Chess::Plisco::Tablebase::Syzygy->__isTablename('QKvK'),
	'__isTablename(QKVK)');
ok(!Chess::Plisco::Tablebase::Syzygy->__isTablename('QKvK', normalized => 0),
	'__isTablename(QKVK, normalized => 0)');

my $tb;

$tb = Chess::Plisco::Tablebase::Syzygy->new('foo/bar');
is $tb->largestWdl, 0, 'non-existent path WDL';
is $tb->largestDtz, 0, 'non-existent path DTZ';

$tb = Chess::Plisco::Tablebase::Syzygy->new('t/syzygy');
is $tb->largestWdl, 3, 'loaded WDL';
is $tb->largestDtz, 3, 'loaded DTZ';

done_testing;
