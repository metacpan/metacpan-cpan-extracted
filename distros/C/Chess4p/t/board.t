# -*- mode: cperl -*-

use v5.36;

use Test::More;

use utf8;

use Config;
skip_all('Only 64 bit systems are supported.') unless $Config{ptrsize} && $Config{ptrsize} == 8;

use Chess4p::Common qw(FILE_A FILE_B FILE_C FILE_D
                     FILE_E FILE_F FILE_G FILE_H
                     RANK_1 RANK_2 RANK_3 RANK_4
                     RANK_5 RANK_6 RANK_7 RANK_8
                     A1 B1 C1 D1 E1 F1 G1 H1
                     A2 B2 C2 D2 E2 F2 G2 H2
                     A3 B3 C3 D3 E3 F3 G3 H3
                     A4 B4 C4 D4 E4 F4 G4 H4
                     A5 B5 C5 D5 E5 F5 G5 H5
                     A6 B6 C6 D6 E6 F6 G6 H6
                     A7 B7 C7 D7 E7 F7 G7 H7
                     A8 B8 C8 D8 E8 F8 G8 H8
                     EMPTY WP WN WB WR WQ WK
                     BP BN BB BR BQ BK
                     %square_names
                     %square_numbers
                   );

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



# *** Conventional start position
my $fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
my $expected =
  "r n b q k b n r\n".
  "p p p p p p p p\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  "P P P P P P P P\n".
  "R N B Q K B N R";

my $board = Chess4p::Board->fromFen($fen);

