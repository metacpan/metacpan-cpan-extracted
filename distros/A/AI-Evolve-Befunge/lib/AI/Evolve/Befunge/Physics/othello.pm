package AI::Evolve::Befunge::Physics::othello;
use strict;
use warnings;
use Carp;
use Language::Befunge::Vector;

use AI::Evolve::Befunge::Util;
use AI::Evolve::Befunge::Physics qw(register_physics);
use base 'AI::Evolve::Befunge::Physics';

my @valid_dirs = (v(-1,-1),v(0,-1),v(1,-1),v(-1,0),v(1,0),v(-1,1),v(0,1),v(1,1));


=head1 NAME
    AI::Evolve::Befunge::Physics::othello - an othello game


=head1 SYNOPSIS

    my $physics = AI::Evolve::Befunge::Physics->new('othello');


=head1 DESCRIPTION

This is an implementation of the "othello" board game ruleset.  This
game is also known to some as "reversi".  It is implemented as a
plugin for the AI::Evolve::Befunge Physics system; essentially an AI
creature exists in an "othello" universe, and plays by its rules.


=head1 CONSTRUCTOR

Use AI::Evolve::Befunge::Physics->new() to get an othello object;
there is no constructor in this module for you to call directly.


=head1 METHODS

=head2 setup_board

    $othello->setup_board($board);

Initialize the board to its default state.  For othello, this looks
like:

    ........
    ........
    ........
    ...xo...
    ...ox...
    ........
    ........
    ........

=cut

sub setup_board {
    my ($self, $board) = @_;
    $board->clear();
    $board->set_value(v(3, 3), 1);
    $board->set_value(v(3, 4), 2);
    $board->set_value(v(4, 3), 2);
    $board->set_value(v(4, 4), 1);
}


=head2 in_bounds

    die("out of bounds") unless $othello->in_bounds($vec);

Returns 1 if the vector is within the playspace, and 0 otherwise.

=cut

sub in_bounds {
    my($self, $vec) = @_;
    confess("vec undefined") unless defined $vec;
    foreach my $d (0..1) {
        return 0 unless $vec->get_component($d) >= 0;
        return 0 unless $vec->get_component($d) <= 7;
    }
    return 1;
}


=head2 try_move_vector

    my $score = $othello->try_move_vector($board, $player, $pos, $dir);

Determines how many flippable enemy pieces exist in the given
direction.  This is a lowlevel routine, meant to be called by
the valid_move() and make_move() methods, below.

=cut

sub try_move_vector {
    my ($self, $board, $player, $pos, $vec) = @_;
    return 0 if $board->fetch_value($pos);
    my $rv = 0;
    $pos += $vec;
    while($self->in_bounds($pos)) {
        my $val = $board->fetch_value($pos);
        return 0 unless $val;
        return $rv if $val == $player;
        $rv++;
        $pos += $vec;
    }
    return 0;
}


=head2 valid_move

    $next_player = $othello->make_move($board, $player, $pos)
        if $othello->valid_move($board, $player, $pos);

If the move is valid, returns the number of pieces which would be
flipped by moving in the given position.  Returns 0 otherwise.

=cut

sub valid_move {
    my ($self, $board, $player, $v) = @_;
    confess "board is not a ref!" unless ref $board;
    confess "Usage: valid_move(self,board,player,v)"
        unless defined($player) && defined($v);
    confess("$v is not a vector argument") unless ref($v) eq 'Language::Befunge::Vector';
    return 0 if $board->fetch_value($v);
    my $rv = 0;
    foreach my $vec (@valid_dirs) {
        $rv += $self->try_move_vector($board,$player,$v,$vec);
    }
    return $rv;
}


=head2 won

    my $winner = $othello->won($board);

If the game has been won, returns the player who won.  Returns 0
otherwise.

=cut

sub won {
    my ($self, $board) = @_;
    my ($p1, $p2) = (0,0);
    foreach my $y (0..7) {
        foreach my $x (0..7) {
            my $v = v($x, $y);
            return 0 if $self->valid_move($board,1,$v);
            return 0 if $self->valid_move($board,2,$v);
            if($board->fetch_value($v) == 1) {
                $p1++;
            } elsif($board->fetch_value($v)) {
                $p2++;
            }
        }
    }
    unless($p1) {
        return 2;
    }
    unless($p2) {
        return 1;
    }
    return 0 if $p1 == $p2;
    return $p2 < $p1 ? 1 : 2;
}


=head2 over

    my $over = $othello->over($board);

Returns 1 if no more moves are valid from either player, and returns
0 otherwise.

=cut

sub over {
    my ($self, $board) = @_;
    my ($p1, $p2) = (0,0);
    foreach my $y (0..7) {
        foreach my $x (0..7) {
            return 0 if $self->valid_move($board,1,v($x,$y));
            return 0 if $self->valid_move($board,2,v($x,$y));
        }
    }
    return 1;
}


=head2 score

    my $score = $othello->score($board, $player, $number_of_moves);

Returns the number of pieces on the board owned by the given player.

=cut

sub score {
    my ($self, $board, $player, $moves) = @_;
    my $mine = 0;
    foreach my $y (0..7) {
        foreach my $x (0..7) {
            if($board->fetch_value(v($x, $y)) == $player) {
                $mine++;
            }
        }
    }
    return $mine;
}


=head2 can_pass

    my $can_pass = $othello->can_pass($board, $player);

Returns 1 if the player can pass, and 0 otherwise.  For the othello
rule set, passing is only allowed if no valid moves are available.

=cut

sub can_pass {
    my ($self,$board,$player) = @_;
    my $possible_points = 0;
    foreach my $y (0..7) {
        foreach my $x (0..7) {
            $possible_points += valid_move($self,$board,$player,v($x,$y));
        }
    }
    return $possible_points ? 0 : 1;
}


=head2 make_move

    $othello->make_move($board, $player, $pos);

Makes the indicated move, updates the board with the new piece and
flips enemy pieces as necessary.

=cut

sub make_move {
    my ($self, $board, $player, $pos) = @_;
    confess "make_move: player value '$player' out of range!" if $player < 1 or $player > 2;
    confess "make_move: vector is undef!" unless defined $pos;
    confess "make_move: vector '$pos' out of range!" unless $self->in_bounds($pos);
    foreach my $vec (@valid_dirs) {
        my $num = $self->try_move_vector($board,$player,$pos,$vec);
        my $cur = $pos + $vec;
        for(1..$num) {
            $board->set_value($cur, $player);
            $cur += $vec;
        }
    }
    $board->set_value($pos, $player);
    return 0 if $self->won($board); # game over, one of the players won
    return 3-$player unless $self->can_pass($board,3-$player); # normal case, other player's turn
    return $player   unless $self->can_pass($board,$player);   # player moves again
    return 0; # game over, tie game
}


register_physics(
    name       => "othello",
    token      => ord('O'),
    decorate   => 1,
    board_size => v(8, 8),
    commands   => {
        M => \&AI::Evolve::Befunge::Physics::op_make_board_move,
        T => \&AI::Evolve::Befunge::Physics::op_query_tokens
    },
);

1;
