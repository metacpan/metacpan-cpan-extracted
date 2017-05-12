use Test::Simple tests => 2;

use Chess::Game;

$game = Chess::Game->new();
$game->make_move("c2", "c4", 1);
$game->make_move("h7", "h5", 1);
$game->make_move("h2", "h4", 1);
$game->make_move("a7", "a5", 1);
$game->make_move("d1", "a4", 1);
$game->make_move("a8", "a6", 1);
$game->make_move("a4", "a5", 1);
$game->make_move("a6", "h6", 1);
$game->make_move("a5", "c7", 1);
$game->make_move("f7", "f6", 1);
$game->make_move("c7", "d7", 1);
$game->make_move("e8", "f7", 1);
$game->make_move("d7", "b7", 1);
$game->make_move("d8", "d3", 1);
$game->make_move("b7", "b8", 1);
$game->make_move("d3", "h7", 1);
$game->make_move("b8", "c8", 1);
$game->make_move("f7", "g6", 1);
$game->make_move("c8", "e6", 1);
ok( $game->player_stalemated("black") );
ok( $game->result() == 0 );
