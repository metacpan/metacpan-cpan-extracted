use Test::Simple tests => 10;

use Chess::Piece::Knight;

$knight = Chess::Piece::Knight->new("e4", "white", "White King's knight");
ok( $knight );
ok( $knight->can_reach("d6") == 1 );
ok( $knight->can_reach("f6") == 1 );
ok( $knight->can_reach("d2") == 1 );
ok( $knight->can_reach("f2") == 1 );
ok( $knight->can_reach("c5") == 1 );
ok( $knight->can_reach("g5") == 1 );
ok( $knight->can_reach("c3") == 1 );
ok( $knight->can_reach("g3") == 1 );
ok( $knight->can_reach("g2") == 0 );
