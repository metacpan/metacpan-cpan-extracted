#!/usr/bin/perl
# 05_list-str.t - test epdlist and epdstr
#
use strict;
use warnings;
use diagnostics;
use Chess::PGN::EPD qw( epdlist epdcode );
use Chess::PGN::Parse;
use Test::More tests => 2;

ok(1);    # load failure check...

my $text = 
    "[Event \"ICC 2 12 u\"]\n" .
    "[Site \"Internet Chess Club\"]\n" .
    "[Date \"2003.03.31\"]\n" .
    "[Round \"-\"]\n" .
    "[White \"hsmyers\"]\n" .
    "[Black \"guest2023\"]\n" .
    "[Result \"1-0\"]\n" .
    "[ICCResult \"Black resigns\"]\n" .
    "[WhiteElo \"1492\"]\n" .
    "[Opening \"KGA: Fischer defense\"]\n" .
    "[ECO \"C30\"]\n" .
    "[NIC \"KG.05\"]\n" .
    "[Time \"14:36:59\"]\n" .
    "[TimeControl \"120+12\"]\n" .
    "\n" .
    "1. e4 e5 2. f4 d6 3. Nf3 exf4 4. Be2 g5 5. O-O Bg4 6. d4 Nc6 7. c3 Qf6 8.\n" .
    "Bb5 Ne7 9. d5 a6 10. dxc6 axb5 11. cxb7 Rb8 12. Qb3 Rxb7 13. a4 Bg7 14. axb5\n" .
    "O-O 15. Na3 Rfb8 16. c4 c6 17. Qc2 cxb5 18. cxb5 Rc8 19. Qd2 Bxf3 20. Rxf3\n" .
    "Qd4+ 21. Qxd4 Bxd4+ 22. Kh1 Re8 23. Rd3 Be5 24. Rb1 g4 25. Bd2 g3 26. hxg3\n" .
    "fxg3 27. Bc3 Bf4 28. Rf3 Ng6 29. Re1 Rbe7 30. b6 Rxe4 31. Rxe4 Rxe4 32. b7\n" .
    "d5 33. Rxf4 Nxf4 34. b8=Q+ {Black resigns} 1-0\n" ;
my $answer =
    "[ECO,\"C34\"]\n" .
    "[NIC,\"KP 10\"]\n" .
    "[Opening,\"KGA: Fischer defense\"]";

is(check_both($text),$answer,'Check both epdlist and epdcode');

sub check_both {
    my $text = shift;
    my @epd;
    my @results;
    my $pgn = new Chess::PGN::Parse undef, $text;

    while ( $pgn->read_game() ) {
        $pgn->parse_game();
        @epd = reverse epdlist( @{ $pgn->moves() } );
        push(@results, '[ECO,"' . epdcode( 'ECO',     \@epd ) . "\"]");
        push(@results, '[NIC,"' . epdcode( 'NIC',     \@epd ) . "\"]");
        push(@results, '[Opening,"' . epdcode( 'Opening', \@epd ) . "\"]");
    }
    return join("\n",@results);
}
