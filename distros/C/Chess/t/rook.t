use Test::Simple tests => 4;

use Chess::Piece::Rook;

$rook = Chess::Piece::Rook->new("a1", "white", "White King's rook");
ok( $rook );
ok( $rook->can_reach("a8") == 1 );
ok( $rook->can_reach("h1") == 1 );
ok( $rook->can_reach("d4") == 0 );
