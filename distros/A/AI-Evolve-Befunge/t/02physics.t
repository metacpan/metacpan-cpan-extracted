#!/usr/bin/perl
use strict;
use warnings;

BEGIN { $ENV{AIEVOLVEBEFUNGE} = 't/testconfig.conf'; };

my $num_tests;
BEGIN { $num_tests = 0; };
use Test::More;
use Test::Exception;
use Test::Output;

use aliased 'AI::Evolve::Befunge::Critter'   => 'Critter';
use aliased 'AI::Evolve::Befunge::Blueprint' => 'Blueprint';
use aliased 'AI::Evolve::Befunge::Board'     => 'Board';
use aliased 'AI::Evolve::Befunge::Physics'   => 'Physics';
use aliased 'AI::Evolve::Befunge::Critter::Result' => 'Result';
use AI::Evolve::Befunge::Util;


push_quiet(1);
# registration API
dies_ok(sub { register_physics(foo => 'bar') }, "no name");
lives_ok(sub{ register_physics(name => 'test0', foo => 'bar') }, "registration");
dies_ok(sub { register_physics(name => 'test0', foo => 'bar') }, "reregistration");
my $test = AI::Evolve::Befunge::Physics::find_physics("test0");
is($$test{foo}, 'bar', "our fake physics engine was registered properly");
$test = AI::Evolve::Befunge::Physics::find_physics("unknown");
is($$test{foo}, undef, "unknown engine results in undef");
BEGIN { $num_tests += 5 };


# constructor
dies_ok(sub { AI::Evolve::Befunge::Physics::new }, 'no package');
dies_ok(sub { Physics->new }, 'no plugin');
dies_ok(sub { Physics->new('unknown') }, 'nonexistent plugin');
my $config = custom_config();
$test = Physics->new('test1');
ok(ref($test) eq "AI::Evolve::Befunge::Physics::test1", "create a test physics object");
BEGIN { $num_tests += 4 };


# run_board_game
my $part1 =  "00M@" . (" "x12);
my $play1 =  "01M["
            ."M@#]" . (" "x8);
my $dier1 =  (" "x16);
my $tier1 =  "00M["
            ."M10]" . (" "x8);
my $tier2 =  "10M["
            ."M11]" . (" "x8);
my $bpart1 = Blueprint->new(code => $part1, dimensions => 2);
my $bplay1 = Blueprint->new(code => $play1, dimensions => 2);
my $bdier1 = Blueprint->new(code => $dier1, dimensions => 2);
my $btier1 = Blueprint->new(code => $tier1, dimensions => 2);
my $btier2 = Blueprint->new(code => $tier2, dimensions => 2);
my $board = Board->new(Size => 2, Dimensions => 2);
my $cpart1 = Critter->new(Blueprint => $bpart1, BoardSize => $board->size, Color => 1, Physics => $test, Commands => $$test{commands}, Config => $config);
my $cplay1 = Critter->new(Blueprint => $bplay1, BoardSize => $board->size, Color => 2, Physics => $test, Commands => $$test{commands}, Config => $config);
my $cdier1 = Critter->new(Blueprint => $bdier1, BoardSize => $board->size, Color => 1, Physics => $test, Commands => $$test{commands}, Config => $config);
my $ctier1 = Critter->new(Blueprint => $btier1, BoardSize => $board->size, Color => 1, Physics => $test, Commands => $$test{commands}, Config => $config);
my $ctier2 = Critter->new(Blueprint => $btier2, BoardSize => $board->size, Color => 2, Physics => $test, Commands => $$test{commands}, Config => $config);
dies_ok(sub { AI::Evolve::Befunge::Physics::run_board_game }, "no self");
dies_ok(sub { $test->run_board_game() }, "no board");
dies_ok(sub { $test->run_board_game([], $board) }, "no critters");
dies_ok(sub { $test->run_board_game([$cpart1], $board) }, "too few critters");
dies_ok(sub { $test->run_board_game([$cpart1, $cplay1, $cplay1], $board ) }, "too many critters");
dies_ok(sub { $test->run_board_game([$cpart1, $cplay1], $board, $cplay1 ) }, "too many args");
lives_ok(sub{ $test->run_board_game([$cpart1, $cplay1], $board ) }, "a proper game was played");
$$test{passable} = 0;
push_debug(1);
stdout_like(sub{ $test->run_board_game([$cdier1, $cplay1], $board ) },
     qr/STDIN \(-4,-4\): infinite loop/,
     "killed with an infinite loop error");
pop_debug();
lives_ok(sub{ $test->run_board_game([$ctier1, $ctier2], $board) }, "a proper game was played");
lives_ok(sub{ $test->run_board_game([$cpart1, $cpart1], $board) }, "a tie game was played");
push_quiet(0);
stdout_is(sub { $test->run_board_game([$cplay1, $cpart1], $board) }, <<EOF, "outputs board");
   01
 0 o.
 1 ..
EOF
pop_quiet();
BEGIN { $num_tests += 11 };


# compare
is($test->compare(Result->new(won    => 1), Result->new()           ), 32, "compare won");
is($test->compare(Result->new(score  => 1), Result->new()           ), 16, "compare score");
is($test->compare(Result->new(moves  => 1), Result->new()           ),  8, "compare moves");
is($test->compare(Result->new(tokens => 1), Result->new()           ),  4, "compare tokens");
is($test->compare(Result->new(), Result->new(died   => 1)           ),  2, "compare died");
is($test->compare(Result->new(name => 'a'), Result->new(name => 'b')),  1, "compare name");
BEGIN { $num_tests += 6 };


