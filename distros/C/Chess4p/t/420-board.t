use v5.36;

use Test::More;

use utf8;

use Config;

plan skip_all => 'Only 64 bit systems are supported.'  unless $Config{ptrsize} && $Config{ptrsize} == 8;

plan tests => 1176;


use Chess4p::Common qw(:all);

require Chess4p;


sub _legal_moves {
    my $board = shift;
    my @result;
    my $moves_iter = $board->legal_moves_iter();
    while (defined(my $s = $moves_iter->())) {
        push (@result, $s->uci());
    }
    \@result;
}

sub _pseudo_legal_moves {
    my $board = shift;
    my $bb_from = shift;
    my $bb_to = shift;
    my @result;
    my $moves_iter = $board->_pseudo_legal_moves_iter($bb_from, $bb_to);
    while (defined(my $s = $moves_iter->())) {
        push (@result, $s->uci());
    }
    \@result;
}



# Invalid positions

push my @invalid,
  {
    board   =>   Chess4p::Board->empty(),
    ascii   =>   ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .",
    err     =>   'WK missing',
    to_move =>   'w', castling => [0, 0, 0, 0],
    fen_out =>   '8/8/8/8/8/8/8/8 w - - 0 1',
  },
  {
    fen     =>   'rnbqkbnr/pppppppp/8/8/8/8/ w KQkq - 0 1',
    ascii   =>   "r n b q k b n r\n".
                 "p p p p p p p p\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .",
    err     =>   'WK missing',
    fen_out =>   'rnbqkbnr/pppppppp/8/8/8/8/8/8 w KQkq - 0 1',
  },
  {
    fen     =>   'kk6/8/8/8/8/8/8/KK6 w - - 0 1',
    ascii   =>   "k k . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 "K K . . . . . .",
    err     =>   'Too many WKs',
    fen_out =>   'kk6/8/8/8/8/8/8/KK6 w - - 0 1',
    to_move =>   'w', castling => [0, 0, 0, 0],
    pieces  =>   { A1() => 'K', B1() => 'K', C1() => '.' }
   },
  {
    fen     =>   'k7/pppppppp/p7/8/8/P7/PPPPPPPP/K7 w - - 0 1',
    ascii   =>   "k . . . . . . .\n".
                 "p p p p p p p p\n".
                 "p . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 "P . . . . . . .\n".
                 "P P P P P P P P\n".
                 "K . . . . . . .",
    err     =>   'Too many WPs',
    fen_out =>   'k7/pppppppp/p7/8/8/P7/PPPPPPPP/K7 w - - 0 1',
    to_move =>   'w',
  },
  {
    fen     =>   'kp6/8/8/8/8/8/8/KP6 w - - 0 1',
    ascii   =>   "k p . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 "K P . . . . . .",
    err     =>   'Pawns on back rank',
    fen_out =>   'kp6/8/8/8/8/8/8/KP6 w - - 0 1',
    to_move =>   'w',
  },
  {
    fen     =>   'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq f6 0 1',
    err     =>   'Invalid e.p. square: 45, but calculation disagreed.',
    # TODO maybe the ep square should be removed:
    fen_out =>   'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq f6 0 1',
    to_move =>   'w',
  },
  {
    fen     =>   'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq f3 0 1',
    err     =>   'Invalid e.p. square: 21, but calculation disagreed.',
    # TODO maybe the ep square should be removed:
    fen_out =>   'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq f3 0 1',
    to_move =>   'b',
  },
  {
    # Ke1 : Ke8
    fen     =>   '4k3/8/8/8/8/8/8/4K3 w KQkq - 0 1',
    err     =>   'Invalid castling rights',
    fen_out =>   '4k3/8/8/8/8/8/8/4K3 w KQkq - 0 1',
    to_move =>   'w',
  },
  {
    fen     =>   '4k3/8/5N2/8/8/8/8/4K3 w - - 0 4',
    err     =>   'Self in check',
    fen_out =>   '4k3/8/5N2/8/8/8/8/4K3 w - - 0 4',
    to_move =>   'w',
  },
  {
    fen     =>   '4k3/8/8/8/8/3n4/8/4K3 b - - 0 4',
    err     =>   'Self in check',
    fen_out =>   '4k3/8/8/8/8/3n4/8/4K3 b - - 0 4',
    to_move =>   'b',
  },
  {
    fen     =>   '4k3/4r3/8/4Pp2/4K3/8/8/7R w KQq f6 0 1',
    ascii   =>   ". . . . k . . .\n".
                 ". . . . r . . .\n".
                 ". . . . . . . .\n".
                 ". . . . P p . .\n".
                 ". . . . K . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . .\n".
                 ". . . . . . . R",
    err     =>   'Invalid castling rights',
    # TODO maybe the castling rights should be corrected
    fen_out =>   '4k3/4r3/8/4Pp2/4K3/8/8/7R w KQq f6 0 1',
    to_move =>   'w', castling => [1, 1, 0, 1],
  },
  {
    fen     =>   'k7/pppppppp/8/8/8/N7/PPPPPPPP/RNBQKBNR w - - 0 1',
    err     =>   'Too many White stones',
    fen_out =>   'k7/pppppppp/8/8/8/N7/PPPPPPPP/RNBQKBNR w - - 0 1',
    to_move =>   'w',
  },
  ;


my %test_fens; # used to check there are no duplicate test pos

