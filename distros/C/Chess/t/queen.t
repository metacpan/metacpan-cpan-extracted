use Test::Simple tests => 7;

use Chess::Piece::Queen;

$queen = Chess::Piece::Queen->new("d1", "white", "White Queen");
ok( $queen );
ok( $queen->can_reach("a1") == 1 );
ok( $queen->can_reach("h1") == 1 );
ok( $queen->can_reach("d8") == 1 );
ok( $queen->can_reach("h5") == 1 );
ok( $queen->can_reach("a4") == 1 );
ok( $queen->can_reach("e4") == 0 );
