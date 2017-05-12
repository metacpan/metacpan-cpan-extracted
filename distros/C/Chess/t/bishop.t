use Test::Simple tests => 6;

use Chess::Piece::Bishop;

$bishop = Chess::Piece::Bishop->new("d4", "white", "White King's bishop");
ok( $bishop );
ok( $bishop->can_reach("h8") == 1 );
ok( $bishop->can_reach("a7") == 1 );
ok( $bishop->can_reach("a1") == 1 );
ok( $bishop->can_reach("g1") == 1 );
ok( $bishop->can_reach("h7") == 0 );