for my $test (@invalid) {
    die 'duplicate test position...that is wasteful.' if $test->{fen} && $test_fens{$test->{fen}};
    $test_fens{$test->{fen}} = 1 if $test->{fen};
    my $out = "$test->{err} " . ( $test->{fen} // 'fen is undef, see board' ) . " -- ";
    my $board;
    if ($test->{board}) {
        $board = $test->{board};
    }
    else {
        $board = Chess4p::Board->fromFen($test->{fen});
    }
    is($board->errors(), $test->{err}, $out.'errors as expected');
    is($board->fen(), $test->{fen_out}, $out.'fen output') if $test->{fen_out};
    is($board->ascii(), $test->{ascii}, $out.'ascii') if $test->{ascii};
    is($board->to_move(), $test->{to_move}, $out.'to move') if $test->{to_move};
    if ($test->{castling}) {
        is($board->kingside_castling_right('w'),  $test->{castling}[0], $out.'c1');
        is($board->kingside_castling_right('b'),  $test->{castling}[2], $out.'c3');        
        is($board->queenside_castling_right('w'), $test->{castling}[1], $out.'c2');
        is($board->queenside_castling_right('b'), $test->{castling}[3], $out.'c4');        
    };
    if ($test->{pieces}) {
        for my $key (keys %{$test->{pieces}}) {
            is($board->piece_at($key), $test->{pieces}{$key}, $out.'pieces');
        }
    }
}


# Legal moves and more

my @tests;
push @tests,
  {
    text    => 'Conventional start position',
    fen     => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    ascii   => "r n b q k b n r\n".
               "p p p p p p p p\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               "P P P P P P P P\n".
               "R N B Q K B N R",
    string  => 1,
    to_move => 'w', castling => [1, 1, 1, 1], ep => undef, hmvc => 0, fmvn => 1,
    moves   => [ qw (a2a3 b2b3 c2c3 d2d3 e2e3 f2f3 g2g3 h2h3 a2a4 b2b4 c2c4 d2d4 e2e4 f2f4 g2g4 h2h4 b1a3 b1c3 g1f3 g1h3) ],
    p_moves => undef,
    pieces  => { A1() => 'R', B1() => 'N', C1() => 'B', E4() => '.', D8() => 'q' },
    attackers => [['w', E2, Chess4p::Board::_make_bb(D1, E1, F1, G1)], # w attackers of e2 ...
                  ['w', F3, Chess4p::Board::_make_bb(G1, E2, G2)],
                  ['w', E4, 0], # no attackers  
                  ['b', C6, Chess4p::Board::_make_bb(B8, D7, B7)],
                  ['b', E5, 0],
                 ],
    k_attack => [[Chess4p::Board::_make_bb(E4), 0], # e4 ok for WK
                 [Chess4p::Board::_make_bb(C3), 0], # and c3
                 [Chess4p::Board::_make_bb(C6), 1], # not c6
                ],
    sans    => [ {san_in => 'e4',  uci_out => 'e2e4',  san_out => 'e4'},
                 {san_in => 'g1f3', uci_out => 'g1f3', san_out => 'Nf3'},
               ],
    find_mv => [
                [[E2, E4], 'e2e4'],
                [[G1, F3], 'g1f3'],                
               ],
    do_pop => 1,
  },
  {
    text    => 'Default fen',
    fen     => undef,
    ascii   => "r n b q k b n r\n".
               "p p p p p p p p\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               "P P P P P P P P\n".
               "R N B Q K B N R",
    to_move => 'w', castling => [1, 1, 1, 1], ep => undef, ply => 0,
    moves   => [ qw (a2a3 b2b3 c2c3 d2d3 e2e3 f2f3 g2g3 h2h3 a2a4 b2b4 c2c4 d2d4 e2e4 f2f4 g2g4 h2h4 b1a3 b1c3 g1f3 g1h3) ],
    p_moves => undef,
    attackers => [['w', F2, Chess4p::Board::_make_bb(E1)],
                  ['w', F3, Chess4p::Board::_make_bb(G1, E2, G2)],
                 ],
  },
  {
    text    => 'missing FEN parts after pieces, works anyway',
    fen     => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
    fen_out => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - - 0 1',
    ascii   => "r n b q k b n r\n".
               "p p p p p p p p\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               "P P P P P P P P\n".
               "R N B Q K B N R",
    to_move => 'w', castling => [0, 0, 0, 0], ply => 0,
    ep => undef,
    moves   => [ qw (a2a3 b2b3 c2c3 d2d3 e2e3 f2f3 g2g3 h2h3 a2a4 b2b4 c2c4 d2d4 e2e4 f2f4 g2g4 h2h4 b1a3 b1c3 g1f3 g1h3) ],
    p_moves => undef,
  },
  {
    text    => 'With En Passant square (1)',
    fen     => 'rnbqkbnr/ppp3pp/4p3/3pPp2/3P4/8/PPP2PPP/RNBQKBNR w KQkq f6 0 4',
    ascii   => "r n b q k b n r\n".
               "p p p . . . p p\n".
               ". . . . p . . .\n".
               ". . . p P p . .\n".
               ". . . P . . . .\n".
               ". . . . . . . .\n".
               "P P P . . P P P\n".
               "R N B Q K B N R",
    to_move => 'w', castling => [1, 1, 1, 1], ep => F6, fmvn => 4, hmvc => 0,
    moves   => [ qw (e5f6 a2a3 b2b3 c2c3 f2f3 g2g3 h2h3 a2a4 b2b4 c2c4 f2f4 g2g4 h2h4 b1d2 b1a3 b1c3 c1d2 c1e3 c1f4 c1g5
                     c1h6 d1d2 d1e2 d1d3 d1f3 d1g4 d1h5 e1d2 e1e2 f1e2 f1d3 f1c4 f1b5 f1a6 g1e2 g1f3 g1h3) ],
    p_moves => undef,
    attackers => [['w', E2, Chess4p::Board::_make_bb(D1, E1, F1, G1)],
                  ['b', D7, Chess4p::Board::_make_bb(D8, E8, C8, B8)],
                 ],
  },
  {
    text    => 'Interesting test position',
    fen     => '6k1/4q3/5n2/8/4N3/5Q2/8/4K3 w - - 0 1',
    ascii   => ". . . . . . k .\n".
               ". . . . q . . .\n".
               ". . . . . n . .\n".
               ". . . . . . . .\n".
               ". . . . N . . .\n".
               ". . . . . Q . .\n".
               ". . . . . . . .\n".
               ". . . . K . . .",
    to_move => 'w', castling => [0, 0, 0, 0], ep => undef,
    moves   => [ qw (e1d1 e1f1 e1d2 e1e2 e1f2 f3d1 f3f1 f3h1 f3e2 f3f2 f3g2 f3a3 f3b3 f3c3 f3d3 f3e3 f3g3 f3h3 f3f4 f3g4 f3f5 f3h5 f3f6) ],
    p_moves => [ qw (e1d1 e1f1 e1d2 e1e2 e1f2 f3d1 f3f1 f3h1 f3e2 f3f2 f3g2 f3a3 f3b3 f3c3 f3d3 f3e3 f3g3 f3h3 f3f4 f3g4 f3f5 f3h5 f3f6
                     e4d2 e4f2 e4c3 e4g3 e4c5 e4g5 e4d6 e4f6) ],
    attackers => [['w', F2, Chess4p::Board::_make_bb(E1, F3, E4)], # w attackers of f2
                  ['b', H7, Chess4p::Board::_make_bb(G8, F6, E7)], # b attackers of h7
                 ],
  },
  {
    text    => 'With En Passant square (2)',
    fen     => 'rnbqkbnr/pppp1ppp/8/8/3PpP2/4P3/PPP3PP/RNBQKBNR b KQkq f3 0 3',
    ascii   => "r n b q k b n r\n".
               "p p p p . p p p\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . P p P . .\n".
               ". . . . P . . .\n".
               "P P P . . . P P\n".
               "R N B Q K B N R",
    to_move => 'b', castling => [1, 1, 1, 1], ep => F3, hmvc => 0, fmvn => 3,
    moves   => [ qw (e4f3 a7a6 b7b6 c7c6 d7d6 f7f6 g7g6 h7h6 a7a5 b7b5 c7c5 d7d5 f7f5 g7g5 h7h5 b8a6 b8c6 d8h4 d8g5 d8f6
                     d8e7 e8e7 f8a3 f8b4 f8c5 f8d6 f8e7 g8f6 g8h6 g8e7) ],
    p_moves => undef,
    k_attack => [[Chess4p::Board::_make_bb(E4), 0], # BK safe on e4
                 [Chess4p::Board::_make_bb(H6), 0], # and h6
                 [Chess4p::Board::_make_bb(D3), 1], # not on d3
                ],
  },
  {
    text    => 'Black to move - with a pin',
    fen     => 'rnbqk2r/pppp1ppp/4pn2/8/1bPP4/2N1P3/PP3PPP/R1BQKBNR b KQkq - 0 4',
    ascii   => "r n b q k . . r\n".
               "p p p p . p p p\n".
               ". . . . p n . .\n".
               ". . . . . . . .\n".
               ". b P P . . . .\n".
               ". . N . P . . .\n".
               "P P . . . P P P\n".
               "R . B Q K B N R",
    to_move => 'b', castling => [1, 1, 1, 1], ep => undef,
    moves   => [ qw (e6e5 a7a6 b7b6 c7c6 d7d6 g7g6 h7h6 a7a5 b7b5 c7c5 d7d5 g7g5 h7h5 h8f8 h8g8 b4a3 b4c3 b4a5 b4c5 b4d6
                     b4e7 b4f8 f6e4 f6g4 f6d5 f6h5 f6g8 b8a6 b8c6 d8e7 e8e7 e8f8 e8g8) ],
    p_moves => undef,
    sans    => [ {san_in => 'O-O',   uci_out => 'e8g8',  san_out => 'O-O'},
                 {san_in => 'Ke7',   uci_out => 'e8e7',  san_out => 'Ke7'},
                 {san_in => 'Bxc3+', uci_out => 'b4c3',  san_out => 'Bxc3+'},
               ],
  },
  ########### BEGIN: From https://www.chessprogramming.org/Perft_Results #############
  {
    text    => 'Position 2',
    fen     => 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -  ',
    fen_out => 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
    to_move => 'w', castling => [1, 1, 1, 1], ep => undef,
    moves   => [ qw (g2h3 d5e6 a2a3 b2b3 g2g3 d5d6 a2a4 g2g4 a1b1 a1c1 a1d1 e1d1 e1f1 h1f1 h1g1 d2c1 d2e3 d2f4 d2g5 d2h6
                     e2d1 e2f1 e2d3 e2c4 e2b5 e2a6 c3b1 c3d1 c3a4 c3b5 f3d3 f3e3 f3g3 f3h3 f3f4 f3g4 f3f5 f3h5 f3f6 e5d3
                     e5c4 e5g4 e5c6 e5g6 e5d7 e5f7 e1g1 e1c1) ],
    p_moves => undef,
  },
  {
    text    => 'Position 2 with Black to move',
    fen     => 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R b KQkq -  ',
    fen_out => 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R b KQkq - 0 1',
    to_move => 'b', castling => [1, 1, 1, 1], ep => undef,
    moves   => [ qw (h3g2 b4c3 e6d5 b4b3 g6g5 c7c6 d7d6 c7c5 h8h4 h8h5 h8h6 h8h7 h8f8 h8g8 a6e2 a6d3 a6c4 a6b5 a6b7 a6c8
                     b6a4 b6c4 b6d5 b6c8 f6e4 f6g4 f6d5 f6h5 f6h7 f6g8 e7c5 e7d6 e7d8 e7f8 g7h6 g7f8 a8b8 a8c8 a8d8 e8d8
                     e8f8 e8c8 e8g8) ],
    p_moves => undef,
  },
  {
    text    => 'Position 3',
    fen     => '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
    to_move => 'w', castling => [0, 0, 0, 0], ep => undef,
    moves   => [ qw (e2e3 g2g3 e2e4 g2g4 b4b1 b4b2 b4b3 b4a4 b4c4 b4d4 b4e4 b4f4 a5a4 a5a6) ],
    p_moves => [ qw (e2e3 g2g3 b5b6 e2e4 g2g4 b4b1 b4b2 b4b3 b4a4 b4c4 b4d4 b4e4 b4f4 a5a4 a5a6 a5b6) ],
  },
  {
    text    => 'Position 4',
    fen     => 'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
    to_move => 'w', castling => [0, 0, 1, 1], ep => undef,
    moves   => [ qw (g1h1 c4c5 d2d4 f1f2 f3d4 b4c5) ],
    p_moves => [ qw (d2d3 g2g3 h2h3 c4c5 e4e5 d2d4 g2g4 h2h4 a1b1 a1c1 d1b1 d1c1 d1e1 d1c2 d1e2 d1b3 f1e1 f1f2 g1h1 g1f2
                     f3e1 f3d4 f3h4 f3e5 f3g5 a4c2 a4b3 b4a3 b4c3 b4a5 b4c5 b4d6 b4e7 b4f8 h6g4 h6f5 h6f7 h6g8) ],
    occupied => ['w', Chess4p::Board::_make_bb(A7, H6, B5, A4, B4, C4, E4, F3, A2, D2, G2, H2, A1, D1, F1, G1)],
  },
  {
    text    => 'Position 6',
    fen     => 'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10',
    to_move => 'w', castling => [0, 0, 0, 0], ep => undef,
    moves   => [ qw (b2b3 g2g3 h2h3 a3a4 d3d4 b2b4 h2h4 a1b1 a1c1 a1d1 a1e1 a1a2 f1b1 f1c1 f1d1 f1e1 g1h1 e2d1 e2e1 e2d2
                     e2e3 c3b1 c3d1 c3a2 c3a4 c3b5 c3d5 f3e1 f3d2 f3d4 f3h4 f3e5 c4a2 c4b3 c4b5 c4d5 c4a6 c4e6 c4f7 g5c1
                     g5d2 g5e3 g5f4 g5h4 g5f6 g5h6) ],
    p_moves => undef,
  },
  ########### END: From https://www.chessprogramming.org/Perft_Results #############
  {
    text    => 'Castling rules (1)',
    fen     => 'r3k2r/8/8/8/8/5n2/8/R3K2R w KQkq - 0 1',
    ascii   => "r . . . k . . r\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . n . .\n".
               ". . . . . . . .\n".
               "R . . . K . . R",
    to_move => 'w', castling => [1, 1, 1, 1], ep => undef,
    moves   => [ qw (e1d1 e1f1 e1e2 e1f2) ],
    p_moves => [ qw (a1b1 a1c1 a1d1 a1a2 a1a3 a1a4 a1a5 a1a6 a1a7 a1a8 e1d1 e1f1 e1d2 e1e2 e1f2 h1h8 h1f1 h1g1 h1h2 h1h3 h1h4 h1h5 h1h6 h1h7) ],
  },
  {
    text    => 'Castling rules (2)',
    fen     => 'r3k2r/8/8/8/8/1n6/8/R3K2R w KQkq - 0 1',
    ascii   => "r . . . k . . r\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". n . . . . . .\n".
               ". . . . . . . .\n".
               "R . . . K . . R",
    to_move => 'w', castling => [1, 1, 1, 1], ep => undef,
    moves   => [ qw (a1b1 a1c1 a1d1 a1a2 a1a3 a1a4 a1a5 a1a6 a1a7 a1a8 e1d1 e1f1 e1e2 e1f2 h1h8 h1f1 h1g1 h1h2 h1h3 h1h4 h1h5 h1h6 h1h7 e1g1) ],
    p_moves => [ qw (a1b1 a1c1 a1d1 a1a2 a1a3 a1a4 a1a5 a1a6 a1a7 a1a8 e1d1 e1f1 e1d2 e1e2 e1f2 h1h8 h1f1 h1g1 h1h2 h1h3 h1h4 h1h5 h1h6 h1h7 e1g1) ],
  },
  {
    text    => 'Belgrade Gambit',
    fen     => 'r1bqkb1r/pppp1ppp/2n2n2/3N4/3pP3/5N2/PPP2PPP/R1BQKB1R b KQkq - 1 5',
    to_move => 'b', castling => [1, 1, 1, 1], ep => undef, hmvc => 1, fmvn => 5,
    moves   => [ qw (d4d3 a7a6 b7b6 d7d6 g7g6 h7h6 a7a5 b7b5 g7g5 h7h5 h8g8 c6b4 c6a5 c6e5 c6e7 c6b8 f6e4 f6g4 f6d5 f6h5 f6g8 a8b8 d8e7 f8a3 f8b4 f8c5 f8d6 f8e7) ],
    p_moves => [ qw (d4d3 a7a6 b7b6 d7d6 g7g6 h7h6 a7a5 b7b5 g7g5 h7h5 h8g8 c6b4 c6a5 c6e5 c6e7 c6b8 f6e4 f6g4 f6d5 f6h5 f6g8 a8b8 d8e7 e8e7 f8a3 f8b4 f8c5 f8d6 f8e7) ],
    not_safe => [E8, 0, E8, E7], # ...Ke7 not safe
  },
  {
    text    => 'Keres Opening',
    fen     => 'rnbqk1nr/pppp1ppp/4p3/8/1bPP4/8/PP2PPPP/RNBQKBNR w KQkq - 1 3',
    to_move => 'w', castling => [1, 1, 1, 1], ep => undef, hmvc => 1, fmvn => 3,
    moves   => [ qw (b1d2 b1c3 c1d2 d1d2) ],
    p_moves => [ qw (a2a3 b2b3 e2e3 f2f3 g2g3 h2h3 c4c5 d4d5 a2a4 e2e4 f2f4 g2g4 h2h4 b1d2 b1a3 b1c3 c1d2 c1e3 c1f4 c1g5 c1h6 d1c2 d1d2 d1b3 d1d3 d1a4 e1d2 g1f3 g1h3) ],
    not_safe => [E1, 0, E1, D2], # Kd2 not safe
  },
  {
    text    => 'Sicilian 3.Bb5+',
    fen     => 'rnbqkbnr/pp2pppp/3p4/1Bp5/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 1 3',
    to_move => 'b', castling => [1, 1, 1, 1], ep => undef, hmvc => 1, fmvn => 3,
    moves   => [ qw (b8c6 b8d7 c8d7 d8d7) ],
    p_moves => [ qw (c5c4 d6d5 a7a6 b7b6 e7e6 f7f6 g7g6 h7h6 a7a5 e7e5 f7f5 g7g5 h7h5 b8a6 b8c6 b8d7 c8h3 c8g4 c8f5 c8e6 c8d7 d8a5 d8b6 d8c7 d8d7 e8d7 g8f6 g8h6) ],
    not_safe => [E8, 0, E8, D7], # Kd7 not safe
  },
  {
    text    => 'Suicide 2...Qh4#',
    fen     => 'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
    to_move => 'w', castling => [1, 1, 1, 1], ep => undef, hmvc => 1, fmvn => 3,
    moves   => [],
    p_moves => [ qw (a2a3 b2b3 c2c3 d2d3 e2e3 h2h3 f3f4 g4g5 a2a4 b2b4 c2c4 d2d4 e2e4 b1a3 b1c3 e1f2 f1g2 f1h3 g1h3) ],
    not_safe => [E1, 0, E1, F2], # Kf2 not safe
  },
  {
    text    => 'Scholars mate',
    fen     => 'r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4',
    to_move => 'b', castling => [1, 1, 1, 1], ep => undef, hmvc => 0, fmvn => 4,
    moves   => [],
    p_moves => [ qw (a7a6 b7b6 d7d6 g7g6 h7h6 a7a5 b7b5 d7d5 g7g5 h7h5 h8g8 c6b4 c6d4 c6a5 c6e7 c6b8 f6e4 f6g4 f6d5 f6h5 f6g8 a8b8 d8e7 e8e7 e8f7 f8a3 f8b4 f8c5 f8d6 f8e7) ],
    not_safe => [E8, 0, E8, F7], # Kxf7 not safe
  },
  {
    text    => 'Keres 3.Bd2 Qe7',
    fen     => 'rnb1k1nr/ppppqppp/4p3/8/1bPP4/8/PP1BPPPP/RN1QKBNR w KQkq - 3 4',
    to_move => 'w', castling => [1, 1, 1, 1], ep => undef, hmvc => 3, fmvn => 4,
    moves   => [ qw (a2a3 b2b3 e2e3 f2f3 g2g3 h2h3 c4c5 d4d5 a2a4 e2e4 f2f4 g2g4 h2h4 b1a3 b1c3 d1c1 d1c2 d1b3 d1a4 g1f3 g1h3 d2c3 d2b4) ],
    p_moves => [ qw (a2a3 b2b3 e2e3 f2f3 g2g3 h2h3 c4c5 d4d5 a2a4 e2e4 f2f4 g2g4 h2h4 b1a3 b1c3 d1c1 d1c2 d1b3 d1a4 g1f3 g1h3 d2c1 d2c3 d2e3 d2b4 d2f4 d2g5 d2h6) ],
    not_safe => [E1, Chess4p::Board::_make_bb(D2), D2, E3], # Be3 not safe
    slider_blockers => [E1, Chess4p::Board::_make_bb(D2)],
  },
  {
    text    => 'e.p. + check evasion',
    fen     => '4k3/4r3/8/4Pp2/4K3/8/8/7R w - f6 0 1',
    to_move => 'w', castling => [0, 0, 0, 0], ep => F6, hmvc => 0, fmvn => 1,
    moves   => [ qw (e4d3 e4e3 e4f3 e4d4 e4f4 e4d5 e4f5) ],
    p_moves => [ qw (e5f6 e5e6 h1h8 h1a1 h1b1 h1c1 h1d1 h1e1 h1f1 h1g1 h1h2 h1h3 h1h4 h1h5 h1h6 h1h7 e4d3 e4e3 e4f3 e4d4 e4f4 e4d5 e4f5) ],
    not_safe => [E4, Chess4p::Board::_make_bb(E5), E5, F6], # exf6 ep. not safe
    slider_blockers => [E4, Chess4p::Board::_make_bb(E5)],
  },
  {
    text    => '1.e4 a5 2.b4',
    fen     => 'rnbqkbnr/1ppppppp/8/p7/1P2P3/8/P1PP1PPP/RNBQKBNR b KQkq b3 0 2',
    to_move => 'b', castling => [1, 1, 1, 1], ep => B3, hmvc => 0, fmvn => 2,
    moves   => [ qw (a5b4 a5a4 b7b6 c7c6 d7d6 e7e6 f7f6 g7g6 h7h6 b7b5 c7c5 d7d5 e7e5 f7f5 g7g5 h7h5 a8a6 a8a7 b8a6 b8c6 g8f6 g8h6) ],
    p_moves => undef,
  },
  {
    text    => 'Evade a check',
    fen     => 'rnbqkbnr/ppppp1pp/8/5p1Q/8/4P3/PPPP1PPP/RNB1KBNR b KQkq - 1 2',
    ascii   => "r n b q k b n r\n".
               "p p p p p . p p\n".
               ". . . . . . . .\n".
               ". . . . . p . Q\n".
               ". . . . . . . .\n".
               ". . . . P . . .\n".
               "P P P P . P P P\n".
               "R N B . K B N R",
    to_move => 'b', castling => [1, 1, 1, 1], ep => undef, hmvc => 1, fmvn => 2,
    moves   => [ qw (g7g6) ],
    p_moves => [ qw (f5f4 a7a6 b7b6 c7c6 d7d6 e7e6 g7g6 h7h6 a7a5 b7b5 c7c5 d7d5 e7e5 g7g5 b8a6 b8c6 e8f7 g8f6 g8h6) ],
  },
  {
    text    => 'Nimzo 4.e3 O-O',
    fen     => 'rnbq1rk1/pppp1ppp/4pn2/8/1bPP4/2N1P3/PP3PPP/R1BQKBNR w KQ - 1 5',
    to_move => 'w', castling => [1, 1, 0, 0], ep => undef, hmvc => 1, fmvn => 5,
    moves   => [ qw (a2a3 b2b3 f2f3 g2g3 h2h3 e3e4 c4c5 d4d5 a2a4 f2f4 g2g4 h2h4 a1b1 c1d2 d1c2 d1d2 d1e2 d1b3 d1d3 d1f3
                     d1a4 d1g4 d1h5 e1d2 e1e2 f1e2 f1d3 g1e2 g1f3 g1h3) ],
    p_moves => [ qw (a2a3 b2b3 f2f3 g2g3 h2h3 e3e4 c4c5 d4d5 a2a4 f2f4 g2g4 h2h4 a1b1 c1d2 d1c2 d1d2 d1e2 d1b3 d1d3 d1f3
                     d1a4 d1g4 d1h5 e1d2 e1e2 f1e2 f1d3 g1e2 g1f3 g1h3 c3b1 c3e2 c3a4 c3e4 c3b5 c3d5) ],
    slider_blockers => [E1, Chess4p::Board::_make_bb(C3)],
    sans    => [ { san_in => 'Ne2',    uci_out => 'g1e2', san_out => 'Ne2' },
                 { san_in => 'Nge2',   uci_out => 'g1e2', san_out => 'Ne2' },
                 { san_in => 'Ng1-e2', uci_out => 'g1e2', san_out => 'Ne2' },
               ],
  },
  {
    text    => 'QGD Nge2',
    fen     => 'r1bqk2r/pp1nbppp/2p2n2/3p2B1/3P4/2NBP3/PP3PPP/R2QK1NR w KQkq - 0 8',
    to_move => 'w', castling => [1, 1, 1, 1], ep => undef, hmvc => 0, fmvn => 8,
    moves   => [ qw (a2a3 b2b3 f2f3 g2g3 h2h3 e3e4 a2a4 b2b4 f2f4 g2g4 h2h4 a1b1 a1c1 d1b1 d1c1 d1c2 d1d2 d1e2 d1b3 d1f3
                     d1a4 d1g4 d1h5 e1f1 e1d2 e1e2 g1e2 g1f3 g1h3 c3b1 c3e2 c3a4 c3e4 c3b5 c3d5 d3b1 d3f1 d3c2 d3e2 d3c4
                     d3e4 d3b5 d3f5 d3a6 d3g6 d3h7 g5f4 g5h4 g5f6 g5h6) ],
    p_moves => undef,
    slider_blockers => [E1, 0], # no blockers
    sans    => [ { san_in => 'Ne2', err_like => qr(Ambiguous san: Ne2, matched both g1e2 and c3e2 in r1bqk2r/pp1nbppp/2p2n2/3p2B1/3P4/2NBP3/PP3PPP/R2QK1NR w KQkq - 0 8) },
                 { san_in => 'Nge2',   uci_out => 'g1e2', san_out => 'Nge2' },
                 { san_in => 'Ng1e2',  uci_out => 'g1e2', san_out => 'Nge2'},
                 { san_in => 'Ng1-e2', uci_out => 'g1e2', san_out => 'Nge2' },                 
               ],
  },
  {
    text    => 'Kiwipete derived',
    ascii   => "r . . . k . . r\n".
               "p . p p q p b .\n".
               "b n . . p n Q .\n".
               ". . . P N . . .\n".
               ". p . . P . . .\n".
               ". . N . . . . .\n".
               "P P P B B P p P\n".
               "R . . . K . . R",
    fen     => 'r3k2r/p1ppqpb1/bn2pnQ1/3PN3/1p2P3/2N5/PPPBBPpP/R3K2R b KQkq - 0 1',
    to_move => 'b', castling => [1, 1, 1, 1], ep => undef,
    moves   => [ qw (g2h1q g2h1r g2h1b g2h1n b4c3 e6d5 f7g6 g2g1q g2g1r g2g1b g2g1n b4b3 c7c6 d7d6 c7c5 h8h2 h8h3 h8h4 h8h5
                     h8h6 h8h7 h8f8 h8g8 a6e2 a6d3 a6c4 a6b5 a6b7 a6c8 b6a4 b6c4 b6d5 b6c8 f6e4 f6g4 f6d5 f6h5 f6h7 f6g8 e7c5
                     e7d6 e7d8 e7f8 g7h6 g7f8 a8b8 a8c8 a8d8 e8d8 e8f8 e8c8 e8g8) ],
    p_moves => undef,
    sans    => [ {san_in => 'gxh1=Q', uci_out => 'g2h1q', san_out => 'gxh1=Q+'} ],
  },
  {
    text    => 'e.p. impossible due to an x-ray pin / skewer ',
    ascii   => ". . . . k . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . K P p . r\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . R",
    fen     => '4k3/8/8/3KPp1r/8/8/8/7R w - f6 0 1',
    to_move => 'w', castling => [0, 0, 0, 0], ep => F6,
    moves   => [ qw (e5e6 h1a1 h1b1 h1c1 h1d1 h1e1 h1f1 h1g1 h1h2 h1h3 h1h4 h1h5 d5c4 d5d4 d5c5 d5c6 d5d6 d5e6) ],
    p_moves => [ qw (e5f6 e5e6 h1a1 h1b1 h1c1 h1d1 h1e1 h1f1 h1g1 h1h2 h1h3 h1h4 h1h5 d5c4 d5d4 d5e4 d5c5 d5c6 d5d6 d5e6) ],
# TODO  
# ok($board->_ep_skewered(D5, E5), 'skewered e.p. move');
# ok($board->_is_ep_move(Chess4p::Move->new(E5, F6)), 'exf6 is en passant');
# is($board->_pin_mask('w', E5), 18446744073709551615, 'pin mask');
  },
  {
    text    => 'Pawn moves corner cases',
    ascii   => "r . r . k . . .\n".
               ". P . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . . . . . .\n".
               ". . . p p . . .\n".
               ". . . P P P . .\n".
               ". . . . K . . .",
    fen     => 'r1r1k3/1P6/8/8/8/3pp3/3PPP2/4K3 w - - 0 1',
    to_move => 'w', castling => [0, 0, 0, 0], ep => undef,
    moves   => [ qw (d2e3 e2d3 f2e3 b7a8q b7a8r b7a8b b7a8n b7c8q b7c8r b7c8b b7c8n f2f3 b7b8q b7b8r b7b8b b7b8n f2f4 e1d1 e1f1) ],
    p_moves => undef,
    sans    => [ {san_in => 'b8Q',      uci_out => 'b7b8q',  san_out => 'b8=Q'},
                 {san_in => 'b8=Q',     uci_out => 'b7b8q',  san_out => 'b8=Q'},
                 {san_in => 'bxa8=Q',   uci_out => 'b7a8q',  san_out => 'bxa8=Q'},
                 {san_in => 'b7a8Q',    uci_out => 'b7a8q',  san_out => 'bxa8=Q'},
                 {san_in => 'b7a8q',    uci_out => 'b7a8q',  san_out => 'bxa8=Q'},                                  
                 {san_in => 'bxa8=N',   uci_out => 'b7a8n',  san_out => 'bxa8=N'},
                 {san_in => 'bxc8=R+',  uci_out => 'b7c8r',  san_out => 'bxc8=R+'},
                 {san_in => 'b7b8Q',    uci_out => 'b7b8q',  san_out => 'b8=Q'},
                 {san_in => 'b7b8q',    uci_out => 'b7b8q',  san_out => 'b8=Q'},                 
                 {san_in => 'b7b8=Q',   uci_out => 'b7b8q',  san_out => 'b8=Q'},
                 {san_in => 'b7b8=q',   uci_out => 'b7b8q',  san_out => 'b8=Q'},                 
                 {san_in => 'b7b8=R',   uci_out => 'b7b8r',  san_out => 'b8=R'},
                 # this is rejected similarly in python-chess,
                 # although it might pass with Q as the default promotion:
                 {san_in => 'b7b8',     err_like => qr'Missing promotion piece type: b7b8 in r1r1k3/1P6/8/8/8/3pp3/3PPP2/4K3 w - - 0 1'},
               ],
  },
  {
    text    => 'Suicide ...Qh4# mate to deliver',
    fen     => 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2',
    to_move => 'b', castling => [1, 1, 1, 1], ep => undef,
    moves   => [ qw (e5e4 a7a6 b7b6 c7c6 d7d6 f7f6 g7g6 h7h6 a7a5 b7b5 c7c5 d7d5 f7f5 g7g5 h7h5 b8a6 b8c6 d8h4 d8g5 d8f6
                     d8e7 e8e7 f8a3 f8b4 f8c5 f8d6 f8e7 g8f6 g8h6 g8e7) ],
    p_moves => undef,
    sans    => [ {san_in => 'Qh4#',   uci_out => 'd8h4',  san_out => 'Qh4#'},
                 {san_in => 'Qh4',    uci_out => 'd8h4',  san_out => 'Qh4#'},
                 {san_in => 'Qh4+',   uci_out => 'd8h4',  san_out => 'Qh4#'},                 
               ],
  },
  {
    text    => 'Long castling, rook travels over an attacked square',
    fen     => 'r3k2r/pp1nbpp1/2p1p2p/8/3P1B2/2PB1PP1/PP3P2/2KR3R b kq - 0 20',
    to_move => 'b', castling => [0, 0, 1, 1], ep => undef,
    moves   => [ qw (c6c5 e6e5 h6h5 a7a6 b7b6 f7f6 g7g6 a7a5 b7b5 f7f5 g7g5 h8h7 h8f8 h8g8 d7c5 d7e5 d7b6 d7f6 d7b8 d7f8
                     e7a3 e7b4 e7h4 e7c5 e7g5 e7d6 e7f6 e7d8 e7f8 a8b8 a8c8 a8d8 e8d8 e8f8 e8c8 e8g8) ],
    p_moves => undef,
    sans    => [ {san_in => 'O-O-O',   uci_out => 'e8c8',  san_out => 'O-O-O'},
                 {san_in => '0-0-0',   uci_out => 'e8c8',  san_out => 'O-O-O'},
               ],
  },
  {
    text    => 'e.p. move to be excluded by bitmask in SAN parsing (check situation)',
    ascii   => ". . r . . . . r\n".
               "p . . . p b b .\n".
               ". . . . . . . p\n".
               "p . P . . k p .\n".
               ". P P . p p P P\n".
               ". K N . . . . .\n".
               ". . . R . P . .\n".
               ". . . R . . B .",
    fen     => '2r4r/p3pbb1/7p/p1P2kp1/1PP1ppPP/1KN5/3R1P2/3R2B1 b - g3 0 28',
    to_move => 'b', castling => [0, 0, 0, 0], ep => G3,
    moves   => [ qw (f5g4 f5e5 f5e6 f5f6 f5g6 f4g3) ],
    p_moves => [ qw (f4g3 a5b4 g5h4 e4e3 f4f3 a5a4 h6h5 a7a6 e7e6 e7e5 h8h7 h8d8 h8e8 h8f8 h8g8 f5g4 f5e5 f5e6 f5f6 f5g6
                     f7c4 f7d5 f7h5 f7e6 f7g6 f7e8 f7g8 g7c3 g7d4 g7e5 g7f6 g7f8 c8c5 c8c6 c8c7 c8a8 c8b8 c8d8 c8e8 c8f8 c8g8) ],
    sans    => [ {san_in => 'Kxg4',   uci_out => 'f5g4',  san_out => 'Kxg4'},
                 {san_in => 'fxg3',   uci_out => 'f4g3',  san_out => 'fxg3'},
               # TODO should 'e.p.' not be accepted ?  {san_in => 'fxg3 e.p.',   uci_out => 'f4g3',  san_out => 'fxg3'},
               ],
  },
  {
    text    => 'e.p. move to be excluded by bitmask in SAN parsing (no check)',
    ascii   => ". . . r . . . r\n".
               ". k . . q p . .\n".
               ". . . . p . p .\n".
               "p . n p P n . p\n".
               "P P p . . N . P\n".
               ". . P . . N P .\n".
               ". . . Q . P . .\n".
               ". R . . . R K .",
    fen     => '3r3r/1k2qp2/4p1p1/p1npPn1p/PPp2N1P/2P2NP1/3Q1P2/1R3RK1 b - b3 0 24',
    to_move => 'b', castling => [0, 0, 0, 0], ep => B3,
    moves   => [ qw (c4b3 a5b4 d5d4 g6g5 f7f6 h8h6 h8h7 h8e8 h8f8 h8g8 c5b3 c5d3 c5a4 c5e4 c5a6 c5d7 f5e3 f5g3 f5d4 f5h4
                     f5d6 f5h6 f5g7 b7a6 b7b6 b7c6 b7a7 b7c7 b7a8 b7b8 b7c8 e7h4 e7g5 e7d6 e7f6 e7c7 e7d7 e7e8 e7f8 d8d6
                     d8d7 d8a8 d8b8 d8c8 d8e8 d8f8 d8g8) ],
    p_moves => undef,
    sans    => [ {san_in => 'Nb3',    uci_out => 'c5b3',  san_out => 'Nb3'},
                 {san_in => 'c5b3',   uci_out => 'c5b3',  san_out => 'Nb3'},
                 {san_in => 'a5b4',   uci_out => 'a5b4',  san_out => 'axb4'},
                 {san_in => 'axb4',   uci_out => 'a5b4',  san_out => 'axb4'},                 
               ],
  },
  
  ;


%test_fens = ();
my $undef_fens = 0;

for my $test (@tests) {
    die 'duplicate test position...that is wasteful.' if $test->{fen} && $test_fens{$test->{fen}};
    $undef_fens++ unless $test->{fen};
    die 'undefined fen twice...that is wasteful.' if $undef_fens > 1;
    
    $test_fens{$test->{fen}} = 1 if $test->{fen};
    my $out = "$test->{text} -- " . ($test->{fen} // 'fen == undef') . ' -- ';
    my $board = Chess4p::Board->fromFen($test->{fen});

    my $board_2 =  Chess4p::Board->copyOf($board);
    is($board_2->fen(), $board->fen(), $out.'copy fen is same');

    test_board($board,   $test, $out);
    test_board($board_2, $test, $out);
}

sub test_board {
    my ($board, $test, $out) = @_;

    if ($test->{do_pop}) {
        my $m = $board->pop_move();
        is($m, undef, 'pop is a no-op when move stack is empty');
    };
    
    is($board->errors(), undef, $out.'board is valid');
    is($board->ascii(), $test->{ascii}, $out.'ascii is ok') if $test->{ascii};
    is("$board", $test->{ascii}, $out.'stringify board') if $test->{string};
    
    my $moves = _pseudo_legal_moves($board);
    # if p_moves is undefined, => it should be same as moves
    is_deeply([sort @$moves], [sort @{$test->{p_moves} // $test->{moves}}], $out.'pseudo legal move list ok');

    $moves = _legal_moves($board);
    is_deeply([sort @$moves], [sort @{$test->{moves}}], $out.'legal move list ok');
    
    unless (@$moves) {
        # if no legal moves, random move won't happen
        ok(!$board->_push_random_move(), $out.'no move made');
        is($board->fen(), $test->{fen}, $out.'Position is unchanged');        
    }
    
    if ($test->{fen_out}) {
        is($board->fen(), $test->{fen_out}, $out.'out-fen != in-fen');
    }
    else {
        is($board->fen(), $test->{fen}, $out.'in/out fen matches') if $test->{fen};
        is($board->fen(), 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', $out.'default fen') unless $test->{fen};
    }
    
    is($board->to_move(), $test->{to_move}, $out.'to move') if $test->{to_move};
    is($board->ply(),     $test->{ply},     $out.'ply')     if defined $test->{ply};    

    if ($test->{castling}) {
        is($board->kingside_castling_right('w'),  $test->{castling}[0], $out.'c1');
        is($board->kingside_castling_right('b'),  $test->{castling}[2], $out.'c3');        
        is($board->queenside_castling_right('w'), $test->{castling}[1], $out.'c2');
        is($board->queenside_castling_right('b'), $test->{castling}[3], $out.'c4');        
    };
    is($board->ep_square(), $test->{ep}, $out.'ep square');
    is($board->fullmove_number(), $test->{fmvn}, $out.'full move number') if $test->{fmvn};
    is($board->halfmove_clock(), $test->{hmvc}, $out.'half move clock')  if $test->{hmvc};
    if ($test->{not_safe}) {
        ok(!$board->_is_safe(@{$test->{not_safe}}), $out.'not safe');
    }
    if ($test->{slider_blockers}) {
        is($board->_slider_blockers($test->{slider_blockers}[0]), $test->{slider_blockers}[1], $out.'slider blockers');
    }
    if ($test->{occupied}) {
        is($board->_occupied($test->{occupied}[0]), $test->{occupied}[1], $out.'Occupied');
    }
    if ($test->{pieces}) {
        for my $key (keys %{$test->{pieces}}) {
            is($board->piece_at($key), $test->{pieces}{$key}, $out.'pieces' );
        }
    }
    if ($test->{attackers}) {
        for my $att (@{$test->{attackers}}) {
            is($board->_get_attackers($att->[0], $att->[1]), $att->[2], $out.'attackers');
        }
    }
    if ($test->{k_attack}) {
        for my $ok_sqr (@{$test->{k_attack}}) {
            is($board->_attacked_for_king($ok_sqr->[0]), $ok_sqr->[1], $out.'king attacked on the square');
        }
    }
    if ($test->{sans}) {
        for my $san (@{$test->{sans}}) {
            if ($san->{err_like}) {
                my $m;
                eval {
                    my $m = $board->parse_san($san->{san_in});
                };
                like($@, $san->{err_like}, $out.'err_like');
                is($m, undef, $out.'move is undef');
            }
            else {
                my $m = $board->parse_san($san->{san_in});
                is($m->uci(), $san->{uci_out}, $out.'move parsing');
                my $s = $board->san($m);
                is($s, $san->{san_out}, $out.'san output');
                # push as SAN
                $board->push_move_san($san->{san_in});
                my $m2 = $board->pop_move();
                is($m->uci(), $m2->uci(), 'popped the move (entered as SAN)');
                # and as UCI
                $board->push_move_uci($san->{uci_out});
                $m2 = $board->pop_move();
                is($m->uci(), $m2->uci(), 'popped the move (entered as UCI)');
            }
        }
    }
    if ($test->{find_mv}) {
        for my $mv_spec (@{$test->{find_mv}}) {
            my $move = $board->_find_move(@{$mv_spec->[0]});
            is($move->uci(), $mv_spec->[1], $out.'find move');
        }
    }
}




done_testing;
