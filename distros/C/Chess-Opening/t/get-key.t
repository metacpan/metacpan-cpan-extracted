#! /usr/bin/env perl

# Copyright (C) 2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use common::sense;

use Test::More;
use Chess::Opening::Book::Polyglot;

# Tests from http://hardy.uhasselt.be/Toga/book_format.html

sub stringify_key($);

my ($key);

$key = Chess::Opening::Book::Polyglot->_getKey(
	'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
);
is stringify_key $key, "0x463b96181691fc9c";

$key = Chess::Opening::Book::Polyglot->_getKey(
	'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
);
is stringify_key $key, "0x823c9b50fd114196";

$key = Chess::Opening::Book::Polyglot->_getKey(
	'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2',
);
is stringify_key $key, "0x0756b94461c50fb0";

$key = Chess::Opening::Book::Polyglot->_getKey(
	'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 2',
);
is stringify_key $key, "0x662fafb965db29d4";

$key = Chess::Opening::Book::Polyglot->_getKey(
	'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3',
);
is stringify_key $key, "0x22a48b5a8e47ff78";

$key = Chess::Opening::Book::Polyglot->_getKey(
	'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPPKPPP/RNBQ1BNR b kq - 0 3',
);
is stringify_key $key, "0x652a607ca3f242c1";

$key = Chess::Opening::Book::Polyglot->_getKey(
	'rnbq1bnr/ppp1pkpp/8/3pPp2/8/8/PPPPKPPP/RNBQ1BNR w - - 0 4',
);
is stringify_key $key, "0x00fdd303c946bdd9";

$key = Chess::Opening::Book::Polyglot->_getKey(
	'rnbqkbnr/p1pppppp/8/8/PpP4P/8/1P1PPPP1/RNBQKBNR b KQkq c3 0 3',
);
is stringify_key $key, "0x3c8123ea7b067637";

$key = Chess::Opening::Book::Polyglot->_getKey(
	'rnbqkbnr/p1pppppp/8/8/P6P/R1p5/1P1PPPP1/1NBQKBNR b Kkq - 0 4',
);
is stringify_key $key, "0x5c3f9b829b279560";

done_testing;

sub stringify_key($) {
	my @bytes = unpack 'C*', shift;

	my $retval = '0x';
	foreach my $byte (@bytes) {
		$retval .= sprintf '%02x', $byte;
	}

	return $retval;
}