is($board->errors(), undef, "board is valid");
ok($board->_check_consistency(), "board is consistent - non-empty FEN");
is($board->ascii(), $expected, "ascii rep of board as expected - non-empty FEN .");
is("$board", $expected, 'Board stringified');
is($board->to_move(), 'w', "white is to move");
ok($board->kingside_castling_right('w'), "white retains kingside castling right");
ok($board->kingside_castling_right('b'), "black retains kingside castling right");
ok($board->queenside_castling_right('w'), "white retains queenside castling right");
ok($board->queenside_castling_right('b'), "black retains queenside castling right");
is($board->fen(), 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1' , "FEN output is correct");
is($board->piece_at(A1), 'R', "Piece at A1 = R");
is($board->piece_at(B1), 'N', "Piece at B1 = N");
is($board->piece_at(C1), 'B', "Piece at C1 = B");
is($board->piece_at(E4), '.', "Piece at E4 = .");
is($board->piece_at(D8), 'q', "Piece at D8 = q");
ok(!defined $board->ep_square(), "no ep square");
is($board->fullmove_number(), 1, "full move number == 1");
is($board->halfmove_clock(), 0, "halfmove clock == 0");

my $moves = _pseudo_legal_moves($board);
is(@$moves, 20, "20 pseudo legal moves.");
my $mv_str =  'a2a3 b2b3 c2c3 d2d3 e2e3 f2f3 g2g3 h2h3 a2a4 b2b4 c2c4 d2d4 e2e4 f2f4 g2g4 h2h4 b1a3 b1c3 g1f3 g1h3';
is((join ' ', @$moves), $mv_str, 'pseudo legal move list as expected');
my $legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');


  

my $attackers = $board->_get_attackers('w', E4);
my $expected_bb =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .";
is(Chess4p::Board::_print_bb($attackers), $expected_bb, 'No attackers');

$attackers = $board->_get_attackers('w', F3);
$expected_bb =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . 1 . 1 .\n".
  ". . . . . . 1 .";
is(Chess4p::Board::_print_bb($attackers), $expected_bb, 'Attackers: Ng1, Pe2, Pg2');

$attackers = $board->_get_attackers('b', E5);
$expected_bb =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .";
is(Chess4p::Board::_print_bb($attackers), $expected_bb, 'No attackers');

$attackers = $board->_get_attackers('b', C6);
$expected_bb =
  ". 1 . . . . . .\n".
  ". 1 . 1 . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .";
is(Chess4p::Board::_print_bb($attackers), $expected_bb, 'Attackers: Nb8, Pd7, Pb7');

ok(!$board->_attacked_for_king(Chess4p::Board::_make_bb(E4)), 'e4 is not attacked for WK');
ok(!$board->_attacked_for_king(Chess4p::Board::_make_bb(C3)), 'c3 is not attacked for WK');
ok($board->_attacked_for_king(Chess4p::Board::_make_bb(C6)), 'c6 is attacked for WK');



# *** Default
$board = Chess4p::Board->fromFen();

is($board->errors(), undef, "board is valid");
ok($board->_check_consistency(), "board is consistent - empty FEN.");
is($board->ascii(), $expected, "ascii rep of board as expected - empty FEN.");
is($board->to_move(), 'w', "white is to move");
ok($board->kingside_castling_right('w'), "white retains kingside castling right");
ok($board->kingside_castling_right('b'), "black retains kingside castling right");
ok($board->queenside_castling_right('w'), "white retains kingside castling right");
ok($board->queenside_castling_right('b'), "black retains kingside castling right");
is($board->fen(), 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1' , "FEN output is correct");

$attackers = $board->_get_attackers('w', F2);
$expected =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . 1 . . .";
is(Chess4p::Board::_print_bb($attackers), $expected, 'Attackers are: Ke1');

$attackers = $board->_get_attackers('w', F3);
$expected =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . 1 . 1 .\n".
  ". . . . . . 1 .";
is(Chess4p::Board::_print_bb($attackers), $expected, 'Attackers are: Ng1, Pe2, Pg2');




# *** Invalid FEN
my $invalid_fen = 'rnbqkbnr/pppppppp/8/8/8/8/ w KQkq - 0 1';

# accept this input as much as possible
$expected =
  "r n b q k b n r\n".
  "p p p p p p p p\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .";

$board = Chess4p::Board->fromFen($invalid_fen);

ok($board->errors() eq 'WK missing', "board is not valid - WK missing");
ok($board->_check_consistency(), "board is consistent");
ok(defined $board, "board created as well as possible from invalid FEN string.");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->fen(), 'rnbqkbnr/pppppppp/8/8/8/8/8/8 w KQkq - 0 1' , "FEN output is correct");

# mend the position to be valid
$expected =
  "r n b q k b n r\n".
  "p p p p p p p p\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . K . . .";
$board->set_piece_at(E1, WK);
is($board->errors(), "Invalid castling rights", "board is now invalid due to castling rights");
is($board->ascii(), $expected, "ascii rep of board as expected.");
ok($board->_check_consistency(), "board is consistent");

 
# *** Empty board
$expected =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .";

$board = Chess4p::Board->empty();

ok($board->errors() eq 'WK missing', "board is not valid - WK missing");
ok($board->_check_consistency(), "board is consistent");
is($board->to_move(), 'w', "white is to move");
is($board->ascii(), $expected, "ascii rep of board as expected.");
ok(! $board->kingside_castling_right('w'), "no white kingside castling right");
ok(! $board->kingside_castling_right('b'), "no black kingside castling right");
ok(! $board->queenside_castling_right('w'), "no white kingside castling right");
ok(! $board->queenside_castling_right('b'), "no black kingside castling right");
is($board->fen(), '8/8/8/8/8/8/8/8 w - - 0 1' , "FEN output is correct"); 


# *** Too many kings
$fen = 'kk6/8/8/8/8/8/8/KK6 w - - 0 1';
$expected =
  "k k . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  "K K . . . . . .";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->errors(), 'Too many WKs', "board is not valid - too many kings");
# check for unwanted side effects:
ok($board->_check_consistency(), "board is consistent");
is($board->to_move(), 'w', "white is to move");
ok(! $board->kingside_castling_right('w'), "no white kingside castling right");
ok(! $board->kingside_castling_right('b'), "no black kingside castling right");
ok(! $board->queenside_castling_right('w'), "no white kingside castling right");
ok(! $board->queenside_castling_right('b'), "no black kingside castling right");
is($board->fen(), 'kk6/8/8/8/8/8/8/KK6 w - - 0 1' , "FEN output is correct"); 
is($board->piece_at(A1), 'K', "Piece at A1 = K");
is($board->piece_at(B1), 'K', "Piece at B1 = K");
is($board->piece_at(C1), '.', "Piece at B1 = .");



# *** Work with 2 boards in parallel
$fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
my $board_2 =  Chess4p::Board->fromFen($fen);
is($board->ascii(), $expected, "ascii rep of board is still the same.");
$expected =
  "r n b q k b n r\n".
  "p p p p p p p p\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  "P P P P P P P P\n".
  "R N B Q K B N R";
is($board_2->ascii(), $expected, "ascii rep of board 2 is different.");
ok($board->_check_consistency(), "board is consistent");
ok($board_2->_check_consistency(), "board 2 is also consistent");

# remove Kb1 to check that error becomes different:
$board->remove_piece_at(B1);
is($board->errors(), 'Too many BKs', "board is not valid - too many _black_ kings");
ok($board->_check_consistency(), "board is still consistent");



# *** With En Passant square (1)
$fen = "rnbqkbnr/ppp3pp/4p3/3pPp2/3P4/8/PPP2PPP/RNBQKBNR w KQkq f6 0 4";
$board = Chess4p::Board->fromFen($fen);

$expected =
  "r n b q k b n r\n".
  "p p p . . . p p\n".
  ". . . . p . . .\n".
  ". . . p P p . .\n".
  ". . . P . . . .\n".
  ". . . . . . . .\n".
  "P P P . . P P P\n".
  "R N B Q K B N R";
is($board->ascii(), $expected, "ascii rep is expected.");
ok($board->_check_consistency(), "board is consistent");

is($board->ep_square(), F6, "ep square == f6");
ok($board->_check_consistency(), "board is consistent");
is($board->fullmove_number(), 4, "full move number == 4");
is($board->halfmove_clock(), 0, "halfmove clock == 0");
#                  rnbqkbnr/ppp3p/43/3Pp2/34/8/PPP2PP/RNBQKBNR w KQkq - 0 1
is($board->fen(), 'rnbqkbnr/ppp3pp/4p3/3pPp2/3P4/8/PPP2PPP/RNBQKBNR w KQkq f6 0 4', 'FEN output is correct');

$moves = _pseudo_legal_moves($board);
is(@$moves, 37, "37 pseudo legal moves.");
$mv_str = 'e5f6 a2a3 b2b3 c2c3 f2f3 g2g3 h2h3 a2a4 b2b4 c2c4 f2f4 g2g4 h2h4 b1d2 b1a3 b1c3 c1d2 c1e3 c1f4 c1g5 c1h6 d1d2 d1e2 d1d3 d1f3 d1g4 d1h5 e1d2 e1e2 f1e2 f1d3 f1c4 f1b5 f1a6 g1e2 g1f3 g1h3';
is((join ' ', @$moves), $mv_str, 'pseudo legal move list as expected');
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');
ok($board->_check_consistency(), "board is consistent");

$attackers = $board->_get_attackers('w', E2);
$expected_bb =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . 1 1 1 1 .";
is(Chess4p::Board::_print_bb($attackers), $expected_bb, 'Attackers: Qd1, Ke1, Bf1, Ng1');

$attackers = $board->_get_attackers('b', D7);
$expected_bb =
  ". 1 1 1 1 . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .";
is(Chess4p::Board::_print_bb($attackers), $expected_bb, 'Attackers: Qd8, Ke8, Bc8, Nb8');

# Push exf6 e.p.
my $debug_state = $board->_debug_state();
$board->push_move(Chess4p::Move->new(E5, F6));
$expected =
  "r n b q k b n r\n".
  "p p p . . . p p\n".
  ". . . . p P . .\n".
  ". . . p . . . .\n".
  ". . . P . . . .\n".
  ". . . . . . . .\n".
  "P P P . . P P P\n".
  "R N B Q K B N R";
ok($board->_check_consistency(), "board is consistent after push");
is("$board", $expected, 'Board is updated as expected');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 30, "30 legal moves.");
is((join ' ', @$legal_moves), 'g7f6 e6e5 a7a6 b7b6 c7c6 g7g6 h7h6 a7a5 b7b5 c7c5 g7g5 h7h5 b8a6 b8c6 b8d7 c8d7 d8d6 d8f6 d8d7 d8e7 e8d7 e8f7 f8a3 f8b4 f8c5 f8d6 f8e7 g8f6 g8h6 g8e7', 'legal move list as expected');

