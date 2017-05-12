#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN { $ENV{AIEVOLVEBEFUNGE} = 't/testconfig.conf'; };

use AI::Evolve::Befunge::Util qw(v);
use aliased 'AI::Evolve::Befunge::Board'     => 'Board';
use aliased 'AI::Evolve::Befunge::Physics'   => 'Physics';

my $num_tests;
BEGIN { $num_tests = 0; };


# try to create a tic tac toe object
my $ttt = Physics->new('ttt');
ok(ref($ttt) eq "AI::Evolve::Befunge::Physics::ttt", "create a tic tac toe object");
BEGIN { $num_tests += 1 };


# valid_move
my $board = Board->new(Size => 3, Dimensions => 2);
$$board{b} = [
    [1, 2, 1],
    [2, 0, 2],
    [1, 2, 1],
];
ok( $ttt->valid_move($board, 1, v(1, 1)), "any untaken move is valid");
ok( $ttt->valid_move($board, 2, v(1, 1)), "any untaken move is valid");
ok(!$ttt->valid_move($board, 1, v(0, 0)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 1, v(1, 0)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 1, v(2, 0)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 1, v(0, 1)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 1, v(2, 1)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 1, v(0, 2)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 1, v(1, 2)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 1, v(2, 2)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 2, v(0, 0)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 2, v(1, 0)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 2, v(2, 0)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 2, v(0, 1)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 2, v(2, 1)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 2, v(0, 2)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 2, v(1, 2)), "any taken move is invalid");
ok(!$ttt->valid_move($board, 2, v(2, 2)), "any taken move is invalid");
dies_ok(sub { $ttt->valid_move() }, "missing board");
dies_ok(sub { $ttt->valid_move($board) }, "missing player");
dies_ok(sub { $ttt->valid_move($board, 1) }, "missing vector");
dies_ok(sub { $ttt->valid_move($board, 1, 0) }, "invalid vector");
ok(!$ttt->valid_move($board, 2, v(-1,1)), "vector out of range");
ok(!$ttt->valid_move($board, 2, v(3, 1)), "vector out of range");
ok(!$ttt->valid_move($board, 2, v(1,-1)), "vector out of range");
ok(!$ttt->valid_move($board, 2, v(1, 3)), "vector out of range");
ok(!$ttt->valid_move($board, 2, v(1, 1, 0, 2)), "clamping down on extra dimensions");
is($ttt->score($board, 1), 4, "score");
BEGIN { $num_tests += 28 };

ok(!$ttt->won($board), "game isn't won yet");
ok(!$ttt->over($board), "game isn't over yet");
is($ttt->can_pass($board, 1), 0, "ttt can never pass");
# player 1 takes middle for the win
is($ttt->make_move($board,1, v(1,1)), 0, "after player 1 wins, game is over");
is($ttt->won($board), 1, "game is won by player 1");
is($ttt->over($board), 1, "game is over");
is($ttt->score($board, 1, 9), 11, "player 1's score");
is($ttt->score($board, 2, 9),  9, "player 2's score");
BEGIN { $num_tests += 8 };

# make_move
$$board{b} = [
    [0, 2, 1],
    [2, 0, 2],
    [2, 1, 2],
];
dies_ok(sub { $ttt->make_move($board, 1, 0) }, "invalid vector");
is($ttt->make_move($board,1,v(0,0)), 2, "player 1 moves, player 2 is next");
is($ttt->make_move($board,1,v(1,1)), 0, "player 1 moves, game over");
is($ttt->score($board, 1, 9), 10, "tie game");
is($ttt->score($board, 2, 9), 10, "tie game");
$$board{b} = [
    [1, 2, 1],
    [2, 0, 2],
    [2, 1, 2],
];
is($ttt->make_move($board,1,v(1,1)), 0, "draw game = game over");
BEGIN { $num_tests += 6 };


# setup_board
$ttt->setup_board($board);
is($board->as_string, <<EOF, "empty board");
...
...
...
EOF
BEGIN { $num_tests += 1 };


BEGIN { plan tests => $num_tests };
