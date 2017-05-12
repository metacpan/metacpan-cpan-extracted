package Bracket::Controller::Admin;

use Moose;
BEGIN { extends 'Catalyst::Controller' }
use Perl6::Junction qw/ any /;

=head1 Name

Bracket::Controller::Admin - Functions for admin users.
  
=head1 Description

Controller for admin functions:

* Update player points
* Mark the round teams go out
* Check which wins are by a lower seed

=head1 Methods

=cut

sub auto : Private {
    my ($self, $c) = @_;

    # Restrict controller to admin role
    my @user_roles = $c->user->roles;

    if (!$c->stash->{is_admin}) {
        $c->go('/error_404');
        return 0;
    }
    else { return 1; }
}

sub update_player_points : Global {
    my ($self, $c) = @_;

    $c->stash->{template} = 'player/all_home.tt';
    my @players = $c->model('DBIC::Player')->all;

    # Get player scores
    foreach my $player (@players) {

        # Avoid non active players
        next if $player->active == 0;

        # Get total points, and regional points
        my $points_ref = $c->forward('player_points', [ $player->id ]);
        $player->points($points_ref->[0] || 0);
        $player->update;
        foreach my $region_id (1 .. 4) {
            my $region_score = $c->model('DBIC::RegionScore')->update_or_create(
                {
                    player => $player->id,
                    region => $region_id,
                    points => $points_ref->[1]->{$region_id} || 0
                }
            );
            $region_score->update;
        }
    }
    $c->stash->{players}    = \@players;
    $c->flash->{status_msg} = 'Scores Updated';
    $c->response->redirect($c->uri_for($c->controller('Player')->action_for('all')));
    return;
}

sub player_points : Private {
    my ($self, $c, $player) = @_;

    # Determine player total running score.
    my @player_picks = $c->model('DBIC::Pick')->search({ player => $player });
    my $total_player_points = 0;
    my $points_for_region;
    foreach my $player_pick (@player_picks) {

        # Compare player pick to actual winner for the perfect player bracket
        # Build the css class name accordingly
        my ($winning_pick) =
          $c->model('DBIC::Pick')->search({ player => 1, game => $player_pick->game->id });
        if (defined $winning_pick) {
            if ($winning_pick->pick->id == $player_pick->pick->id) {

                # Compute points for correct pick
                # Formula
                my $points_for_pick =
                  (5 + $player_pick->pick->seed * $player_pick->game->lower_seed);

                # Championship game has round multiplier of 10.
                if ($player_pick->game->round == 6) {
                    $points_for_pick *= 10;
                }

                # All other games have round multiplier of round number.
                else {
                    $points_for_pick *= $player_pick->game->round;
                }
                $total_player_points                                   += $points_for_pick;
                $points_for_region->{ $player_pick->pick->region->id } += $points_for_pick;
            }
        }
    }

    return [ $total_player_points, $points_for_region ];
}

# Quality Assurance to check that lower seeds are marked correctly.
sub qa : Global {
    my ($self, $c) = @_;
    my @played_games = $c->model('DBIC::Pick')->search({ player => 1 }, { order_by => 'game' });
    $c->stash->{played_games} = \@played_games;
    $c->stash->{template}     = 'admin/lower_seeds.tt';
}

sub update_points : Global {
    my ($self, $c) = @_;
    my @points = $c->model('DBIC')->update_points;
    $c->flash->{status_msg} = 'Scores Updated';
    $c->response->redirect($c->uri_for($c->controller('Player')->action_for('all')));
    return;
}

=head2 round_out

Mark the round teams go out.

=cut

sub round_out : Global : ActionClass('REST') {
    my ($self, $c) = @_;

    $c->stash->{template} = 'admin/round_out.tt';
    my @teams = $c->model('DBIC::Team')->all;
    $c->stash(teams => \@teams);
}

sub round_out_GET {}

sub round_out_POST {
    my  ($self, $c) = @_;
    
    foreach my $team (@{$c->stash->{teams}}) {
        $team->update({ round_out => $c->request->body_parameters->{$team->id} });
    }
}

=head2 round_out_unmarked

Show only the teams that havent' been marked out yet.

=cut

sub round_out_unmarked : Global : ActionClass('REST') {
    my ($self, $c) = @_;
    $c->stash->{template} = 'admin/round_out_unmarked.tt';
    my @teams = $c->model('DBIC::Team')->search({round_out => 7})->all;
    $c->stash(teams => \@teams);
}
sub round_out_unmarked_GET {}

sub round_out_unmarked_POST {
    my  ($self, $c) = @_;
    
    foreach my $team (@{$c->stash->{teams}}) {
        $team->update({ round_out => $c->request->body_parameters->{$team->id} });
    }
    $c->response->redirect($c->uri_for($c->controller('Player')->action_for('home')));
    return;
}

__PACKAGE__->meta->make_immutable;
1