# Pop
my $move = $board->pop_move();
is("$move", 'e5f6', 'Move popped correctly');
is($board->_debug_state(), $debug_state, 'State after push/pop is the same as it was before.');
$expected =
  "r n b q k b n r\n".
  "p p p . . . p p\n".
  ". . . . p . . .\n".
  ". . . p P p . .\n".
  ". . . P . . . .\n".
  ". . . . . . . .\n".
  "P P P . . P P P\n".
  "R N B Q K B N R";
ok($board->_check_consistency(), "board is consistent after pop");
is("$board", $expected, 'Board is updated as expected');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 37, "37 legal moves.");
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');



# *** With En Passant square (2)
$fen = "rnbqkbnr/pppp1ppp/8/8/3PpP2/4P3/PPP3PP/RNBQKBNR b KQkq f3 0 3";
$board = Chess4p::Board->fromFen($fen);

$expected =
  "r n b q k b n r\n".
  "p p p p . p p p\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . P p P . .\n".
  ". . . . P . . .\n".
  "P P P . . . P P\n".
  "R N B Q K B N R";
is($board->ascii(), $expected, "ascii rep is expected.");
ok($board->_check_consistency(), "board is consistent");

is($board->ep_square(), F3, "ep square == f3");
ok($board->_check_consistency(), "board is consistent");
is($board->fullmove_number(), 3, "full move number == 3");
is($board->halfmove_clock(), 0, "halfmove clock == 0");

$moves = _pseudo_legal_moves($board);
is(@$moves, 30, "30 pseudo legal moves.");
$mv_str = 'e4f3 a7a6 b7b6 c7c6 d7d6 f7f6 g7g6 h7h6 a7a5 b7b5 c7c5 d7d5 f7f5 g7g5 h7h5 b8a6 b8c6 d8h4 d8g5 d8f6 d8e7 e8e7 f8a3 f8b4 f8c5 f8d6 f8e7 g8f6 g8h6 g8e7';
is((join ' ', @$moves), $mv_str, 'pseudo legal move list as expected');
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');
ok($board->_check_consistency(), "board is consistent");

ok(!$board->_attacked_for_king(Chess4p::Board::_make_bb(E4)), 'e4 is not attacked for BK');
ok(!$board->_attacked_for_king(Chess4p::Board::_make_bb(H6)), 'h6 is not attacked for BK');
ok($board->_attacked_for_king(Chess4p::Board::_make_bb(D3)), 'd3 is attacked for BK');


# *** Too many pawns
$fen = 'k7/pppppppp/p7/8/8/P7/PPPPPPPP/K7 w - - 0 1';
$expected =
  "k . . . . . . .\n".
  "p p p p p p p p\n".
  "p . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  "P . . . . . . .\n".
  "P P P P P P P P\n".
  "K . . . . . . .";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->errors(), 'Too many WPs', "board is not valid - to many white pawns");


# *** Too many pieces
$fen = 'k7/pppppppp/8/8/8/N7/PPPPPPPP/RNBQKBNR w - - 0 1';
$expected =
  "k . . . . . . .\n".
  "p p p p p p p p\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  "N . . . . . . .\n".
  "P P P P P P P P\n".
  "R N B Q K B N R";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->errors(), 'Too many White stones', "board is not valid - to many white pawns");
