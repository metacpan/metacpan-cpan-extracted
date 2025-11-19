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
use Chess::Plisco;

my $pos = Chess::Plisco->new;

ok $pos, 'created';

my $got = $pos->toFEN;
my $initial = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
my $wanted = $initial;

is $got, $wanted, 'FEN initial position';
is "$pos", $wanted, 'FEN initial position stringified';

is_deeply(Chess::Plisco->newFromFEN($wanted), $pos, 'newFromFEN');

$pos = eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w');
};
ok $pos;
ok !$pos->enPassantShift;
ok !$pos->castlingRights;

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

eval {
	Chess::Plisco->newFromFEN('8/8/8/pPk5/8/8/8/7K w a6 - 0 1');
};
like $@, qr/Illegal castling rights 'a6'/i;

ok(Chess::Plisco->newFromFEN('4k3/8/8/8/8/8/8/4K2R w K - 0 1'));

eval {
	Chess::Plisco->newFromFEN('r3k2r/8/8/8/8/8/8/R4K1R w KQkq - 0 1');
};
like $@, qr/Illegal castling rights: king not on initial square!/i;

eval {
	Chess::Plisco->newFromFEN('r3k2r/8/8/8/8/8/8/R3K1R1 w KQkq - 0 1');
};
like $@, qr/Illegal castling rights: rook not on initial square!/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/4P3/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
};
like $@, qr/White has too many pawns/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/4p3/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
};
like $@, qr/Black has too many pawns/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/4R3/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
};
like $@, qr/White has too many rooks/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/4r3/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
};
like $@, qr/Black has too many rooks/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/4B3/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
};
like $@, qr/White has too many bishops/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/4b3/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
};
like $@, qr/Black has too many bishops/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/4N3/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
};
like $@, qr/White has too many knights/i;

eval {
	Chess::Plisco->newFromFEN('rnbqkbnr/pppppppp/8/8/4n3/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
};
like $@, qr/Black has too many knights/i;

eval {
	Chess::Plisco->newFromFEN('7k/8/8/8/8/8/8/Q6K w - - 0 1');
};
like $@, qr/side not to move is in check/i;

eval {
	Chess::Plisco->newFromFEN('7K/8/8/8/8/8/8/q6k b - - 0 1');
};
like $@, qr/side not to move is in check/i;

done_testing;
