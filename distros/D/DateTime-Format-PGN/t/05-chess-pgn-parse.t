#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;

require_ok( 'Chess::PGN::Parse' );
require_ok( 'DateTime::Format::PGN' );

my $text = '[Event "Moscow"]
[Site "Moscow"]
[Date "1925.??.??"]
[Round "?"]
[White "Lasker, Emanuel"]
[Black "Spielmann, Rudolf"]
[Result "1-0"]
[ECO "D43"]
[PlyCount "85"]
[EventDate "1925.11.10"]
[EventType "tourn"]
[EventRounds "21"]
[EventCountry "URS"]
[Source "ChessBase"]
[SourceDate "1999.07.01"]

1. c4 e6 2. d4 d5 3. Nf3 Nf6 4. Bg5 h6 5. Bxf6 Qxf6 6. Nc3 c6 7. e3 Nd7 8. Bd3
Bb4 9. O-O Bxc3 10. bxc3 dxc4 11. Bxc4 e5 12. dxe5 Nxe5 13. Nxe5 Qxe5 14. Qd4
Qxd4 15. exd4 Be6 16. Rfe1 Kd7 17. Bxe6+ fxe6 18. Re5 Rhf8 19. Rae1 Rae8 20. f3
Rf5 21. Kf2 Rxe5 22. Rxe5 b5 23. Ke3 Rb8 24. h4 Rb6 25. a4 a5 26. Kd3 Rb8 27.
Kc2 Rb7 28. c4 bxa4 29. Rxa5 Rb4 30. Kd3 Kc7 31. c5 Kb7 32. Ke4 h5 33. g4 hxg4
34. fxg4 g6 35. Ke5 Rc4 36. h5 gxh5 37. gxh5 Rc1 38. Rxa4 Rh1 39. Kd6 Rxh5 40.
Rb4+ Kc8 41. Kxc6 Rd5 42. Ra4 Kb8 43. Kb6 1-0

';

my $pgn = new Chess::PGN::Parse undef, $text; 
$pgn->read_game();
my $hash_ref = $pgn->tags();

my $dtf = DateTime::Format::PGN->new({use_incomplete => 1});
my $dt = $dtf->parse_datetime($pgn->date());
is($dtf->format_datetime($dt),"1925.??.??", "Lasker - Spielmann (Moscow 1925) 1-0 [Date]");

$dt = $dtf->parse_datetime(${$hash_ref}{EventDate});
is($dtf->format_datetime($dt),"1925.11.10", "Lasker - Spielmann (Moscow 1925) 1-0 [EventDate]");

$dt = $dtf->parse_datetime(${$hash_ref}{SourceDate});
is($dtf->format_datetime($dt),"1999.07.01", "Lasker - Spielmann (Moscow 1925) 1-0 [SourceDate]");
