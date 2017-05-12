#!perl -T

use Test::More qw(no_plan);

BEGIN {
    use_ok('Chess::PGN::Parse::FileHandle');
}

*fh = DATA;

my $pgn = Chess::PGN::Parse::FileHandle->new(*fh);

isa_ok($pgn, 'Chess::PGN::Parse');
isa_ok($pgn, 'Chess::PGN::Parse::FileHandle');

$pgn->read_game();

is($pgn->black(), 'Shirov,A', 'Check $pgn->black() from the filehandle');

__DATA__
[Event "Blitz Match"]
[Site "Prague CZE"]
[Date "2005.11.04"]
[Round "1"]
[White "Navara,D"]
[Black "Shirov,A"]
[Result "0-1"]
[WhiteElo "2646"]
[BlackElo "2710"]
[EventDate "2005.11.04"]
[ECO "D17"]

1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. Nf3 dxc4 5. a4 Bf5 6. Ne5 e6 7. f3 Bb4 8.
e4 Bxe4 9. fxe4 Nxe4 10. Bd2 Qxd4 11. Nxe4 Qxe4+ 12. Qe2 Bxd2+ 13. Kxd2
Qd5+ 14. Kc2 Na6 15. Nxc4 O-O 16. Rd1 Qf5+ 17. Kc1 Nb4 18. b3 Rfd8 19. g3
Qf6 20. Ne5 Qg5+ 21. Rd2 Na2+ 22. Kc2 Rxd2+ 23. Qxd2 Qxe5 24. Bg2 a5 25.
Re1 Qc5+ 26. Kb2 Nb4 27. Be4 g6 28. h4 Qe5+ 29. Ka3 Qxg3 30. h5 Nd5 31.
hxg6 hxg6 0-1

