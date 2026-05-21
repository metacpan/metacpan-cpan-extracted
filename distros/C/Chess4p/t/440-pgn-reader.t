use v5.36;

use Test::More;

use utf8;

use Config;

plan skip_all => 'Only 64 bit systems are supported.'  unless $Config{ptrsize} && $Config{ptrsize} == 8;

plan tests => 46;


my $visitor = TestVisitor->new();

use Chess4p::Pgn::Reader qw(read_game);

$Chess4p::Pgn::Reader::_debug = 0;
$visitor->debug(0);

my ($res, $err) = read_game(*DATA, $visitor);
is($res, 'e2e4,e7e5,1,g1f3,2,b8c6,5,f1a6,4,b7a6,3,a2a3,6,a6a5,1,e1g1,--,*,', 'Game 1 ok.');
is(@$err, 0, 'No error');

($res, $err) = read_game(*DATA, $visitor);
is($res, 'd2d4,d7d5,[QGD.],c2c4,e7e6,b1c3,g8f6,c4d5,e6d5,c1g5,(,g1f3,),1-0,', 'Game 2 ok.');
is (@$err, 0, 'No error');
 
($res, $err) = read_game(*DATA, $visitor);
is($res,
   'Event=World Senior Teams +50,Site=Radebeul GER,Date=2016.07.03,Round=8.2,White=Anastasian, A.,Black=Lewis, An,Result=1-0,ECO=E90,WhiteElo=2532,BlackElo=2269,PlyCount=84,EventDate=2016.06.26,'.
   'd2d4,g8f6,c2c4,g7g6,b1c3,f8g7,e2e4,d7d6,g1f3,e8g8,h2h3,e7e5,d4d5,b8a6,c1e3,f6h5,f3h2,d8e8,f1e2,h5f4,e2f3,f7f5,[...],1-0,',
   'Game 3 ok.');
is (@$err, 0, 'No error');

($res, $err) = read_game(*DATA, $visitor);
is($res, '*,', 'Game 4 ok.');
like($err->[0], qr(Illegal san: Ng3 in rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1), 'Error: Illegal move caught.');

($res, $err) = read_game(*DATA, $visitor);
is($res, 'e2e4,*,', 'Game 5 ok.');
is(@$err, 0, 'No error: Invalid content was simply skipped.');

($res, $err) = read_game(*DATA, $visitor);
is($res, '*,', 'Game 6 ok.');
like($err->[0], qr(Illegal san: Ng3 in rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1), 'Error: (1) Illegal move caught.');
like($err->[1], qr(Illegal san \(short castling\) for O-O in rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1), 'Error: (2) Illegal move caught.');

($res, $err) = read_game(*DATA, $visitor);
is($res,
   'Event=CCRL 40/4,Site=CCRL,Date=2006.05.24,Round=1,White=Aristarch 4.50,Black=Chess Tiger 15,Result=1/2-1/2,'.
   'g1f3,c7c5,e2e4,d7d6,d2d4,c5d4,f3d4,g8f6,b1c3,e7e6,c1e3,a7a6,g2g4,h7h6,d1f3,b8d7,f1e2,d8c7'.
   ',f3h3,d6d5,e4d5,f8b4,e3d2,c7b6,d5e6,b6d4,e6d7,c8d7,e1c1,d4b6,d2e3,b4c5,h3g3,c5e3,f2e3,e8g8'.
   ',g4g5,h6g5,g3g5,f8e8,d1d3,f6h7,c3d5,h7g5,d5b6,d7c6,h1g1,g5h3,g1g3,h3f2,b6a8,f2d3,c2d3,e8a8'.
   ',g3g5,g7g6,g5c5,g8g7,h2h4,a8h8,h4h5,f7f5,d3d4,g6h5,d4d5,c6e8,c5c7,e8f7,d5d6,g7f6,d6d7,h8d8'.
   ',c7b7,f6e7,e2a6,f7d5,b7b6,d8d7,a6e2,d7c7,c1d2,d5a2,b6h6,c7d7,d2e1,a2b3,h6h7,e7e6,h7d7,e6d7'.
   ',e2h5,d7e6,h5d1,b3a2,e1f2,e6e5,f2f3,a2f7,d1c2,f7d5,f3g3,d5c4,c2b1,c4d5,b1d3,d5b3,d3b5,e5e4'.
   ',g3f2,f5f4,b5c6,e4e5,e3e4,1/2-1/2,',
   'Game 7 ok.');  
