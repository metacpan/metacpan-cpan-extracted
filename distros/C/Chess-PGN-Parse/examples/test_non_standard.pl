#!/usr/bin/perl -w
use strict;
use Chess::PGN::Parse;

my $out ='';

{
    local $/ =undef;
    $out = <DATA>;
}

my $pgn = new Chess::PGN::Parse(undef, $out) or die "can't \n";

use Data::Dumper;

while ($pgn->read_game()) {
    if ($pgn->parse_game(
        {   
            save_comments => 1 , 
            comments_struct => 'string' , 
            log_errors => 1
            })) 
        {
        print $pgn->standard_PGN({all_tags=>1}),"\n";
        print Data::Dumper->Dump([$pgn->{GameComments}],['comments']),"\n";
        print Data::Dumper->Dump([$pgn->{GameErrors}],['err']),"\n";
    }
}


__DATA__

; this is a comment
; also this is a comment
; this is a third comment
[DUMMY "dummy"]
; another comment
[Result "*"]

e4 e5 Nf3 Nc6 {test} Bb5 a6 $1 Ba4
; this is a comment inside a game 
Nf6 0-0 ; this comment will be kept

[Event "Idclosed20021"]
[Site "Boise"]
[Date "2002.2.16"]
[Round "1"]
[White "hsmyers"]
[Black "Chambers, Geofrey"]
[Result "1-0"]
[ECO "?"]
[WhiteElo "span ?"] [BlackElo 
"span ?"] [EventDate "span ?"]
 1.  e4 e5 2.  f4 Bc5 3.  Nf3 Nc6 4.  {test} Nc3 Qe7 5.  Nd5 Qd6 6.  d3 Nf6 7.  fxe5 Nxe5 8.  Nxf6+ Qxf6 9.  c3 Nxf3+ 10.  Qxf3 Qxf3 11.  gxf3 0-0 12.  Bd2 c6 13.  0-0-0 d5 14.  d4 Bd6 15.  e5 Bc7 16.  Rg1 f6 17.  f4 b6 18.  Bd3 c5 19.  Rde1 fxe5 20.  dxe5 g6 21.  c4 d4 22.  Be4 Rb8 23.  Bd5+ Kg7 24.  h4 Bf5 25.  Be4 h5 26.  Re2 Rbe8 27.  Bxf5 Rxf5 28.  Rg5 Rxg5 29.  hxg5 h4 30.  Rh2 Rh8 31.  Rh3 a5 32.  Be1 d3 33.  Rxh4 Rd8 34.  a4 Rd4 35.  b3 Re4 36.  Kd1 Bb8 37.  Bc3 Re2 38.  e6+ Kf8 39.  Rh8+ Ke7 40.  Rxb8 Rxe6 41.  Be5 Kd7 42.  Kd2 Re8 43.  Kxd3 Rxb8 44.  Bxb8
