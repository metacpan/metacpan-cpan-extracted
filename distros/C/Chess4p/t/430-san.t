use v5.36;

use Test::More;

use utf8;

use Config;

plan skip_all => 'Only 64 bit systems are supported.'  unless $Config{ptrsize} && $Config{ptrsize} == 8;

plan tests => 1112;

require Chess4p;


my $board = Chess4p::Board->fromFen();

my @games;

push @games,
  [qw (d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Nf3 O-O Be2 e5 O-O Nc6 d5 Ne7 Ne1 Nd7 Nd3 f5
       exf5 Nxf5 f3 Nf6 Nf2 Nd4 Nfe4 Nh5 Bg5 Qd7 g3 h6 Be3 c5 Bxd4 exd4 Nb5 a6 Nbxd6 d3
       Qxd3 Bd4+ Kg2 Nxg3 Nxc8 Nxf1 Nb6 Qc7 Rxf1 Qxb6 b4 Qxb4 Rb1 Qa5 Nxc5 Qxc5 Qxg6+ Bg7 Rxb7 Qd4
       Bd3 Rf4 Qe6+ Kh8 Qg6)
  ],
  [qw (d4 Nf6 c4 g6 g3 c6 Bg2 d5 cxd5 cxd5 Nc3 Bg7 e3 O-O Nge2 Nc6 O-O b6 b3 Ba6
       Ba3 Re8 Qd2 e5 dxe5 Nxe5 Rfd1 Nd3 Qc2 Nxf2 Kxf2 Ng4+ Kg1 Nxe3 Qd2 Nxg2 Kxg2 d4 Nxd4 Bb7+
       Kf1 Qd7)
  ],
  [qw (e4 c5 Nf3 Nc6 d4 cxd4 Nxd4 Qc7 Nc3 e6 g3 a6 Bg2 Nf6 O-O Nxd4 Qxd4 Bc5 Bf4 d6
       Qd2 h6 Rad1 e5 Be3 Bg4 Bxc5 dxc5 f3 Be6 f4 Rd8 Nd5 Bxd5 exd5 e4 Rfe1 Rxd5 Rxe4+ Kd8
       Qe2 Rxd1+ Qxd1+ Qd7 Qxd7+ Kxd7 Re5 b6 Bf1 a5 Bc4 Rf8 Kg2 Kd6 Kf3 Nd7 Re3 Nb8 Rd3+ Kc7
       c3 Nc6 Re3 Kd6 a4 Ne7 h3 Nc6 h4 h5 Rd3+ Kc7 Rd5 f5 Rd2 Rf6 Re2 Kd7 Re3 g6
       Bb5 Rd6 Ke2 Kd8 Rd3 Kc7 Rxd6 Kxd6 Kd3 Ne7 Be8 Kd5 Bf7+ Kd6 Kc4 Kc6 Be8+ Kb7 Kb5 Nc8
       Bc6+ Kc7 Bd5 Ne7 Bf7 Kb7 Bb3 Ka7 Bd1 Kb7 Bf3+ Kc7 Ka6 Ng8 Bd5 Ne7 Bc4 Nc6 Bf7 Ne7
       Be8 Kd8 Bxg6 Nxg6 Kxb6 Kd7 Kxc5 Ne7 b4 axb4 cxb4 Nc8 a5 Nd6 b5 Ne4+ Kb6 Kc8 Kc6 Kb8
       b6)
  ],
  [qw (e4 c5 Nf3 e6 d4 cxd4 Nxd4 a6 Bd3 Nc6 Nxc6 bxc6 O-O d5 c4 Nf6 cxd5 cxd5 exd5 exd5
       Nc3 Be7 Qa4+ Qd7 Re1 Qxa4 Nxa4 Be6 Be3 O-O Bc5 Rfe8 Bxe7 Rxe7 b4 Kf8 Nc5 Bc8 f3 Rea7
       Re5 Bd7 Nxd7+ Rxd7 Rc1 Rd6 Rc7 Nd7 Re2 g6 Kf2 h5 f4 h4 Kf3 f5 Ke3 d4+ Kd2 Nb6
       Ree7 Nd5 Rf7+ Ke8 Rb7 Nxf4 Bc4)
  ],
  [qw ( e4 Nf6  e5 Nd5  d4 d6  Nf3 g6  Bc4 Nb6  Bb3 Bg7  Nbd2 O-O  h3 a5  a4 dxe5  dxe5 Na6
        O-O Nc5  Qe2 Qe8  Ne4 Nbxa4  Bxa4 Nxa4  Re1 Nb6  Bd2 a4  Bg5 h6  Bh4 Bf5  g4 Be6  Nd4 Bc4
        Qd2 Qd7  Rad1 Rfe8  f4 Bd5  Nc5 Qc8  Qc3 e6  Kh2 Nd7  Nd3 c5  Nb5 Qc6  Nd6 Qxd6  exd6 Bxc3
        bxc3 f6  g5 hxg5  fxg5 f5  Bg3 Kf7  Ne5+ Nxe5  Bxe5 b5  Rf1 Rh8  Bf6 a3  Rf4 a2  c4 Bxc4
        d7 Bd5  Kg3 Ra3+  c3 Rha8  Rh4 e5  Rh7+ Ke6  Re7+ Kd6  Rxe5 Rxc3+  Kf2 Rc2+  Ke1 Kxd7  Rexd5+ Kc6
        Rd6+ Kb7  Rd7+ Ka6  R7d2 Rxd2  Kxd2 b4  h4 Kb5  h5 c4  Ra1 gxh5  g6 h4  g7 h3  Be7 Rg8
        Bf8 h2  Kc2 Kc6  Rd1 b3+  Kc3 h1=Q  Rxh1 Kd5  Kb2 f4  Rd1+ Ke4  Rc1 Kd3  Rd1+ Ke2  Rc1 f3
        Bc5 Rxg7  Rxc4 Rd7  Re4+ Kf1  Bd4 f2)
  ],
  [qw (d4 d5 c4 e6 Nc3 Nf6
       cxd5 exd5 )
  ],
  [qw (e4 c6 Nc3 d5 Nf3 dxe4 Nxe4 Nf6 Qe2 Nxe4 Qxe4 Qd5 Qf4 Qf5
       Qc7 Qd7 Qf4 Qf5 Qd4 Qd5 Qh4 Qe6+ Be2 Qg4 Qg3 Qxg3 hxg3
       Bg4 d4 Nd7 Bf4 e6 O-O-O Be7 Bd3 Bxf3 gxf3 h6 c3 O-O-O
       Bc2 Bg5 Be3 Nb6 f4 Be7 f5 exf5 Bxf5+ Kb8 b3 Rhe8 c4
       Bg5 Bxg5 hxg5 Rh7 Re2 Rxg7 Rxf2 Rxg5 a5 Bc2 a4 Rf5 Rg2
       d5 cxd5 Rf6 Ka7 c5 Nd7 Rd6 Re8 Rxd7 Ree2 Bd3 Rxa2 c6
       a3 Rxb7+ Ka8 Re1 Rae2 Rxe2
     )
  ],
  ;

# Play through the games to test SAN i/o.

for my $game (@games) {
    for my $san (@$game) {
        my $move = $board->parse_san($san);
        is($board->san($move), $san, 'SAN output == SAN input');

        # UCI input should work the same
        my $move_2 = $board->parse_san($move->uci());
        is($move->uci(), $move_2->uci(), 'UCI is parsed too');
        
        $board->push_move($move);
    }
    while ($board->ply()) {
        $board->pop_move();
    }
}




done_testing;