is (@$err, 0, 'No error.');

($res, $err) = read_game(*DATA, $visitor);
is(@$err, 0, 'No error: Invalid content was simply skipped.');
is($res,
   'Event=,Site=,Date=????.??.??,Round=,White=,Black=,Result=*,'.
   'FEN=r1bq1rk1/2p1bppp/p1np1n2/1p2p3/4P3/1BP2N1P/PP1P1PP1/RNBQR1K1 b - - 0 9'.
   ',c6b8,d2d4,b8d7,b1d2,c8b7,b3c2,f8e8,a2a4,*,',
   'Game 8 ok.');

($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res,
   'Event=,Site=,Date=????.??.??,Round=,White=,Black=,Result=*,d2d4,d7d5,c2c4,e7e6,b1c3,'.
   '(,g1f3,g8f6,g2g3,f8e7,(,f8b4,c1d2,(,b1c3,e8g8,f1g2,d5c4,),(,b1d2,d5c4,d1a4,b8c6,),b4e7,f1g2,'.
   'e8g8,e1g1,b8d7,),f1g2,e8g8,e1g1,d5c4,d1c2,a7a6,c2c4,b7b5,c4c2,c8b7,c1g5,),g8f6,(,f8e7,g1f3,'.
   '(,c4d5,e6d5,c1f4,g8f6,e2e3,e8g8,),g8f6,c1g5,e8g8,e2e3,b8d7,),(,c7c6,e2e4,d5e4,c3e4,f8b4,c1d2,d8d4,d2b4,d4e4,f1e2,),'.
   '(,c7c5,c4d5,e6d5,g1f3,b8c6,g2g3,g8f6,f1g2,f8e7,e1g1,e8g8,),c4d5,(,c1g5,f8e7,(,b8d7,e2e3,c7c6,g1f3,d8a5,c4d5,'.
   '(,f3d2,d5c4,g5f6,d7f6,d2c4,a5c7,),f6d5,),(,c7c6,g1f3,h7h6,g5h4,d5c4,e2e4,g7g5,h4g3,b7b5,),e2e3,e8g8,),'.
   '(,g1f3,f8e7,(,c7c5,c4d5,f6d5,e2e4,d5c3,b2c3,c5d4,c3d4,f8b4,c1d2,b4d2,d1d2,e8g8,),c1f4,e8g8,e2e3,c7c5,),'.
   'e6d5,(,f6d5,e2e4,d5c3,b2c3,c7c5,),c1g5,b8d7,e2e3,f8e7,f1d3,e8g8,g1e2,c7c6,d1c2,*,',
   'Game 9 ok.');

($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res,
   "e2e4,e7e5,g1f3,g8f6,f3e5,d7d6,e5f3,f6e4,d1e2,d8e7,d2d3,e4f6,c1g5,[Looks like a boring line.\nBut maybe ".
   "its reputation is due to being played in a lot of peaceful drawn\ngames?\n{From the World Champions, ".
   "Lasker and Spassky have played the line],*,",
   'Game 10 ok.');

# Games with strange headers...

($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res, 'e2e4,*,', 'Game 11 ok.');

($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res, 'e2e4,*,', 'Game 12 ok.');

($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res, 'Event="WC,e2e4,*,', 'Game 13 ok.');

($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res, 'e2e4,*,', 'Game 14 ok.');

($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res, 'White=[[,Black=]],c2c4,c7c5,*,', 'Game 15 ok.');

# ... end of games with strange headers


$visitor->skip_game(1);
($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res, '', 'Game 16 skipped.');
$visitor->skip_game(0);


