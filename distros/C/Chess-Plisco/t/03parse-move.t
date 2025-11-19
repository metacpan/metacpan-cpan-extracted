#! /usr/bin/env perl

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!

my $fen;

my ($pos, $move);

$pos = Chess::Plisco->new;
$move = $pos->parseMove('e2e4');
ok $move, 'e2e4 from start position';

$pos = Chess::Plisco->new;
$move = eval { $pos->parseMove('i0j9') };
ok $@, 'i0j9 from start position';

$pos = Chess::Plisco->new;
$move = eval { $pos->parseMove('e3e4') };
ok $@, 'e3e4 from start position';
like $@, qr/Illegal move: start square is empty/, 'e3e4 from start position error match';

$pos = Chess::Plisco->new;
$move = eval { $pos->parseMove('e1g1') };
ok $@, '0-0 from start position';
is $@, "Illegal move!\n", '0-0 from start position error match';

done_testing;