[Event "Idclosed20022"]
[Site "?"]
[Date "2002.2.16"]
[Round "?"]
[White "Parscns
Parsons
Parsons, Larry"]
[Black "hsmyers"]
[Result "1-0"]
[ECO "?"]
[WhiteElo "?"]
[BlackElo "?"]
[EventDate "?"]
 1.  c4 f5 2.  Nf3 Nf6 3.  d3 e6 4.  g3 d5 5.  Bg2 c6 6.  0-0 Be7 7.  a3 0-0 8.  b3 Qe8 9.  Ne5 Nfd7 10.  Nxd7 Nxd7 11.  e4 Bf6 12.  Ra2 d4 13.  b4 Rb8 14.  c5 Ne5 15.  Bf4 g5 16.  Bxe5 Bxe5 17.  exf5 Bf6 18.  fxe6 Bxe6 19.  Re2 Qf7 20.  Nd2 Rbe8 21.  Ne4 Be7 22.  f4 Qh5 23.  Bf3 Bg4 24.  Ref2 Bxf3 25.  Qxf3 g4 26.  Qd1 Qf5 27.  Re1 h5 28.  Rfe2 Red8 29.  Ng5 Bxg5 30.  R2e5 Qh7 31.  Rxg5+
[Event "Idclosed20023"]
[Site "?"]
[Date "2002.2.17"]
[Round "?"]
[White "hsmyers"]
[Black "Matanzas, Joe"]
[Result "1-0"]
[ECO "?"]
[WhiteElo "?"]
[BlackElo "?"]
[EventDate "?"]
 1.  e4 c5 2.  f4 d6 3.  Nf3 Nc6 4.  Nc3 a6 5.  Be2 e6 6.  0-0 Nf6 7.  d3 g6 8.  Qe1 b5 9.  Bd1 Bg7 10.  f5 0-0 11.  fxg6 fxg6 12.  Bg5 Qc7 13.  Rb1 b4 14.  Ne2 a5 15.  Ng3 Ba6 16.  Qd2 c4 17.  Be2 d5 18.  Bxf6 Rxf6 19.  exd5 exd5 20.  dxc4 Bxc4 21.  Bxc4 Qb6+ 22.  Kh1 dxc4 23.  Qd5+ Kh8 24.  Qxc4 Raf8 25.  c3 R6f4 26.  Qd3 Ne5 27.  Nxe5 R4xf1+ 28.  Rxf1 Rxf1+ 29.  Qxf1 Qe6 30.  Qc4 Qxc4 31.  Nxc4 bxc3 32.  bxc3 Bxc3 33.  Ne4
[Event "Idclosed20024"]
[Site "?"]
[Date "2002.2.17"]
[Round "?"]
[White "Kennedy, Shane"]
[Black "hsmyers"]
[Result "0-1"]
[ECO "?"]
[WhiteElo "?"]
[BlackElo "?"]
[EventDate "?"]
 1.  e4 d5 2.  exd5 Nf6 3.  d4 Bg4 4.  Be2 Bxe2 5.  Qxe2 Qxd5 6.  Nf3 e6 7.  0-0 Qd8 8.  c4 Be7 9.  Be3 0-0 10.  Nc3 c6 11.  Rad1 Re8 12.  Rd3 Bb4 13.  Rfd1 Bxc3 14.  bxc3 Qc7 15.  Ne5 Nbd7 16.  Bf4 Qa5 17.  Rg3 Rad8 18.  Bh6 g6 19.  Bg5 Nh5 20.  Qxh5 Nxe5 21.  Bxd8 Rxd8 22.  Qxe5 Qxe5 23.  Rgd3 Qe2 24.  h3 Qxa2
[Event "?"]
[Site "?"]
[Date "2002.2.18"]
[Round "5"]
[White "Mark, Anderson"]
[Black "hsmyers"]
[Result "0-1"]
[ECO "?"]
[WhiteElo "?"]
[BlackElo "?"]
[EventDate "?"]
 1.  Nf3 f5 2.  d4 Nf6 3.  c4 e6 4.  Nc3 d5 5.  Bg5 Be7 6.  cxd5 exd5 7.  Qb3 c6 8.  g3 0-0 9.  Bg2 Ne4 10.  Bxe7 Qxe7 11.  Ne5 Nd7 12.  Nxd7 Qxd7 13.  Bxe4 fxe4 14.  e3 Qf7 15.  Qc2 Bg4 16.  h3 Bf3 17.  Rh2 Qe6 18.  b4 b6 19.  Rc1 Rac8 20.  Qa4 Qf7 21.  a3 Qb7 22.  Rc2 a6 23.  Qb3 Rfd8 24.  Nb1 c5 25.  bxc5 b5 26.  Nd2 Bh5 27.  Rb2 Bf7 28.  Nb1 Rcb8 29.  Nc3 Qc6 30.  Kd2 g6 31.  Rh1 Qf6 32.  Ke1 Qc6 33.  Rh2 Kg7 34.  Na2 a5 35.  Nc3 b4 36.  axb4 Rxb4 37.  Qc2 Rdb8 38.  Rxb4 axb4 39.  Nb1 Be8 40.  Nd2 Qa4 41.  Nb3 Bb5 42.  Kd2 Bc4 43.  Nc1 Qa3 44.  Rh1 b3 45.  Qc3 Qa4 46.  Nxb3 Rxb3 47.  Ra1 Qb5 48.  Ra7+ Kh6 49.  Qa1 Qb4+ 50.  Kc1 Qe1+ 51.  Kc2 Qxf2+ 52.  Kc1 Qxe3+ 53.  Kc2 Qd3+ 54.  Kc1 Rc3+ 55.  Kb2 Qd2+ 56.  Kb1 Rc1+
[Event "?"]
[Site "?"]
[Date "2002.2.18"]
[Round "6"]
[White "hsmyers"]
[Black "Gold, Mark"]
[Result "0-1"]
[ECO "?"]
[WhiteElo "?"]
[BlackElo "?"]
[EventDate "?"]
 1.  e4 c5 2.  f4 e6 3.  Nf3 Nc6 4.  Bb5 Nd4 5.  Nxd4 cxd4 6.  Be2 Bc5 7.  d3 d5 8.  e5 Ne7 9.  0-0 Bd7 10.  Nd2 Qc7 11.  Nb3 Bb6 12.  Bd2 a5 13.  Rc1 a4 14.  Na1 a3 15.  b3 Nc6 16.  Kh1 0-0 17.  Qe1 Rfc8 18.  Qg3 Ba5 19.  c3 dxc3 20.  Bxc3 Bxc3 21.  Rxc3 Qa5 22.  Rfc1 Nd4 23.  R3xc8+ Rxc8 24.  Rxc8+ Bxc8



1. d4 d5 2. c4 dxc4 3. e3 e6 4. Nf3 a6 5. Bxc4 c5 6. O-O Nf6 7. dxc5 Qxd1 8.
Rxd1 Bxc5 9. Be2 O-O 10. Nbd2 Rd8 11. Ne5 Be7 12. b3 Nd5 13. Bb2 f6 14. Nd3 Nc6
15. e4 Nb6 16. e5 f5 17. Rac1 Bd7 18. Nf3 1/2-1/2

[Event "Botvinnik Memorial Classical"]
[Site "Moscow"]
[Date "2001.12.02"]
[Round "1.2"]
[White "Kasparov, Garry"]
[Black "Kramnik, Vladimir"]
[Result "1/2-1/2"]
[ECO "B40"]
[WhiteElo "2838"]
[BlackElo "2809"]
[PlyCount "143"]
[EventDate "2001.??.??"]
1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 a6 5. c4 Nf6 6. Nc3 Qc7 7. a3 d6 8. Be3
b6 9. Rc1 Nbd7 10. Be2 Bb7 11. f3 Be7 12. O-O O-O 13. Kh1 Rac8 14. b4 Qb8 15.
Qd2 Bd8 16. Rc2 Re8 17. Na4 Bc7 18. Bg1 Rcd8 19. Rb1 Ba8 20. Qc1 h6 21. Nb2 Nf8
22. Nd3 Ng6 23. a4 Qc8 24. b5 a5 25. Nc6 Bxc6 26. bxc6 e5 27. Bxb6 Ne7 28. c5
d5 29. Bxc7 Qxc7 30. Rb7 Qxc6 31. Rb5 Ng6 32. exd5 Nxd5 33. Nf2 Ngf4 34. Bf1
Ne6 35. Rxa5 Qc7 36. Rb5 Nd4 37. Rc4 Nxb5 38. axb5 Rb8 39. b6 Nxb6 40. cxb6
Qxb6 41. Qe1 Rec8 42. Rxc8+ Rxc8 43. Ng4 Re8 44. Bd3 Qd4 45. Be4 f5 46. Bxf5
Ra8 47. Bb1 Qb2 48. h4 Ra1 49. Kh2 Qxb1 50. Qxe5 Qh1+ 51. Kg3 Qe1+ 52. Qxe1
Rxe1 53. Kf4 Re2 54. Ne3 g6 55. g4 Kf7 56. h5 g5+ 57. Ke4 Ke6 58. f4 Rf2 59.
Nd5 gxf4 60. Nxf4+ Kf6 61. Ke3 Ra2 62. Nd3 Ra3 63. Ke4 Ra1 64. Kf4 Ra4+ 65. Kf3
Ra3 66. Ke4 Rb3 67. Nc5 Rb4+ 68. Kf3 Rb5 69. Ne4+ Ke5 70. g5 Rb4 71. Nf2 Rf4+
72. Kg3 1/2-1/2

1. d4 d5 2. c4 dxc4 3. e3 e6 4. Nf3 a6 5. Bxc4 c5 6. O-O Nf6 7. dxc5 Qxd1 8.
Rxd1 Bxc5 9. Be2 O-O 10. Nbd2 Rd8 11. Ne5 Be7 12. b3 Nd5 13. Bb2 f6 14. Nd3 Nc6
15. e4 Nb6 16. e5 f5 17. Rac1 Bd7 18. Nf3 1/2-1/2


[Event "Botvinnik Memorial"]
[Site "Moscow"]
[Date "2001.12.05"]
[Round "4"]
[White "Kasparov, Garry"]
[Black "Kramnik, Vladimir"]
[Result "1/2-1/2"]
[ECO "C80"]
[WhiteElo "2839"]
[BlackElo "2808"]
[PlyCount "37"]
[EventDate "2001.12.01"]

1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 $1 {first comment} 4. Ba4 Nf6 5. O-O 
Nxe4 {second comment} 6. d4 ; comment starting with ";" up to EOL 
b5 7. Bb3 d5 8. dxe5 Be6 9. Be3 {third comment} 9... Bc5 10. Qd3 O-O 
11. Nc3 Nb4 (11... Bxe3 12. Qxe3 Nxc3 13. Qxc3 Qd7 14. Rad1 Nd8 $1 
15. Nd4 c6 $14 (15... Nb7 16. Qc6 $1 $16)) 12. Qe2 Nxc3 13. bxc3 Bxe3 
% escaped line - it will be discarded up to the EOL
14. Qxe3 Nc6 {wrong } comment} 15. a4 Na5 oh? 16. axb5 {yet another 
comment} (16. Nd4 {nested comment}) 16... axb5 17. Nd4 (17. Qc5 c6 18. 
Nd4 Ra6 19. f4 g6 20. Ra3 Qd7 21. Rfa1 Rfa8) 17... Qe8 18. f4 c5 19. 
Nxe6 the end 1/2-1/2

[Event "Botvinnik Memorial Classical"]
[Site "Moscow"]
[Date "2001.12.05"]
[Round "1.4"]
[White "Kasparov, Garry"]
[Black "Kramnik, Vladimir"]
[Result "1/2-1/2"]
[ECO "C80"]
[WhiteElo "2839"]
[BlackElo "2808"]
[PlyCount "37"]
[EventDate "2001.??.??"]
[SentinelTag "LASTGAME"]
1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Nxe4 6. d4 b5 7. Bb3 d5 8. dxe5
Be6 9. Be3 Bc5 10. Qd3 O-O 11. Nc3 Nb4 12. Qe2 Nxc3 13. bxc3 Bxe3 14. Qxe3 Nc6
15. a4 Na5 16. axb5 axb5 17. Nd4 Qe8 18. f4 c5 19. Nxe6 1/2-1/2

