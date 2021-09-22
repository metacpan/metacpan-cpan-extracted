#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use Chess::Plisco;

my $pos = Chess::Plisco->new;

ok $pos, 'created';

my $got = $pos->toFEN;
my $initial = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
my $wanted = $initial;

is $got, $wanted, 'FEN initial position';
is "$pos", $wanted, 'FEN initial position stringified';

is_deeply(Chess::Plisco->newFromFEN($wanted), $pos, 'newFromFEN');

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w');
};
like $@, qr/incomplete/i;

is(Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq')
   ->toFEN, $initial, 'defaults');

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/8/PPPPPPPP/RNBQKBNR w KQkq');
};
like $@, qr/exactly eight ranks/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq');
};
like $@, qr/exactly eight ranks/i;

eval {
	Chess::Plisco->newFromFEN('rsbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq');
};
like $@, qr/illegal piece\/number 's'/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/9/8/PPPPPPPP/RNBQKBNR w KQkq');
};
like $@, qr/illegal piece\/number '9'/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppp0pppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq');
};
like $@, qr/illegal piece\/number '0'/i, "illegal number 0";

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/ppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq');
};
like $@, qr/incomplete or overpopulated rank/i;

done_testing;
