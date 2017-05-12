use Test::Simple tests => 14;

use Chess::Piece::Pawn;
use Chess::Piece::Queen;

$pawn = Chess::Piece::Pawn->new("e2", "white", "White King's pawn");
ok( $pawn );
ok( $pawn->can_reach("e3") == 1 );
ok( $pawn->can_reach("e4") == 1 );
ok( $pawn->can_reach("e5") == 0 );
$pawn->set_moved(1);
ok( $pawn->can_reach("e4") == 0 );
ok( $pawn->can_reach("d3") == 1 );
ok( $pawn->can_reach("f3") == 1 );
$pawn = Chess::Piece::Pawn->new("e7", "black", "Black King's pawn");
ok( $pawn->can_reach("e6") == 1 );
ok( $pawn->can_reach("e5") == 1 );
ok( $pawn->can_reach("e4") == 0 );
$pawn->set_moved(1);
ok( $pawn->can_reach("e5") == 0 );
ok( $pawn->can_reach("d6") == 1 );
ok( $pawn->can_reach("f6") == 1 );
$queen = $pawn->promote("queen");
ok( $queen->can_reach("e8") == 1 );