$visitor->skip_moves(1);
($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res,
   'Event=World Senior Teams +50,Site=Radebeul GER,Date=2016.07.03,'.
   'White=Anastasian, A.,Black=Lewis, An,Result=1-0,',
   'Game 17 - moves skipped.');
$visitor->skip_moves(0);


($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res, 'f2f4,[♖ ♜ ♘ ♞],d7d5,g1f3,*,', 'Game 18 ok.');

($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res, 'f2f4,[På Øen køber jeg Æg. Zoltán & Sólrún.],d7d5,g1f3,*,', 'Game 18 ok.');


# strange result tag value
($res, $err) = read_game(*DATA, $visitor);
is (@$err, 0, 'No error');
is($res,
   "White=Baraeva,I,Black=Isaev,Y,Result=1-0 ff,WhiteTitle=WF,BlackTitle=FM,WhiteElo=2159,BlackElo=2238,".
   "ECO=A40,Opening=Queen's pawn,WhiteFideId=24142565,BlackFideId=4173350,EventDate=2013.01.15,d2d4,1-0,",
   'Game 19 read ok anyway.');


# invalid move at the end
($res, $err) = read_game(*DATA, $visitor);
is (@$err, 1, 'One error');
like(${$err}[0], qr(Illegal san: b1 in 8/6qk/8/5KPp/1Q3p2/4P1P1/1p6/8 b - - 1 69), 'Illegal move b1 reported correctly');
is($res,
   "Event=6th Mayors Cup 2013,Site=Mumbai IND,Date=2013.06.05,Round=10,White=Swathi,G,Black=Neelotpal,D,".
   "Result=0-1,WhiteTitle=WGM,BlackTitle=GM,WhiteElo=2260,BlackElo=2461,ECO=C55,Opening=Two knights defence (Modern bishop's opening),".
   "WhiteFideId=5003474,BlackFideId=5003512,EventDate=2013.05.29,".
   "e2e4,e7e5,g1f3,b8c6,f1c4,g8f6,d2d3,f8e7,c4b3,e8g8,b1d2,d7d6,c2c3,c6a5,b3c2,c7c5,e1g1,a5c6,f1e1,f8e8,d2f1,h7h6,".
   "f1g3,e7f8,h2h3,d8c7,f3h2,c8e6,d1f3,f6h7,g3f5,a8d8,h2g4,d6d5,c2a4,g8h8,h3h4,d5e4,d3e4,f7f6,g4e3,c7f7,f3e2,g7g6,".
   "f5g3,h6h5,b2b3,f7c7,c1b2,f8h6,a1d1,d8d1,e1d1,e8d8,g3f1,d8d1,e2d1,a7a6,e3d5,c7d8,c3c4,c6d4,b3b4,h6f8,b4c5,f8c5,".
   "f1e3,b7b5,c4b5,a6b5,a4c2,d4c2,e3c2,h8g7,d1d3,e6d5,e4d5,d8b6,c2e3,h7f8,b2c1,f6f5,e3d1,f8d7,d3d2,d7f6,c1b2,c5d4,".
   "g1f1,f6d5,g2g3,b5b4,b2d4,b6d4,f1e1,d4c4,d1e3,d5e3,d2e3,e5e4,e3b6,c4c3,e1e2,c3d3,e2e1,d3b1,e1e2,b1a2,e2e3,a2b3,".
   "e3f4,b3f3,f4e5,f3c3,e5d5,b4b3,b6b7,g7h6,b7b8,b3b2,d5e6,h6h7,b8b7,c3g7,b7b5,g7g8,e6f6,g8f8,f6e6,f8g7,b5b4,g6g5,".
   "h4g5,e4e3,f2e3,f5f4,e6f5,0-1,",
   'Game 20 - read all moves up to the last invalid move.');



# detect the end of the input
($res, $err) = read_game(*DATA, $visitor);
is($res, undef, 'Read undef when no more input');
is(@$err, 0, 'No error when no more input');



close DATA;



done_testing;


package TestVisitor;

sub new {
    my ($class) = @_;
    my $visitor = {};
    $visitor->{result} = '';
    $visitor->{debug} = 0;
    $visitor->{skip_game} = 0;
    $visitor->{skip_moves} = 0;
    return bless $visitor, $class;
}

