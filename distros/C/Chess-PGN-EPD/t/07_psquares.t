#!/usr/bin/perl
# 07_psquares.t - test psquares
#
use strict;
use warnings;
use diagnostics;
use Chess::PGN::EPD qw( epdgetboard psquares );
use Test::More tests => 7;

ok(1);    # load failure check...

my @answers = ( 
    'b1 g1', 
    'b1 g1', 
    'b1 f3', 
    'b8 g8',
    'b8 g8',
    'b8 g8',
);
my @epd = (
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3',
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6',
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq -',
);

is( check_psquares( $epd[0], 'N' ), $answers[0], 'Check psquares' );
is( check_psquares( $epd[1], 'N' ), $answers[1], 'Check psquares' );
is( check_psquares( $epd[2], 'N' ), $answers[2], 'Check psquares' );
is( check_psquares( $epd[0], 'n' ), $answers[3], 'Check psquares' );
is( check_psquares( $epd[1], 'n' ), $answers[4], 'Check psquares' );
is( check_psquares( $epd[2], 'n' ), $answers[5], 'Check psquares' );

sub check_psquares {
    my ( $epd, $piece ) = @_;
    my ( $w, $Kc, $Qc, $kc, $qc, %board ) = epdgetboard($epd);
    my @result = psquares( $piece, %board );
    return join( " ", @result );
}
