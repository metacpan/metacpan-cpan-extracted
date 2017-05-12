#!/usr/bin/perl
# 09_epdTaxonomy.t -- test epdTaxonomy.
use Test::More tests => 13;
use Chess::PGN::EPD qw( epdlist epdTaxonomy );

ok(1); # 1. If we made it this far, we're ok.

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

is(ECO1(\@moves1),'C00','ECO lookup #1'); # 2.
is(NIC1(\@moves1),'FR 1','NIC lookup #1'); # 3.
is(Opening1(\@moves1),'French: Labourdonnais variation','Opening lookup #1'); # 4.
is(ECO1(\@moves2),'E44','ECO lookup #2'); # 5.
is(NIC1(\@moves2),'NI 13','NIC lookup #2'); # 6.
is(Opening1(\@moves2),'Nimzo-Indian: Fischer variation, 5.Ne2','Opening lookup #2'); # 7.

is(ECO2(\@moves1),'[ECO "C00"]','ECO lookup #3'); # 8.
is(NIC2(\@moves1),'[NIC "FR 1"]','NIC lookup #3'); # 9.
is(Opening2(\@moves1),'[Opening "French: Labourdonnais variation"]','Opening lookup #3'); # 10.
is(ECO2(\@moves2),'[ECO "E44"]','ECO lookup #4'); # 11.
is(NIC2(\@moves2),'[NIC "NI 13"]','NIC lookup #4'); # 12.
is(Opening2(\@moves2),'[Opening "Nimzo-Indian: Fischer variation, 5.Ne2"]','Opening lookup #4'); # 13.

sub ECO1 {
    my $movesref = shift;
    my @taxonomy = epdTaxonomy(moves => $movesref,all => 1,astags => 0);
    return $taxonomy[0];
}

sub NIC1 {
    my $movesref = shift;
    my @taxonomy = epdTaxonomy(moves => $movesref,all => 1,astags => 0);
    return $taxonomy[1];
}

sub Opening1 {
    my $movesref = shift;
    my @taxonomy = epdTaxonomy(moves => $movesref,all => 1,astags => 0);
    return $taxonomy[2];
}

sub ECO2 {
    my $movesref = shift;
    my @taxonomy = epdTaxonomy(moves => $movesref,all => 1,astags => 1);
    return $taxonomy[0];
}

sub NIC2 {
    my $movesref = shift;
    my @taxonomy = epdTaxonomy(moves => $movesref,all => 1,astags => 1);
    return $taxonomy[1];
}

sub Opening2 {
    my $movesref = shift;
    my @taxonomy = epdTaxonomy(moves => $movesref,all => 1,astags => 1);
    return $taxonomy[2];
}
