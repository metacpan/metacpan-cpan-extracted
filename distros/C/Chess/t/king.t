use Test::Simple tests => 8;

use Chess::Piece::King;

$king = Chess::Piece::King->new("e1", "white", "White King");
ok( $king );
ok( $king->can_reach("d1") == 1 );
ok( $king->can_reach("f1") == 1 );
ok( $king->can_reach("d2") == 1 );
ok( $king->can_reach("e2") == 1 );
ok( $king->can_reach("f2") == 1 );
ok( $king->can_reach("g1") == 1 );
$king->set_moved(1);
ok( $king->can_reach("c1") == 0 );