sub debug {
    my ($visitor, $debug) = @_;
    $visitor->{debug} = $debug;
}

sub skip_game {
    my ($visitor, $skip) = @_;
    $visitor->{skip_game} = $skip;
}

sub skip_moves {
    my ($visitor, $skip) = @_;
    $visitor->{skip_moves} = $skip;
}

sub begin_game {
    my $visitor = shift;
    # clean up from previous game
    $visitor->{result} = '';
    # 0 -> read game
    # 1 -> skip game
    return $visitor->{skip_game};
}

sub end_game {
    # nop
}

sub result {
    my $visitor = shift;
    $visitor->{result};
}

sub visit_header {
    my ($visitor, $tag, $name) = @_;
    $visitor->{result} = ($visitor->{result}.$tag.'='.$name.',');  
}

sub end_headers {
    # 0 -> read movetext
    # 1 -> skip movetext
    return $visitor->{skip_moves};
}

sub begin_parse_san {
    1;
}

sub visit_move {
    my ($visitor, $board, $move) = @_;
    say "visit_move - got a board:\n$board" if $visitor->debug();
    say "visit_move - got a move: $move"    if $visitor->debug();
    if (defined ($move)) {
        $visitor->{result} = $visitor->{result}.$move.',';
    } else {
        # null move
        $visitor->{result} = $visitor->{result}.'--,';
    }
}

sub begin_variation {
    my $visitor = shift;
    $visitor->{result} .= '(,';
}

sub end_variation {
    my $visitor = shift;
    $visitor->{result} .= '),';
}

sub visit_nag {
    my ($visitor, $nag) = @_;
    $visitor->{result} .= $nag.',';
}

sub visit_comment {
    my ($visitor, $comment) = @_;
    $visitor->{result} .= "[$comment]".',';
}

sub visit_result {
    my ($visitor, $result) = @_;
    $visitor->{result} .= $result.',';
}

sub visit_board {
    # nop
}



# back to main for the DATA section
package main;


__DATA__

1. e4 e5! 2. Nf3? Nc6!? 3.Ba6?? bxa6!! 4. a3?! a5 $1 5. O-O --
*

1. d4 d5 { QGD. } 2.c4 e6 3.Nc3 Nf6
;
4. cxd5 exd5 5. Bg5 ( 5. Nf3 )
1-0

[Event "World Senior Teams +50"]
[Site "Radebeul GER"]
[Date "2016.07.03"]
[Round "8.2"]
[White "Anastasian, A."]
[Black "Lewis, An"]
[Result "1-0"]
[ECO "E90"]
[WhiteElo "2532"]
[BlackElo "2269"]
[PlyCount "84"]
[EventDate "2016.06.26"]

1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. h3 e5 7. d5 Na6 8. Be3 Nh5
; A PGN comment here.
; and here ;
9. Nh2 Qe8 10. Be2 Nf4 11. Bf3 f5 { ... } 1-0

; Illegal move
1. Ng3 *

; Invalid SAN syntax
1. xxx e4 *

; Multiple illegal moves
1. Ng3 O-O *

[Event "CCRL 40/4"]
[Site "CCRL"]
[Date "2006.05.24"]
[Round "1"]
[White "Aristarch 4.50"]
[Black "Chess Tiger 15"]
[Result "1/2-1/2"]