is($board->remove_piece_at(E4), EMPTY, "E4 is empty, so removing piece at E4 returns empty");

is($board->remove_piece_at(A3), WN, "removal of Na3 -> returns WN");
is($board->piece_at(A3), '.', "Piece at A3 = .");
ok($board->_check_consistency(), "board is consistent");
ok(!defined $board->errors(), "board is valid");
 

# *** missing FEN parts after pieces
$fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR';
$expected =
  "r n b q k b n r\n".
  "p p p p p p p p\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  "P P P P P P P P\n".
  "R N B Q K B N R";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
ok(!defined $board->errors(), "board is valid");


# *** Black to move - with a pin
$fen = "rnbqk2r/pppp1ppp/4pn2/8/1bPP4/2N1P3/PP3PPP/R1BQKBNR b KQkq - 0 4";
$expected =
  "r n b q k . . r\n".
  "p p p p . p p p\n".
  ". . . . p n . .\n".
  ". . . . . . . .\n".
  ". b P P . . . .\n".
  ". . N . P . . .\n".
  "P P . . . P P P\n".
  "R . B Q K B N R";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->errors(), undef, "board is valid");
is($board->to_move(), 'b', 'black to move');

$moves = _pseudo_legal_moves($board);
is(@$moves, 33, "33 pseudo legal moves.");
$mv_str = 'e6e5 a7a6 b7b6 c7c6 d7d6 g7g6 h7h6 a7a5 b7b5 c7c5 d7d5 g7g5 h7h5 h8f8 h8g8 b4a3 b4c3 b4a5 b4c5 b4d6 b4e7 b4f8 f6e4 f6g4 f6d5 f6h5 f6g8 b8a6 b8c6 d8e7 e8e7 e8f8 e8g8';
is((join ' ', @$moves), $mv_str, 'pseudo legal move list as expected');
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');



# *** Pawn moves corner cases

$fen = "r1r1k3/1P6/8/8/8/3pp3/3PPP2/4K3 w - - 0 1";
$expected =
  "r . r . k . . .\n".
  ". P . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . p p . . .\n".
  ". . . P P P . .\n".
  ". . . . K . . .";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->errors(), undef, "board is valid");
is($board->to_move(), 'w', 'white to move');

$moves = _pseudo_legal_moves($board);
is(@$moves, 19, "19 pseudo legal moves.");
$mv_str = 'd2e3 e2d3 f2e3 b7a8q b7a8r b7a8b b7a8n b7c8q b7c8r b7c8b b7c8n f2f3 b7b8q b7b8r b7b8b b7b8n f2f4 e1d1 e1f1';
is((join ' ', @$moves), $mv_str, 'pseudo legal move list as expected');
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');



# *** Pawns on back ranks
$fen = 'kp6/8/8/8/8/8/8/KP6 w - - 0 1';
$expected =
  "k p . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  "K P . . . . . .";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->errors(), 'Pawns on back rank', "board is not valid - pawns on back rank");


# *** Invalid e.p. square
$fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq f6 0 1';
$board = Chess4p::Board->fromFen($fen);
is($board->errors(), "Invalid e.p. square", "board is valid");

# mirrored
$fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq f3 0 1';
$board = Chess4p::Board->fromFen($fen);
is($board->errors(), "Invalid e.p. square", "board is valid");




# *** Invalid castling rights
$fen = "4k3/8/8/8/8/8/8/4K3 w KQkq - 0 1";
$expected =
  ". . . . k . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . K . . .";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->errors(), 'Invalid castling rights', "board is not valid - invalid castling rights");




$fen = "6k1/4q3/5n2/8/4N3/5Q2/8/4K3 w - - 0 1";
$expected =
  ". . . . . . k .\n".
  ". . . . q . . .\n".
  ". . . . . n . .\n".
  ". . . . . . . .\n".
  ". . . . N . . .\n".
  ". . . . . Q . .\n".
  ". . . . . . . .\n".
  ". . . . K . . .";

$board = Chess4p::Board->fromFen($fen);
$moves = _pseudo_legal_moves($board);

is(@$moves, 31, "31 pseudo legal moves.");
$mv_str = 'e1d1 e1f1 e1d2 e1e2 e1f2 f3d1 f3f1 f3h1 f3e2 f3f2 f3g2 f3a3 f3b3 f3c3 f3d3 f3e3 f3g3 f3h3 f3f4 f3g4 f3f5 f3h5 f3f6 e4d2 e4f2 e4c3 e4g3 e4c5 e4g5 e4d6 e4f6';
is((join ' ', @$moves), $mv_str, 'pseudo legal move list as expected');
$legal_moves = _legal_moves($board);
$mv_str = 'e1d1 e1f1 e1d2 e1e2 e1f2 f3d1 f3f1 f3h1 f3e2 f3f2 f3g2 f3a3 f3b3 f3c3 f3d3 f3e3 f3g3 f3h3 f3f4 f3g4 f3f5 f3h5 f3f6';
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');



# *** Attackers

$attackers = $board->_get_attackers('w', F2);
$expected =
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . 1 . . .\n".
  ". . . . . 1 . .\n".
  ". . . . . . . .\n".
  ". . . . 1 . . .";
is(Chess4p::Board::_print_bb($attackers), $expected, 'Attackers are: Ke1, Ne4, Qf3');

