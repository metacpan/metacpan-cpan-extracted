#!/usr/bin/perl
# 11_ludens-2.t -- ludens reported bug
use Test::More tests => 2;
use Chess::PGN::EPD qw( epdlist );

ok(1); # 1. If we made it this far, we're ok.

my $answer = 'r1b1kbnr/pp1ppppp/2N5/8/4P3/4B3/P1P2PPP/qN1QKB1R w Kkq -';
my @moves = qw(
e4 c5 Nf3 Nc6 d4 cxd4 Nxd4 Qb6 Be3 Qxb2 Nxc6 Qxa1
);

is(EPD(@moves),$answer,'EPD result'); # 2.

sub EPD {
    my @EPD = epdlist(@_);
    return $EPD[-1];
}
