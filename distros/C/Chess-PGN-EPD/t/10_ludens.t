#!/usr/bin/perl
# 10_ludens.t -- ludens reported bug(s)
use Test::More tests => 7;
use Chess::PGN::EPD qw( epdlist epdTaxonomy );

ok(1); # 1. If we made it this far, we're ok.

my @moves1 = qw(
d4 g6 Bf4 Bg7 Nf3 d6 Nc3 Nf6 e3 O-O Qd3 Nbd7 h4 c5 
dxc5 Nxc5 Qe2 b6 O-O-O Ba6 Qe1 Bxf1 Qxf1 Nce4 
Nxe4 Nxe4 g4 Rc8 Qd3 Nc5 Qe2 b5 h5 Qa5 a3 Qa4 
c3 Nb3+ Kb1 b4 cxb4 a5 bxa5 Nxa5 hxg6 fxg6 Bh6 Bxb2 
Bxf8 Qxa3 Qxb2 Qa4 Qa2+ Qc4 Qxc4+ Rxc4 Bxe7 Nc6 
Bxd6 Ra4 Rd2 Rxg4 Ne5 Ra4 Nxc6 Ra6 Rc2 Rb6+ Kc1 Kf7 
Rxh7+ Ke6 Bf4 Kd5 Ne7+ Ke4 Rg7 Kf3 Rxg6 Ra6 Rxa6 Kg2 
Kd1 Kf1 Rca2 Kg2 Bh6 Kf3 Re6 Kg4 Nc6 Kf5 Rd6 Kg4 
Rdd2 Kf3 Bf8 Kg2 Re2 Kf3 e4 Kf4 e5 Kf3 e6 Kg2 
Ba3 Kf1 e7 Kg2 Re1 Kf3 e8=R Kf4 Rf8+ Kg5 f3 Kg6 
f4 Kg7 f5 Kh7 Ra8 Kg7 Rf1 Kf6 Nd4 Kf7 f6 Kg6 
f7 Kg5 f8=R Kg4 Rf8f2 Kg3 Rae2 Kg4 Rae8 Kg3 R8e3+ Kg4 
Ree1 Kg5 Bb2 Kg4 Bc3 Kg5 Re1e2 Kg4 Be1 Kg5 Nc2 Kg4 
Kd2 Kg5 Kd3 Kg4 Kd4 Kg5 Kc4 Kg4 Kd5 Kg5 Bd2 Kg4 
Ne1 Kg5 Rd3+ Kg4 Bc1 Kh5 Rd1 Kg6 Bd2 Kg7 Re3 Kg6 
Rfe2 Kg7 Rff3 Kg6 Rff2 Kg7 Rf1 Kg6 Rff2 Kg7 Rf4 Kg6 
Rd4 Kg7 Rdd3 Kg6 Rc3 Kg7 Rc2 Kg6 Rcc1 Kg7 Rcc3 Kg6 
Rc2 Kg7 Rcc1 Kg6 Rc4 Kg7 Rb4 Kg6 Rbb3
);

my @moves2 = (
);

is(ECO1(\@moves1),'A40','ECO lookup #1'); # 2.
is(NIC1(\@moves1),'VO 23','NIC lookup #1'); # 3.
is(Opening1(\@moves1),'Modern defense','Opening lookup #1'); # 4.
is(ECO1(\@moves2),'Unknown','ECO lookup #2'); # 5.
is(NIC1(\@moves2),'Unknown','NIC lookup #2'); # 6.
is(Opening1(\@moves2),'Unknown','Opening lookup #2'); # 7.

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