$attackers =  $board->_get_attackers('b', H7);
$expected =
  ". . . . . . 1 .\n".
  ". . . . 1 . . .\n".
  ". . . . . 1 . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .\n".
  ". . . . . . . .";
is(Chess4p::Board::_print_bb($attackers), $expected, 'Attackers are: Kg8, Nf6, Qe7');


# *** Castling

$fen = "r3k2r/pp1bppbp/2np1np1/q7/3NP3/2N1BP2/PPPQB1PP/R3K2R w KQkq - 1 10";
$expected =
  "r . . . k . . r\n".
  "p p . b p p b p\n".
  ". . n p . n p .\n".
  "q . . . . . . .\n".
  ". . . N P . . .\n".
  ". . N . B P . .\n".
  "P P P Q B . P P\n".
  "R . . . K . . R";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->errors(), undef, "board is valid");
$moves = _pseudo_legal_moves($board);
is(@$moves, 44, "44 pseudo legal moves.");
$mv_str = 'a2a3 b2b3 g2g3 h2h3 f3f4 e4e5 a2a4 b2b4 g2g4 h2h4 a1b1 a1c1 a1d1 e1d1 e1f1 e1f2 h1f1 h1g1 d2c1 d2d1 d2d3 e2d1 e2f1 e2d3 e2c4 e2b5 e2a6 c3b1 c3d1 c3a4 c3b5 c3d5 e3g1 e3f2 e3f4 e3g5 e3h6 d4b3 d4b5 d4f5 d4c6 d4e6 e1g1 e1c1';
is((join ' ', @$moves), $mv_str, 'pseudo legal move list as expected');
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');

# Push O-O
$debug_state = $board->_debug_state();
$board->push_move(Chess4p::Move->new(E1, G1));

my $expected_2 =
  "r . . . k . . r\n".
  "p p . b p p b p\n".
  ". . n p . n p .\n".
  "q . . . . . . .\n".
  ". . . N P . . .\n".
  ". . N . B P . .\n".
  "P P P Q B . P P\n".
  "R . . . . R K .";

ok($board->_check_consistency(), "board is consistent after push");
is("$board", $expected_2, 'Board is updated as expected');

# Pop O-O
$move = $board->pop_move();
is("$move", 'e1g1', 'Move popped correctly');
is($board->_debug_state(), $debug_state, 'State after push/pop is the same as it was before.');

ok($board->_check_consistency(), "board is consistent after pop");
is("$board", $expected, 'Board is updated as expected');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 44, "44 legal moves.");
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');


# *** Check

$fen = "rnbqkbnr/ppppp1pp/8/5p1Q/8/4P3/PPPP1PPP/RNB1KBNR b KQkq - 1 2";
$expected =
  "r n b q k b n r\n".
  "p p p p p . p p\n".
  ". . . . . . . .\n".
  ". . . . . p . Q\n".
  ". . . . . . . .\n".
  ". . . . P . . .\n".
  "P P P P . P P P\n".
  "R N B . K B N R";

$board = Chess4p::Board->fromFen($fen);

ok($board->_check_consistency(), "board is consistent");
is($board->ascii(), $expected, "ascii rep of board as expected.");
is($board->errors(), undef, "board is valid");
$moves = _pseudo_legal_moves($board);
is(@$moves, 19, "19 pseudo legal moves.");
$mv_str = 'f5f4 a7a6 b7b6 c7c6 d7d6 e7e6 g7g6 h7h6 a7a5 b7b5 c7c5 d7d5 e7e5 g7g5 b8a6 b8c6 e8f7 g8f6 g8h6';
is((join ' ', @$moves), $mv_str, 'pseudo legal move list as expected');
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), 'g7g6', 'legal move list as expected');

my $ev_itr = $board->_evasions_iter(E8, Chess4p::Board::_make_bb(H5));
my $ev = $ev_itr->();
is($ev->uci(), 'g7g6', 'Evasion is g7g6');
$ev = $ev_itr->();
my $uci = defined $ev ? $ev->uci() : "";
is($ev, undef, "no more evasions: $uci");


# *** Belgrade Gambit

$fen = "r1bqkb1r/pppp1ppp/2n2n2/3N4/3pP3/5N2/PPP2PPP/R1BQKB1R b KQkq - 1 5";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), 'd4d3 a7a6 b7b6 d7d6 g7g6 h7h6 a7a5 b7b5 g7g5 h7h5 h8g8 c6b4 c6a5 c6e5 c6e7 c6b8 f6e4 f6g4 f6d5 f6h5 f6g8 a8b8 d8e7 f8a3 f8b4 f8c5 f8d6 f8e7', 'legal move list as expected');
ok(!$board->_is_safe(E8, 0, E8, E7), 'Ke7 is not safe');
ok($board->_check_consistency(), "board is consistent");


# *** Keres Opening

$fen = "rnbqk1nr/pppp1ppp/4p3/8/1bPP4/8/PP2PPPP/RNBQKBNR w KQkq - 1 3";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), 'b1d2 b1c3 c1d2 d1d2', 'legal move list as expected');


# *** Sicilian 3.Bb5+

$fen = "rnbqkbnr/pp2pppp/3p4/1Bp5/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 1 3";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), 'b8c6 b8d7 c8d7 d8d7', 'legal move list as expected');