g1f3 c7c5 e2e4 d7d6 d2d4 c5d4 f3d4 g8f6 b1c3 e7e6 c1e3 a7a6 g2g4 h7h6 d1f3 b8d7 f1e2 d8c7
f3h3 d6d5 e4d5 f8b4 e3d2 c7b6 d5e6 b6d4 e6d7 c8d7 e1c1 d4b6 d2e3 b4c5 h3g3 c5e3 f2e3 e8g8
g4g5 h6g5 g3g5 f8e8 d1d3 f6h7 c3d5 h7g5 d5b6 d7c6 h1g1 g5h3 g1g3 h3f2 b6a8 f2d3 c2d3 e8a8
g3g5 g7g6 g5c5 g8g7 h2h4 a8h8 h4h5 f7f5 d3d4 g6h5 d4d5 c6e8 c5c7 e8f7 d5d6 g7f6 d6d7 h8d8
c7b7 f6e7 e2a6 f7d5 b7b6 d8d7 a6e2 d7c7 c1d2 d5a2 b6h6 c7d7 d2e1 a2b3 h6h7 e7e6 h7d7 e6d7
e2h5 d7e6 h5d1 b3a2 e1f2 e6e5 f2f3 a2f7 d1c2 f7d5 f3g3 d5c4 c2b1 c4d5 b1d3 d5b3 d3b5 e5e4
g3f2 f5f4 b5c6 e4e5 e3e4
1/2-1/2 

[Event ""]
[Site ""]
[Date "????.??.??"]
[Round ""]
[White ""]
[Black ""]
[Result "*"]
[FEN "r1bq1rk1/2p1bppp/p1np1n2/1p2p3/4P3/1BP2N1P/PP1P1PP1/RNBQR1K1 b - - 0 9"]

9...Nb8 10.d4 Nbd7 11.Nbd2 Bb7 12.Bc2 Re8 13.a4 *

[Event ""]
[Site ""]
[Date "????.??.??"]
[Round ""]
[White ""]
[Black ""]
[Result "*"]

1.d4 d5 2.c4 e6 3.Nc3 ( 3.Nf3 Nf6 4.g3 Be7 ( 4...Bb4+ 5.Bd2 ( 5.Nc3 O-O 6.
Bg2 dxc4 ) ( 5.Nbd2 dxc4 6.Qa4+ Nc6 ) 5...Be7 6.Bg2 O-O 7.O-O Nbd7 ) 5.Bg2
O-O 6.O-O dxc4 7.Qc2 a6 8.Qxc4 b5 9.Qc2 Bb7 10.Bg5 ) 3...Nf6 ( 3...Be7 4.
Nf3 ( 4.cxd5 exd5 5.Bf4 Nf6 6.e3 O-O ) 4...Nf6 5.Bg5 O-O 6.e3 Nbd7 ) ( 
3...c6 4.e4 dxe4 5.Nxe4 Bb4+ 6.Bd2 Qxd4 7.Bxb4 Qxe4+ 8.Be2 ) ( 3...c5 4.
cxd5 exd5 5.Nf3 Nc6 6.g3 Nf6 7.Bg2 Be7 8.O-O O-O ) 4.cxd5 ( 4.Bg5 Be7 ( 
4...Nbd7 5.e3 c6 6.Nf3 Qa5 7.cxd5 ( 7.Nd2 dxc4 8.Bxf6 Nxf6 9.Nxc4 Qc7 ) 
7...Nxd5 ) ( 4...c6 5.Nf3 h6 6.Bh4 dxc4 7.e4 g5 8.Bg3 b5 ) 5.e3 O-O ) ( 4.
Nf3 Be7 ( 4...c5 5.cxd5 Nxd5 6.e4 Nxc3 7.bxc3 cxd4 8.cxd4 Bb4+ 9.Bd2 Bxd2+
10.Qxd2 O-O ) 5.Bf4 O-O 6.e3 c5 ) 4...exd5 ( 4...Nxd5 5.e4 Nxc3 6.bxc3 c5 
) 5.Bg5 Nbd7 6.e3 Be7 7.Bd3 O-O 8.Nge2 c6 9.Qc2 *


1.e4 e5 2.Nf3 Nf6 3.Nxe5 d6 4.Nf3 Nxe4 5.Qe2 Qe7 6.d3 Nf6 7.Bg5 {Looks 
like a boring line.
But maybe its reputation is due to being played in a lot of peaceful drawn
games?
{From the World Champions, Lasker and Spassky have played the line}} *


