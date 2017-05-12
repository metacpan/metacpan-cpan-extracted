#!/usr/bin/perl
# 06_epdgetboard.t - test epdgetboard
#
use strict;
use warnings;
use diagnostics;
use Chess::PGN::EPD qw( epdgetboard );
use Test::More tests => 4;

ok(1);    # load failure check...

my @answers = (
    ',1,1,1,1',
    '1,1,1,1,1',
    ',1,1,1,1',
);
my @epd = (
	'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3',
	'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6',
	'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq -',
);

is(check_epdgetboard($epd[0]),$answers[0],'Check epdgetboard');
is(check_epdgetboard($epd[1]),$answers[1],'Check epdgetboard');
is(check_epdgetboard($epd[2]),$answers[2],'Check epdgetboard');

sub check_epdgetboard {
    my $epd = shift;
    my ($w,$Kc,$Qc,$kc,$qc,%board) = epdgetboard($epd);
    return "$w,$Kc,$Qc,$kc,$qc";
}