# *** Suicide 2...Qh4#

$fen = "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is((join ' ', @$legal_moves), '', 'legal move list as expected');


# *** Keres 3.Bd2 Qe7

$fen = "rnb1k1nr/ppppqppp/4p3/8/1bPP4/8/PP1BPPPP/RN1QKBNR w KQkq - 3 4";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is($board->_slider_blockers(E1), Chess4p::Board::_make_bb(D2), 'blockers = D2');
is((join ' ', @$legal_moves), 'a2a3 b2b3 e2e3 f2f3 g2g3 h2h3 c4c5 d4d5 a2a4 e2e4 f2f4 g2g4 h2h4 b1a3 b1c3 d1c1 d1c2 d1b3 d1a4 g1f3 g1h3 d2c3 d2b4', 'legal move list as expected');


########### From https://www.chessprogramming.org/Perft_Results #############

# *** Position 2

$fen = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - ";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 48, "48 legal moves.");
is((join ' ', @$legal_moves), 'g2h3 d5e6 a2a3 b2b3 g2g3 d5d6 a2a4 g2g4 a1b1 a1c1 a1d1 e1d1 e1f1 h1f1 h1g1 d2c1 d2e3 d2f4 d2g5 d2h6 e2d1 e2f1 e2d3 e2c4 e2b5 e2a6 c3b1 c3d1 c3a4 c3b5 f3d3 f3e3 f3g3 f3h3 f3f4 f3g4 f3f5 f3h5 f3f6 e5d3 e5c4 e5g4 e5c6 e5g6 e5d7 e5f7 e1g1 e1c1', 'legal move list as expected');


# *** Position 2 Black to move

$fen = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R b KQkq - ";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 43, "43 legal moves.");
is((join ' ', @$legal_moves), 'h3g2 b4c3 e6d5 b4b3 g6g5 c7c6 d7d6 c7c5 h8h4 h8h5 h8h6 h8h7 h8f8 h8g8 a6e2 a6d3 a6c4 a6b5 a6b7 a6c8 b6a4 b6c4 b6d5 b6c8 f6e4 f6g4 f6d5 f6h5 f6h7 f6g8 e7c5 e7d6 e7d8 e7f8 g7h6 g7f8 a8b8 a8c8 a8d8 e8d8 e8f8 e8c8 e8g8', 'legal move list as expected');


# *** Position 3 

$fen = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1 ";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 14, "14 legal moves.");
is((join ' ', @$legal_moves), 'e2e3 g2g3 e2e4 g2g4 b4b1 b4b2 b4b3 b4a4 b4c4 b4d4 b4e4 b4f4 a5a4 a5a6', 'legal move list as expected');


# *** Position 4

$fen = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1";
$board = Chess4p::Board->fromFen($fen);
my $occupied = $board->_occupied('w');
is($occupied, Chess4p::Board::_make_bb(A7, H6, B5, A4, B4, C4, E4, F3, A2, D2, G2, H2, A1, D1, F1, G1), 'occupied squares');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 6, "6 legal moves.");
is((join ' ', @$legal_moves), 'g1h1 c4c5 d2d4 f1f2 f3d4 b4c5', 'legal move list as expected');


# *** Position 5

$fen = "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8  ";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 44, "44 legal moves.");
is((join ' ', @$legal_moves), 'd7c8q d7c8r d7c8b d7c8n a2a3 b2b3 c2c3 g2g3 h2h3 a2a4 b2b4 g2g4 h2h4 b1d2 b1a3 b1c3 c1d2 c1e3 c1f4 c1g5 c1h6 d1d2 d1d3 d1d4 d1d5 d1d6 e1f1 e1d2 e1f2 h1f1 h1g1 e2g1 e2c3 e2g3 e2d4 e2f4 c4b3 c4d3 c4b5 c4d5 c4a6 c4e6 c4f7 e1g1', 'legal move list as expected');

# Push d7xc8=Q
$debug_state = $board->_debug_state();
$board->push_move(Chess4p::Move->new(D7, C8, 'Q'));
$expected = "r n Q q . k . r\n".
            "p p . . b p p p\n".
            ". . p . . . . .\n".
            ". . . . . . . .\n".
            ". . B . . . . .\n".
            ". . . . . . . .\n".
            "P P P . N n P P\n".
            "R N B Q K . . R";
ok($board->_check_consistency(), "board is consistent after push");
is("$board", $expected, 'Board is updated as expected');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 31, "6 legal moves.");
is((join ' ', @$legal_moves), 'c6c5 a7a6 b7b6 f7f6 g7g6 h7h6 a7a5 b7b5 f7f5 g7g5 h7h5 h8g8 f2d1 f2h1 f2d3 f2h3 f2e4 f2g4 e7a3 e7b4 e7h4 e7c5 e7g5 e7d6 e7f6 b8a6 b8d7 d8c8 d8e8 f8e8 f8g8', 'legal move list as expected');

$expected = "r n b q . k . r\n".
            "p p . P b p p p\n".
            ". . p . . . . .\n".
            ". . . . . . . .\n".
            ". . B . . . . .\n".
            ". . . . . . . .\n".
            "P P P . N n P P\n".
            "R N B Q K . . R";
