#!/usr/bin/perl
# 03_epdlist.t - test epdlist
#
use strict;
use warnings;
use diagnostics;
use Chess::PGN::EPD qw( epdlist );
use Test::More tests => 4;

ok(1); # load failure check...

my @game = qw ( e4 c5 Nf3 );
my @answers = (
	'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3',
	'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6',
	'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq -',
);

is(check_epd(0,@game),$answers[0],'Check epdlist function');
is(check_epd(1,@game),$answers[1],'Check epdlist function');
is(check_epd(2,@game),$answers[2],'Check epdlist function');

sub check_epd {
	my ($which,@moves) = @_;
	my @epdstrings = epdlist(@moves);
	return $epdstrings[$which];
}
