use Test::Simple tests => 6;

use Chess::Game;

$game = Chess::Game->new();
$game->make_move("e2", "e3", 1);
$game->make_move("f7", "f6", 1);
$game->make_move("d2", "d3", 1);
$game->make_move("g7", "g5", 1);
$game->make_move("d1", "h5", 1);
ok( $game->player_checkmated("black") );
ok( $game->result() == 1 );
$game->take_back_move();
ok( !$game->player_checkmated("black") );
ok( !defined($game->result()) );
$game->make_move("d1", "h5", 1);
ok( $game->player_checkmated("black") );
# http://rt.cpan.org/Ticket/Display.html?id=28540
$game = Chess::Game->new();
$game->make_move("e2", "e4", 1);
$game->make_move("e7", "e6", 1);
$game->make_move("d2", "d4", 1);
$game->make_move("f7", "f6", 1);
$game->make_move("c1", "h6", 1);
$game->make_move("g7", "h6", 1);
$game->make_move("d1", "h5", 1);
ok( !$game->player_checkmated("black") );