# Pop and check state
$move = $board->pop_move();
is("$move", 'd7c8q', 'Move popped correctly');
is($board->_debug_state(), $debug_state, 'State after push/pop is the same as it was before.');

ok($board->_check_consistency(), "board is consistent after pop");
is("$board", $expected, 'Board is updated as expected');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 44, "44 legal moves.");
is((join ' ', @$legal_moves), 'd7c8q d7c8r d7c8b d7c8n a2a3 b2b3 c2c3 g2g3 h2h3 a2a4 b2b4 g2g4 h2h4 b1d2 b1a3 b1c3 c1d2 c1e3 c1f4 c1g5 c1h6 d1d2 d1d3 d1d4 d1d5 d1d6 e1f1 e1d2 e1f2 h1f1 h1g1 e2g1 e2c3 e2g3 e2d4 e2f4 c4b3 c4d3 c4b5 c4d5 c4a6 c4e6 c4f7 e1g1', 'legal move list as expected');



# *** Position 5 mirrored

$fen = "rnbqk2r/ppp1nNpp/8/2b5/8/2P5/PP1pBPPP/RNBQ1K1R b kq - 1 8";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 44, "44 legal moves.");
is((join ' ', @$legal_moves), 'd2c1q d2c1r d2c1b d2c1n a7a6 b7b6 c7c6 g7g6 h7h6 a7a5 b7b5 g7g5 h7h5 h8f8 h8g8 c5f2 c5a3 c5e3 c5b4 c5d4 c5b6 c5d6 e7d5 e7f5 e7c6 e7g6 e7g8 b8a6 b8c6 b8d7 c8h3 c8g4 c8f5 c8e6 c8d7 d8d3 d8d4 d8d5 d8d6 d8d7 e8d7 e8f7 e8f8 e8g8', 'legal move list as expected');

# Push d2xc1=Q
$debug_state = $board->_debug_state();
$board->push_move(Chess4p::Move->new(D2, C1, 'Q'));
$expected = "r n b q k . . r\n".
            "p p p . n N p p\n".
            ". . . . . . . .\n".
            ". . b . . . . .\n".
            ". . . . . . . .\n".
            ". . P . . . . .\n".
            "P P . . B P P P\n".
            "R N q Q . K . R";
ok($board->_check_consistency(), "board is consistent after push");
is("$board", $expected, 'Board is updated as expected');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 31, "6 legal moves.");
is((join ' ', @$legal_moves), 'a2a3 b2b3 f2f3 g2g3 h2h3 c3c4 a2a4 b2b4 f2f4 g2g4 h2h4 b1d2 b1a3 d1c1 d1e1 f1e1 f1g1 h1g1 e2d3 e2f3 e2c4 e2g4 e2b5 e2h5 e2a6 f7h8 f7e5 f7g5 f7d6 f7h6 f7d8', 'legal move list as expected');

# Pop and check state
$move = $board->pop_move();
is("$move", 'd2c1q', 'Move popped correctly');
is($board->_debug_state(), $debug_state, 'State after push/pop is the same as it was before.');

$expected = "r n b q k . . r\n".
            "p p p . n N p p\n".
            ". . . . . . . .\n".
            ". . b . . . . .\n".
            ". . . . . . . .\n".
            ". . P . . . . .\n".
            "P P . p B P P P\n".
            "R N B Q . K . R";

ok($board->_check_consistency(), "board is consistent after pop");
is("$board", $expected, 'Board is updated as expected');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 44, "44 legal moves.");
is((join ' ', @$legal_moves), 'd2c1q d2c1r d2c1b d2c1n a7a6 b7b6 c7c6 g7g6 h7h6 a7a5 b7b5 g7g5 h7h5 h8f8 h8g8 c5f2 c5a3 c5e3 c5b4 c5d4 c5b6 c5d6 e7d5 e7f5 e7c6 e7g6 e7g8 b8a6 b8c6 b8d7 c8h3 c8g4 c8f5 c8e6 c8d7 d8d3 d8d4 d8d5 d8d6 d8d7 e8d7 e8f7 e8f8 e8g8', 'legal move list as expected');



# *** Position 6

$fen = "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10 ";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 46, "46 legal moves.");
is((join ' ', @$legal_moves), 'b2b3 g2g3 h2h3 a3a4 d3d4 b2b4 h2h4 a1b1 a1c1 a1d1 a1e1 a1a2 f1b1 f1c1 f1d1 f1e1 g1h1 e2d1 e2e1 e2d2 e2e3 c3b1 c3d1 c3a2 c3a4 c3b5 c3d5 f3e1 f3d2 f3d4 f3h4 f3e5 c4a2 c4b3 c4b5 c4d5 c4a6 c4e6 c4f7 g5c1 g5d2 g5e3 g5f4 g5h4 g5f6 g5h6', 'legal move list as expected');


# *** En passant to evade a check

$fen = "8/8/4k3/4Pp2/4K3/8/8/8 w - f6 0 4";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 6, "6 legal moves.");
is((join ' ', @$legal_moves), 'e4d3 e4e3 e4f3 e4d4 e4f4 e5f6', 'legal move list as expected');

