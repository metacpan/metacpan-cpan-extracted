use v5.36;

use Test::More;

use utf8;

use Config;

plan skip_all => 'Only 64 bit systems are supported.'  unless $Config{ptrsize} && $Config{ptrsize} == 8;

plan tests => 33;

require Chess4p;
require Chess4p::Perft;

my $rel = $ENV{RELEASE_TESTING};

my @tests;

push @tests,
  { board => Chess4p::Board->fromFen(),
    depth => $rel ? 4 : 3, result => $rel ? 197281 : 8902, label => 'pos-1',
    fen_mirror => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1',
  },
  { board => Chess4p::Board->fromFen('r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -'),
    depth => $rel ? 4 : 3, result => $rel ? 4085603 : 97862, label => 'pos-2',
    fen_mirror => 'r3k2r/pppbbppp/2n2q1P/1P2p3/3pn3/BN2PNP1/P1PPQPB1/R3K2R b KQkq - 0 1',
  },
  { board => Chess4p::Board->fromFen('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -'),
    depth => $rel ? 5 : 3, result => $rel ? 674624 : 2812, label => 'pos-3',
    fen_mirror => '8/4p1p1/8/1r3P1K/kp5R/3P4/2P5/8 b - - 0 1',
  },
  { board => Chess4p::Board->fromFen('r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ -'),
    depth => $rel ? 4 : 3, result => $rel ? 422333 : 9467, label => 'pos-4 (mirrored)',
    fen_mirror => 'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
  },
  { board => Chess4p::Board->fromFen('rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ -'),
    depth => $rel ? 4 : 3, result => $rel ? 2103487 : 62379, label => 'pos-5',
    fen_mirror => 'rnbqk2r/ppp1nNpp/8/2b5/8/2P5/PP1pBPPP/RNBQ1K1R b kq - 0 1',
  },
  { board => Chess4p::Board->fromFen('r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - -'),
    depth => $rel ? 4 : 3, result => $rel ? 3894594 : 89890, label => 'pos-6',
    fen_mirror => 'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 b - - 0 1',
  },
  { board => Chess4p::Board->fromFen('rnbqkbnr/ppp3pp/4p3/3pPp2/3P4/8/PPP2PPP/RNBQKBNR w KQkq f6'),
    depth => $rel ? 4 : 3, result => $rel ? 1201468 : 39384, label => 'e.p. special',
    fen_mirror => 'rnbqkbnr/ppp2ppp/8/3p4/3PpP2/4P3/PPP3PP/RNBQKBNR b KQkq f3 0 1',
  },
  { board => Chess4p::Board->fromFen('r3k2r/pp1bppbp/2np1np1/q7/3NP3/2N1BP2/PPPQB1PP/R3K2R w KQkq -'),
    depth => $rel ? 4 : 3, result => $rel ? 4526742 : 96138, label => 'dragon special',
    fen_mirror => 'r3k2r/pppqb1pp/2n1bp2/3np3/Q7/2NP1NP1/PP1BPPBP/R3K2R b KQkq - 0 1',
  },
  { board => Chess4p::Board->fromFen('rnbqkbnr/pp4pp/4p3/3pPp2/2pP4/2P5/PP3PPP/RNBQKBNR w KQkq f6'),
    depth => $rel ? 4 : 3, result => $rel ? 1147447 : 36366, label => 'e.p. special 2',
    fen_mirror => 'rnbqkbnr/pp3ppp/2p5/2Pp4/3PpP2/4P3/PP4PP/RNBQKBNR b KQkq f3 0 1',
  },
  { board => Chess4p::Board->fromFen('8/8/4k3/4Pp2/4K3/8/8/8 w - f6'),
    depth => 4, result => 1440, label => 'check evasion by e.p. capture',
    fen_mirror => '8/8/8/4k3/4pP2/4K3/8/8 b - f3 0 1',
  },
  { board => Chess4p::Board->fromFen('rnb2k1r/pp1Pbppp/1qp5/8/2B5/8/PPP1NKPP/RNBQ3R w - -'),
    depth => $rel ? 4 : 3, result => $rel ? 333553 : 10748, label => 'wiki-pos-5-Qb6+',
    fen_mirror => 'rnbq3r/ppp1nkpp/8/2b5/8/1QP5/PP1pBPPP/RNB2K1R b - - 0 1',
  },
  ;


for my $test (@tests) {
    is(Chess4p::Perft::perft($test->{depth}, $test->{board}), $test->{result}, $test->{label});
    if ($test->{fen_mirror}) {
        # mirrored position should give same result:
        my $board = $test->{board};
        $board->apply_mirror();
        is($board->fen(), $test->{fen_mirror}, 'mirror fen');
        is(Chess4p::Perft::perft($test->{depth}, $board), $test->{result}, $test->{label}.' mirrored');    
    }
}
 


done_testing;
