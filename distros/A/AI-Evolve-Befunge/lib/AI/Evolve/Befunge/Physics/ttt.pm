package AI::Evolve::Befunge::Physics::ttt;
use strict;
use warnings;
use Carp;
use Language::Befunge::Vector;

use AI::Evolve::Befunge::Util;
use AI::Evolve::Befunge::Physics qw(register_physics);
use base 'AI::Evolve::Befunge::Physics';


=head1 NAME
    AI::Evolve::Befunge::Physics::ttt - a tic tac toe game


=head1 SYNOPSIS

    my $ttt = AI::Evolve::Befunge::Physics->new('ttt');


=head1 DESCRIPTION

This is an implementation of the "ttt" game ruleset.  It is
implemented as a plugin for the AI::Evolve::Befunge Physics system;
essentially an AI creature exists in a "tic tac toe" universe,
and plays by its rules.


=head1 CONSTRUCTOR

Use AI::Evolve::Befunge::Physics->new() to get a ttt object;
there is no constructor in this module for you to call directly.


=head1 METHODS

=head2 setup_board

    $ttt->setup_board($board);

Initialize the board to its default state.  For tic tac toe, this
looks like:

    ...
    ...
    ...

=cut

sub setup_board {
    my ($self, $board) = @_;
    $board->clear();
}


=head2 valid_move

    my $valid = $ttt->valid_move($board, $player, $pos);

Returns 1 if the move is valid, 0 otherwise.  In tic tac toe, all
places on the board are valid unless the spot is already taken with
an existing piece.

=cut

sub valid_move {
    my ($self, $board, $player, $v) = @_;
    confess "board is not a ref!" unless ref $board;
    confess "Usage: valid_move(self,board,player,vector)" unless defined($player) && defined($v);
    confess("need a vector argument") unless ref($v) eq 'Language::Befunge::Vector';
    my ($x, $y) = ($v->get_component(0), $v->get_component(1));
    return 0 if $x < 0 || $y < 0;
    return 0 if $x > 2 || $y > 2;
    for my $dim (2..$v->get_dims()-1) {
        return 0 if $v->get_component($dim);
    }
    return 0 if $board->fetch_value($v);
    return 1;
}


=head2 won

    my $winner = $ttt->won($board);

If the game has been won, returns the player who won.  Returns 0
otherwise.

=cut

my @possible_wins = (
    # row wins
    [v(0,0), v(0,1), v(0,2)],
    [v(1,0), v(1,1), v(1,2)],
    [v(2,0), v(2,1), v(2,2)],
    # col wins
    [v(0,0), v(1,0), v(2,0)],
    [v(0,1), v(1,1), v(2,1)],
    [v(0,2), v(1,2), v(2,2)],
    # diagonal wins
    [v(0,0), v(1,1), v(2,2)],
    [v(2,0), v(1,1), v(0,2)],
);

sub won {
    my $self = shift;
    my $board = shift;
    foreach my $player (1..2) {
        my $score;
        foreach my $row (@possible_wins) {
            $score = 0;
            foreach my $i (0..2) {
                my $v = $$row[$i];
                $score++ if $board->fetch_value($v) == $player;
            }
            return $player if $score == 3;
        }
    }
    return 0;
}


=head2 over

    my $over = $ttt->over($board);

Returns 1 if no more moves are valid from either player, and returns
0 otherwise.

=cut

sub over {
    my $self = shift;
    my $board = shift;
    return 1 if $self->won($board);
    foreach my $y (0..2) {
        foreach my $x (0..2) {
            return 0 unless $board->fetch_value(v($x, $y));
        }
    }
    return 1;
}


=head2 score

    my $score = $ttt->score($board, $player, $number_of_moves);

Return a relative score of how the player performed in a game.
Higher numbers are better.

=cut

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
    return 10 if $self->over($board);
    # game isn't over yet
    my $mine = 0;
    foreach my $y (0..2) {
        foreach my $x (0..2) {
            if($board->fetch_value(v($x, $y)) == $player) {
                $mine++;
            }
        }
    }
    return $mine;
}


=head2 can_pass

    my $can_pass = $ttt->can_pass($board, $player);

Always returns 0; tic tac toe rules do not allow passes under any
circumstances.

=cut

sub can_pass {
    return 0;
}


=head2 make_move

    $next_player = $ttt->make_move($board, $player, $pos)
        if $ttt->valid_move($board, $player, $pos);

Makes the given move, updates the board with the newly placed piece.

=cut

sub make_move {
    my ($self, $board, $player, $v) = @_;
    confess("need a vector argument") unless ref($v) eq 'Language::Befunge::Vector';
    $board->set_value($v, $player);
    return 0 if $self->won($board);
    return 0 if $self->over($board);
    return 3 - $player;  # 2 => 1, 1 => 2
}

register_physics(
    name       => "ttt",
    token      => ord('T'),
    decorate   => 0,
    board_size => v(3, 3),
    commands   => {
        M => \&AI::Evolve::Befunge::Physics::op_make_board_move,
        T => \&AI::Evolve::Befunge::Physics::op_query_tokens
    },
);

1;
