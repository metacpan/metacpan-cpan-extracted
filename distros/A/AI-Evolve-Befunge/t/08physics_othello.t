#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use AI::Evolve::Befunge::Util qw(v);
use aliased 'AI::Evolve::Befunge::Board'   => 'Board';
use aliased 'AI::Evolve::Befunge::Physics' => 'Physics';

my $num_tests;
BEGIN { $num_tests = 0; };

# basic game
# try to create an othello object
my $othello = Physics->new('othello');
ok(ref($othello) eq "AI::Evolve::Befunge::Physics::othello", "create an othello object");
BEGIN { $num_tests += 1 };


# setup_board
my $board = Board->new(Size => 8, Dimensions => 2);
$othello->setup_board($board);
is($board->as_string, <<EOF, 'setup_board initial values');
........
........
........
...xo...
...ox...
........
........
........
EOF
BEGIN { $num_tests += 1 };


# valid_move
for(my $y = 0; $y < 2; $y++) {
    for(my $x = 0; $x < 8; $x++) {
        for(my $player = 1; $player < 3; $player++) {
            ok(!$othello->valid_move($board, $player, v($x, $y)), "any out-of-range move is invalid");
            ok(!$othello->valid_move($board, $player, v($y, $x)), "any out-of-range move is invalid");
            ok(!$othello->valid_move($board, $player, v(7-$x, 7-$y)), "any out-of-range move is invalid");
            ok(!$othello->valid_move($board, $player, v(7-$y, 7-$x)), "any out-of-range move is invalid");
        }
    }
}
BEGIN { $num_tests += 128 };
for(my $player = 1; $player < 3; $player++) {
    ok(!$othello->valid_move($board, $player, v(2, 2)), "non-jump moves are invalid");
    ok(!$othello->valid_move($board, $player, v(2, 5)), "non-jump moves are invalid");
    ok(!$othello->valid_move($board, $player, v(5, 2)), "non-jump moves are invalid");
    ok(!$othello->valid_move($board, $player, v(5, 5)), "non-jump moves are invalid");
    ok(!$othello->valid_move($board, $player, v(3, 3)), "already taken moves are invalid");
    ok(!$othello->valid_move($board, $player, v(3, 4)), "already taken moves are invalid");
    ok(!$othello->valid_move($board, $player, v(4, 3)), "already taken moves are invalid");
    ok(!$othello->valid_move($board, $player, v(4, 4)), "already taken moves are invalid");
}
is($othello->try_move_vector($board,1,v(3,3),v(-1,0)), 0, 'already taken moves are invalid');
ok($othello->valid_move($board, 1, v(4, 2)), "valid move");
ok($othello->valid_move($board, 1, v(5, 3)), "valid move");
ok($othello->valid_move($board, 1, v(2, 4)), "valid move");
ok($othello->valid_move($board, 1, v(3, 5)), "valid move");
ok($othello->valid_move($board, 2, v(3, 2)), "valid move");
ok($othello->valid_move($board, 2, v(5, 4)), "valid move");
ok($othello->valid_move($board, 2, v(2, 3)), "valid move");
ok($othello->valid_move($board, 2, v(4, 5)), "valid move");
ok(!$othello->won($board), "game isn't won yet");
dies_ok(sub { $othello->valid_move() }, "missing board");
dies_ok(sub { $othello->valid_move($board) }, "missing player");
dies_ok(sub { $othello->valid_move($board, 1) }, "missing vector");
dies_ok(sub { $othello->valid_move($board, 1, 0) }, "invalid vector");
BEGIN { $num_tests += 30 };


