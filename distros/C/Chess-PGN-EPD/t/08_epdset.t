#!/usr/bin/perl
# 08_epdset.t - test epdset
#
use strict;
use warnings;
use diagnostics;
use Chess::PGN::EPD qw( epdset epdgetboard psquares );
use Test::More tests => 4;

ok(1);    # load failure check...

my @answers = ( 
    'b1 g1', 
    'b1 g1', 
    'b1 f3', 
);
my @epd = (
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3',
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6',
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq -',
);

is( check_epdset( $epd[0]), $answers[0], 'Check epdset' );
is( check_epdset( $epd[1]), $answers[1], 'Check epdset' );
is( check_epdset( $epd[2]), $answers[2], 'Check epdset' );

sub check_epdset {
    epdset(shift);
    my ( $w, $Kc, $Qc, $kc, $qc, %board ) = epdgetboard();
    my @result = psquares( 'N', %board );
    return join( " ", @result );
}
