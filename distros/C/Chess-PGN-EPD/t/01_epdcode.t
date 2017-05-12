#!/usr/bin/perl
# 01_epdcode.t -- test epdcode.
use Test::More tests => 7;
use Chess::PGN::EPD qw( epdlist epdcode );

ok(1); # 1. If we made it this far, we're ok.

my @epd1;
my @epd2;
my @moves1 = qw(
e4 e6 f4 d5 e5 c5 Nf3 Nc6 d3 Be7 Be2 Nh6 c3 O-O O-O f6
exf6 Bxf6 d4 cxd4 cxd4 Qb6 Nc3 Bxd4+ Kh1 Bxc3 bxc3 Ng4
Nd4 Nxd4 cxd4 Nf6 Ba3 Rf7 Rb1 Qd8 Bd3 Bd7 Qf3 Bc6
f5 Ne4 Bxe4 dxe4 Qd1 exf5 Rb2 Qd5 Rbf2 e3 Re2 Bb5
);
my @moves2 = qw(
d4 Nf6 c4 e6 Nc3 Bb4 e3 b6 Ne2 Bb7 a3 Be7 f3 d5 cxd5 exd5 Ng3 O-O Bd3 c5
O-O Re8 Nf5 Bf8 g4 g6 Ng3 Nc6 g5 cxd4 exd4 Nd7 Nge2 Bg7 Nb5 Nf8 f4 a6 f5
axb5 f6 Bh8 Bxb5 Ba6 Bxa6 Rxa6 Bf4 Qd7 Rc1 Raa8 Rc3 Re4 Ng3 Rxd4 Qc2 Na5
Be3 Rg4 Qd1 Nc4 Bc1 b5 Rd3 d4 Re1 h5 b3 Nb6 Re7 Qd6 Re4 Rxe4 Nxe4 Qc6 Nd2
Ne6 Nf3 Rd8 Be3 Qe4
);

@epd1 = reverse epdlist( @moves1 );
@epd2 = reverse epdlist( @moves2 );

is(ECO(\@epd1),'C00','ECO lookup #1'); # 2.
is(NIC(\@epd1),'FR 1','NIC lookup #1'); # 3.
is(Opening(\@epd1),'French: Labourdonnais variation','Opening lookup #1'); # 4.
is(ECO(\@epd2),'E44','ECO lookup #2'); # 5.
is(NIC(\@epd2),'NI 13','NIC lookup #2'); # 6.
is(Opening(\@epd2),'Nimzo-Indian: Fischer variation, 5.Ne2'); # 7.

sub ECO {
    my $movesref = shift;

    return epdcode('ECO',$movesref);
}

sub NIC {
    my $movesref = shift;

    return epdcode('NIC',$movesref);
}

sub Opening {
    my $movesref = shift;

    return epdcode('Opening',$movesref);
}