# Push Ke4-e3
$debug_state = $board->_debug_state();
$board->push_move(Chess4p::Move->new(E4, E3));
$expected = ". . . . . . . .\n".
            ". . . . . . . .\n".
            ". . . . k . . .\n".
            ". . . . P p . .\n".
            ". . . . . . . .\n".
            ". . . . K . . .\n".
            ". . . . . . . .\n".
            ". . . . . . . .";
ok($board->_check_consistency(), "board is consistent after push");
is("$board", $expected, 'Board is updated as expected');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 6, "6 legal moves.");
is((join ' ', @$legal_moves), 'f5f4 e6d5 e6e5 e6d7 e6e7 e6f7', 'legal move list as expected');

$expected = ". . . . . . . .\n".
            ". . . . . . . .\n".
            ". . . . k . . .\n".
            ". . . . P p . .\n".
            ". . . . K . . .\n".
            ". . . . . . . .\n".
            ". . . . . . . .\n".
            ". . . . . . . .";
# Pop and check state
$move = $board->pop_move();
is("$move", 'e4e3', 'Move popped correctly');
is($board->_debug_state(), $debug_state, 'State after push/pop is the same as it was before.');

ok($board->_check_consistency(), "board is consistent after pop");
is("$board", $expected, 'Board is updated as expected');
$legal_moves = _legal_moves($board);
is(@$legal_moves, 6, "6 legal moves.");
is((join ' ', @$legal_moves), 'e4d3 e4e3 e4f3 e4d4 e4f4 e5f6', 'legal move list as expected');


# *** Castling rules

$fen = "r3k2r/8/8/8/8/5n2/8/R3K2R w KQkq - 0 1";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 4, "4 legal moves.");
is((join ' ', @$legal_moves), 'e1d1 e1f1 e1e2 e1f2', 'legal move list as expected');


$fen = "r3k2r/8/8/8/8/1n6/8/R3K2R w KQkq - 0 1";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 24, "24 legal moves.");
is((join ' ', @$legal_moves), 'a1b1 a1c1 a1d1 a1a2 a1a3 a1a4 a1a5 a1a6 a1a7 a1a8 e1d1 e1f1 e1e2 e1f2 h1h8 h1f1 h1g1 h1h2 h1h3 h1h4 h1h5 h1h6 h1h7 e1g1', 'legal move list as expected');



# *** e.p. + check evasion

$fen = "4k3/4r3/8/4Pp2/4K3/8/8/7R w KQq f6 0 1";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 7, "7 legal moves.");
is((join ' ', @$legal_moves), 'e4d3 e4e3 e4f3 e4d4 e4f4 e4d5 e4f5', 'legal move list as expected');


# e.p. vs. a pin

$fen = "4k3/8/8/3KPp1r/8/8/8/7R w KQq f6 0 1";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
ok($board->_ep_skewered(D5, E5), 'skewered e.p. move');
ok($board->_is_ep_move(Chess4p::Move->new(E5, F6)), 'exf6 is en passant');
is($board->_pin_mask('w', E5), 18446744073709551615, 'pin mask');
is(@$legal_moves, 18, "18 legal moves.");
is((join ' ', @$legal_moves), 'e5e6 h1a1 h1b1 h1c1 h1d1 h1e1 h1f1 h1g1 h1h2 h1h3 h1h4 h1h5 d5c4 d5d4 d5c5 d5c6 d5d6 d5e6', 'legal move list as expected');



# *** Pseudo legals with bitboard from/to filters

$fen = "rnb2k1r/pp1Pbppp/1qp5/8/2B5/8/PPP1NKPP/RNBQ3R w - - 1 9";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 7, "7 legal moves.");
is((join ' ', @$legal_moves), 'f2e1 f2f1 f2f3 f2g3 c1e3 d1d4 e2d4', 'legal move list as expected');

$moves = _pseudo_legal_moves($board, ~Chess4p::Board::_make_bb(F2), Chess4p::Board::_make_bb(B6, C5, D4, E3));
is(@$moves, 3, "3 moves.");
is((join ' ', @$moves), 'c1e3 d1d4 e2d4', 'pseudo legal move list as expected');



# *** Kiwipete derived

$fen = "r3k2r/p1ppqpb1/bn2pnQ1/3PN3/1p2P3/2N5/PPPBBPpP/R3K2R b KQkq - 0 1";
$board = Chess4p::Board->fromFen($fen);
$legal_moves = _legal_moves($board);
is(@$legal_moves, 52, "52 legal moves.");
$mv_str = 'g2h1q g2h1r g2h1b g2h1n b4c3 e6d5 f7g6 g2g1q g2g1r g2g1b g2g1n b4b3 c7c6 d7d6 c7c5 h8h2 h8h3 h8h4 h8h5 h8h6 h8h7 h8f8 h8g8 a6e2 a6d3 a6c4 a6b5 a6b7 a6c8 b6a4 b6c4 b6d5 b6c8 f6e4 f6g4 f6d5 f6h5 f6h7 f6g8 e7c5 e7d6 e7d8 e7f8 g7h6 g7f8 a8b8 a8c8 a8d8 e8d8 e8f8 e8c8 e8g8';
is((join ' ', @$legal_moves), $mv_str, 'legal move list as expected');

$moves = _pseudo_legal_moves($board);
is(@$moves, 52, "52 moves.");
is((join ' ', @$moves), $mv_str, 'pseudo legal move list as expected');


  



done_testing;