# make_move
dies_ok(sub { $othello->make_move($board,0,v(5,3)) }, "player out of range");
dies_ok(sub { $othello->make_move($board,3,v(5,3)) }, "player out of range");
dies_ok(sub { $othello->make_move($board,1,undef)  },  "undef vector");
dies_ok(sub { $othello->make_move($board,1,v(10,0))}, "vector out of range");
is($board->as_string(), <<EOF, "new board");
........
........
........
...xo...
...ox...
........
........
........
EOF
# player 1 makes a move
is($othello->make_move($board,1,v(5,3)), 2, "after player 1 moves, player 2 is next");
is($board->as_string(), <<EOF, "after one move");
........
........
........
...xxx..
...ox...
........
........
........
EOF
is($othello->score($board, 1, 1), 4, "score");
is($othello->score($board, 2, 1), 1, "score");
is($othello->over($board), 0, "over");
# player 1 makes another move
is($othello->make_move($board,1,v(2,4)), 0, "after player 1 moves again, the game is won; no moves are valid");
is($board->as_string(), <<EOF, "after two moves");
........
........
........
...xxx..
..xxx...
........
........
........
EOF
is($othello->score($board, 1, 1), 6, "score");
is($othello->score($board, 2, 1), 0, "score");
is($othello->over($board), 1, "over");
is($othello->won($board), 1, "game is won by player 1");
$$board{b} = [
    [0,0,0,0,0,0,0,0], # 0
    [0,0,0,0,0,0,0,0], # 1
    [0,0,0,0,0,0,0,0], # 2
    [0,0,1,1,1,1,1,0], # 3
    [0,0,1,2,1,0,1,0], # 4
    [0,0,1,1,1,1,1,0], # 5
    [0,0,0,0,0,0,0,0], # 6
    [0,0,0,0,0,0,0,0], # 7
#    0 1 2 3 4 5 6 7
];
is($othello->can_pass($board,1), 1, "player 1 has no valid moves, can pass");
is($othello->make_move($board,2,v(5,4)), 2, "player 1 has to pass, player 2 moves again");
$$board{b} = [
    [0,0,0,0,0,0,0,0], # 0
    [0,0,0,0,0,0,0,0], # 1
    [0,2,2,2,0,1,1,1], # 2
    [0,2,0,2,0,1,1,1], # 3
    [0,2,1,2,0,1,1,1], # 4
    [0,2,2,2,0,1,1,1], # 5
    [0,0,0,0,0,0,0,0], # 6
    [0,0,0,0,0,0,0,0], # 7
#    0 1 2 3 4 5 6 7
];
is($othello->won( $board), 0, "game not won yet");
is($othello->over($board), 0, "game not over yet");
is($othello->make_move($board,2,v(2,3)), 0, "no valid moves, equal scores, tie game");
$$board{b} = [
    [0,0,0,0,0,0,0,0], # 0
    [0,0,0,0,0,0,0,0], # 1
    [0,2,2,2,0,0,0,0], # 2
    [0,2,2,2,0,0,0,0], # 3
    [0,2,2,2,0,0,0,0], # 4
    [0,2,2,2,0,0,0,0], # 5
    [0,0,0,0,0,0,0,0], # 6
    [0,0,0,0,0,0,0,0], # 7
#    0 1 2 3 4 5 6 7
];
is($othello->won($board), 2, "nothing left of player 1");
$$board{b} = [
    [0,0,0,0,0,0,0,0], # 0
    [0,0,0,0,0,0,0,0], # 1
    [0,0,0,0,0,0,0,0], # 2
    [0,2,2,0,0,1,0,0], # 3
    [0,0,0,0,0,0,0,0], # 4
    [0,0,0,0,0,0,0,0], # 5
    [0,0,0,0,0,0,0,0], # 6
    [0,0,0,0,0,0,0,0], # 7
#    0 1 2 3 4 5 6 7
];
is($othello->won($board), 2, "player 2 still wins");
$$board{b} = [
    [0,0,0,0,0,0,0,0], # 0
    [0,0,0,0,0,0,0,0], # 1
    [0,0,0,0,0,0,0,0], # 2
    [0,2,0,0,1,1,0,0], # 3
    [0,0,0,0,0,0,0,0], # 4
    [0,0,0,0,0,0,0,0], # 5
    [0,0,0,0,0,0,0,0], # 6
    [0,0,0,0,0,0,0,0], # 7
#    0 1 2 3 4 5 6 7
];
is($othello->won($board), 1, "player 1 still wins");
BEGIN { $num_tests += 24 };


# in_bounds
dies_ok(sub { $othello->in_bounds() }, "in_bounds with no argument");
BEGIN { $num_tests += 1 };





BEGIN { plan tests => $num_tests };