# setup_and_run
dies_ok(sub { $test->setup_and_run_board_game(               ) }, "no config argument");
dies_ok(sub { $test->setup_and_run_board_game($config        ) }, "no blueprint1 argument");
dies_ok(sub { $test->setup_and_run_board_game($config,$bplay1) }, "no blueprint2 argument");
BEGIN { $num_tests += 3 };


# double_match
dies_ok(sub { $test->double_match(               ) }, "no config argument");
dies_ok(sub { $test->double_match($config        ) }, "no blueprint1 argument");
dies_ok(sub { $test->double_match($config,$bplay1) }, "no blueprint2 argument");
BEGIN { $num_tests += 3 };


# non-game physics engines
$test = Physics->new('test2');
lives_ok(sub{ $test->run_board_game([$cdier1, $cdier1], $board) }, "a proper game was played");
BEGIN { $num_tests += 1 };


BEGIN { plan tests => $num_tests };


package AI::Evolve::Befunge::Physics::test1;
use strict;
use warnings;
use Carp;

# this game is a sort of miniature tic tac toe, played on a 2x2 board.
# one difference: only diagonal lines are counted as wins.

use AI::Evolve::Befunge::Util;
use base 'AI::Evolve::Befunge::Physics';
use AI::Evolve::Befunge::Physics  qw(register_physics);

sub new {
    my $package = shift;
    return bless({}, $package);
}

sub get_token { return ord('_'); }

sub decorate_valid_moves {
    return 0;
}

sub valid_move {
    my ($self, $board, $player, $v) = @_;
    confess "board is not a ref!" unless ref $board;
    confess "Usage: valid_move(self,board,player,vector)" unless defined($player) && defined($v);
    confess("need a vector argument") unless ref($v) eq 'Language::Befunge::Vector';
    my ($x, $y) = ($v->get_component(0), $v->get_component(1));
    return 0 if $x < 0 || $y < 0;
    return 0 if $x > 1 || $y > 1;
    for my $dim (2..$v->get_dims()-1) {
        return 0 if $v->get_component($dim);
    }
    return 0 if $board->fetch_value($v);
    return 1;
}

my @possible_wins;

sub won {
    my $self = shift;
    my $board = shift;
    foreach my $player (1..2) {
        foreach my $row (@possible_wins) {
            my $score = 0;
            foreach my $i (0..1) {
                my $v = $$row[$i];
                $score++ if $board->fetch_value($v) == $player;
            }
            return $player if $score == 2;
        }
    }
    return 0;
}

sub over {
    my $self = shift;
    my $board = shift;
    return 1 if $self->won($board);
    foreach my $y (0..1) {
        foreach my $x (0..1) {
            return 0 unless $board->fetch_value(v($x, $y));
        }
    }
    return 1;
}

sub score {
    my ($self, $board, $player, $moves) = @_;
    if($self->won($board) == $player) {
        # won! the quicker, the better.
        return 20 - $moves;
    }
    if($self->won($board)) {
        # lost; prolonging defeat scores better
        return $moves;
    }
    # draw
    return 0 if $self->over($board);
    # game isn't over yet
    my $mine = 0;
    foreach my $y (0..1) {
        foreach my $x (0..1) {
            if($board->fetch_value(v($x, $y)) == $player) {
                $mine++;
            } elsif($board->fetch_value(v($x, $y))) {
                $mine--;
            }
        }
    }
    return $mine;
}

sub can_pass {
    my ($self, $board, $color) = @_;
    return 0 unless $$self{passable};
    my $score = 0;
    foreach my $y (0..1) {
        foreach my $x (0..1) {
            if($board->fetch_value(v($x, $y)) == $color) {
                $score++;
            }
        }
    }
    return $score < 2;
}

sub make_move {
    my ($self, $board, $player, $v) = @_;
    confess("need a vector argument") unless ref($v) eq 'Language::Befunge::Vector';
    $board->set_value($v, $player);
    return 0 if $self->won($board);
    return 0 if $self->over($board);
    return 3 - $player;  # 2 => 1, 1 => 2
}

sub setup_board {
    my ($self, $board) = @_;
    $board->clear();
}

BEGIN {
    register_physics(
        name => "test1",
        board_size => v(2, 2),
        commands   => {
            M => \&AI::Evolve::Befunge::Physics::op_make_board_move,
            T => \&AI::Evolve::Befunge::Physics::op_query_tokens
        },
        passable   => 1,
    );
    @possible_wins = (
        [v(0,0), v(1,1)],
        [v(1,0), v(0,1)],
    );
};


package AI::Evolve::Befunge::Physics::test2;
use strict;
use warnings;
use Carp;

# this is a boring, non-game physics engine.  Not much to see here.

use AI::Evolve::Befunge::Util;
use base 'AI::Evolve::Befunge::Physics';
use AI::Evolve::Befunge::Physics  qw(register_physics);

sub new {
    my $package = shift;
    return bless({}, $package);
}

sub get_token { return ord('-'); }

sub decorate_valid_moves { return 0; }
sub valid_move           { return 0; }
sub won                  { return 0; }
sub over                 { return 0; }
sub score                { return 0; }
sub can_pass             { return 0; }
sub make_move            { return 0; }
sub setup_board          { return 0; }

BEGIN { register_physics(
        name => "test2",
);};