; Now some examples of invalid/unusual header syntax
[Event ""

1.e4 *

[Event '']

1.e4 *

[Event ""WC"]

1.e4 *

Date]
1.e4 *

[]
[[]]
[White "[["]
[Black "]]"]

1.c4 c5 *

; END examples of invalid/unusual header syntax

[Event "World Senior Teams +50"]
[Site "Radebeul GER"]
[Date "2016.07.03"]
[White "Anastasian, A."]
[Black "Lewis, An"]
[Result "1-0"]

1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. h3 e5 7. d5 Na6 8. Be3 Nh5
9. Nh2 Qe8 10. Be2 Nf4 11. Bf3 f5 *

[Event "World Senior Teams +50"]
[Site "Radebeul GER"]
[Date "2016.07.03"]
[White "Anastasian, A."]
[Black "Lewis, An"]
[Result "1-0"]

1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. h3 e5 7. d5 Na6 8. Be3 Nh5
9. Nh2 Qe8 10. Be2 Nf4 11. Bf3 f5 *

; comments with strange characters
;
1. f4 { ♖ ♜ ♘ ♞ } d5 2. Nf3 *

1. f4 { På Øen køber jeg Æg. Zoltán & Sólrún. } d5 2. Nf3 *

[White "Baraeva,I"]
[Black "Isaev,Y"]
[Result "1-0 ff"]
[WhiteTitle "WF"]
[BlackTitle "FM"]
[WhiteElo "2159"]
[BlackElo "2238"]
[ECO "A40"]
[Opening "Queen's pawn"]
[WhiteFideId "24142565"]
[BlackFideId "4173350"]
[EventDate "2013.01.15"]

1. d4 1-0 ff

; Last move 69...b1 is invalid
; ensure that the game is read in up to that point
[Event "6th Mayors Cup 2013"]
[Site "Mumbai IND"]
[Date "2013.06.05"]
[Round "10"]
[White "Swathi,G"]
[Black "Neelotpal,D"]
[Result "0-1"]
[WhiteTitle "WGM"]
[BlackTitle "GM"]
[WhiteElo "2260"]
[BlackElo "2461"]
[ECO "C55"]
[Opening "Two knights defence (Modern bishop's opening)"]
[WhiteFideId "5003474"]
[BlackFideId "5003512"]
[EventDate "2013.05.29"]

1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. d3 Be7 5. Bb3 O-O 6. Nbd2 d6 7. c3 Na5 8. Bc2
c5 9. O-O Nc6 10. Re1 Re8 11. Nf1 h6 12. Ng3 Bf8 13. h3 Qc7 14. Nh2 Be6 15. Qf3
Nh7 16. Nf5 Rad8 17. Ng4 d5 18. Ba4 Kh8 19. h4 dxe4 20. dxe4 f6 21. Nge3 Qf7 22.
Qe2 g6 23. Ng3 h5 24. b3 Qc7 25. Bb2 Bh6 26. Rad1 Rxd1 27. Rxd1 Rd8 28. Ngf1
Rxd1 29. Qxd1 a6 30. Nd5 Qd8 31. c4 Nd4 32. b4 Bf8 33. bxc5 Bxc5 34. Nfe3 b5 35.
cxb5 axb5 36. Bc2 Nxc2 37. Nxc2 Kg7 38. Qd3 Bxd5 39. exd5 Qb6 40. Ne3 Nf8 41.
Bc1 f5 42. Nd1 Nd7 43. Qd2 Nf6 44. Bb2 Bd4 45. Kf1 Nxd5 46. g3 b4 47. Bxd4 Qxd4
48. Ke1 Qc4 49. Ne3 Nxe3 50. Qxe3 e4 51. Qb6 Qc3+ 52. Ke2 Qd3+ 53. Ke1 Qb1+ 54.
Ke2 Qxa2+ 55. Ke3 Qb3+ 56. Kf4 Qf3+ 57. Ke5 Qc3+ 58. Kd5 b3 59. Qb7+ Kh6 60. Qb8
b2 61. Ke6 Kh7 62. Qb7+ Qg7 63. Qb5 Qg8+ 64. Kf6 Qf8+ 65. Ke6 Qg7 66. Qb4 g5 67.
hxg5 e3 68. fxe3 f4 69. Kf5 b1 0-1
