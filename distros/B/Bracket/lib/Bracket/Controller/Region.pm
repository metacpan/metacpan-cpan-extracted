package Bracket::Controller::Region;

use Moose;
BEGIN { extends 'Catalyst::Controller' }
use Perl6::Junction qw/ any /;
use DateTime;

my $PERFECT_BRACKET_MODE = 1;

=head1 NAME

Bracket::Controller::Region - Edit/View Regional picks


=cut

sub save_picks : Local {
    my ($self, $c, $region, $player_id) = @_;

    my $player_object = $c->model('DBIC::Player')->find({ id => $player_id });
    my $player_name = $player_object->first_name . ' ' . $player_object->last_name;
    $c->stash->{player_id}   = $player_id;
    $c->stash->{player_name} = $player_name;
    my $region_object = $c->model('DBIC::Region')->find($region);
    my $region_name   = $region_object->name;
    $c->stash->{region}      = $region;
    $c->stash->{region_name} = $region_name;

    my $params = $c->request->params;

    # Do database insert
    foreach my $pgame (keys %{$params}) {
        $pgame =~ m{p(\d+)};
        my $game = $1;
        my $team = ${$params}{$pgame};
        my ($pick) = $c->model('DBIC::Pick')->search({ player => $player_id, game => $game });
        if (defined $pick) {
            $pick->pick($team);
            $pick->update;
        }
        else {
            my $new_pick =
              $c->model('DBIC::Pick')->new({ player => $player_id, game => $game, pick => $team });
            $new_pick->insert;
        }
    }

    $c->stash->{params} = $params;
    my $previous_user_id = $c->session->{previous_user_id};
    $c->response->redirect(
        $c->uri_for($c->controller('Player')->action_for('home'))
        . "/${player_id}"
    );

    return;
}

sub view : Local {
    my ($self, $c, $region_id, $player_id) = @_;

    my @perfect_picks = $c->model('DBIC::Pick')->search({ player => 1 });
    my @player_picks  = $c->model('DBIC::Pick')->search({ player => $player_id });

    my %picks;
    my %class_for;
    my $region_points = 0;
    my @show_regions;
    foreach my $player_pick (@player_picks) {

        # Operate only on the current region
        if ($player_pick->pick->region->id == $region_id) {

            # Compare player pick to actual winner for the perfect player bracket
            # Build the css class name accordingly
            my ($winning_pick) =
              $c->model('DBIC::Pick')->search({ player => 1, game => $player_pick->game->id });
            if (defined $winning_pick) {
                if ($winning_pick->pick->id == $player_pick->pick->id) {
                    $class_for{ $player_pick->game->id } = 'in';

                    # Formula to compute points for correct picks
                    my $points_for_pick =
                      (5 + $player_pick->pick->seed * $player_pick->game->lower_seed) *
                      $player_pick->game->round;
                    $region_points += $points_for_pick;
                }
                else {
                    $class_for{ $player_pick->game->id } = 'out';
                }
            }
            else {

                # Need to determine if player pick has already been ousted in a
                # previous round using round_out variable.
                if ($player_pick->game->round >= $player_pick->pick->round_out) {

                    #                    warn "round greater than round out: ",
                    #                      $player_pick->game->round, ' and ',
                    #                      $player_pick->pick->round_out;
                    $class_for{ $player_pick->game->id } = 'out';
                }
                else {
                    $class_for{ $player_pick->game->id } = 'pending';
                }
            }
            $picks{ $player_pick->game->id } = $player_pick->pick;
        }
    }
    $c->stash->{class_for}     = \%class_for;
    $c->stash->{picks}         = \%picks;
    $c->stash->{region_points} = $region_points;

    my $player = $c->model('DBIC::Player')->find($player_id);
    $c->stash->{player} = $player;
    my $region = $c->model('DBIC::Region')->find($region_id);
    $c->stash->{region}       = $region;
    $c->stash->{teams}        = $c->model('DBIC::Team')->search({region => $region_id});
    $c->stash->{regions}      = $c->model('DBIC::Region')->search({},{order_by => 'id'});
    $c->stash->{show_regions} = \@show_regions;
    $c->stash->{template}     = 'region/view_region_status.tt';

    return;
}

sub edit : Local {
    my ($self, $c, $region, $player) = @_;

    # Restrict edits to user or admin role.
    my @user_roles = $c->user->roles;
    $c->go('/error_404') if (($player != $c->user->id) && !('admin' eq any(@user_roles)));

    # Go to home if edits are attempted after closing time
    # NOTE: Put a player's id on this list and they can make edits after the cut-off.
    my @open_edit_ids = qw/ /;
    my $edit_allowed = 1 if ($c->user->id eq any(@open_edit_ids));
    if ( $c->stash->{is_game_time} && (!($c->stash->{is_admin} || $edit_allowed)) ) {
        $c->flash->{status_msg} = 'Regional edits are closed';
        $c->response->redirect($c->uri_for($c->controller('Player')->action_for('home')));
    }

    # Player picks
    my @picks = $c->model('DBIC::Pick')->search({ player => $player });
    my %picks;
    foreach my $pick (@picks) {
        $picks{ $pick->game->id } = $pick->pick;
    }
    $c->stash->{picks} = \%picks;

    # Player info
    my $player_object = $c->model('DBIC::Player')->find($player);
    my $player_name   = $player_object->first_name . ' ' . $player_object->last_name;
    $c->stash->{player}      = $player;
    $c->stash->{player_name} = $player_name;

    # Region object
    my $region_object = $c->model('DBIC::Region')->find($region);
    my $region_name   = $region_object->name;
    $c->stash->{region}      = $region;
    $c->stash->{region_name} = $region_name;

    # Teams
    $c->stash->{teams} = $c->model('DBIC::Team')->search({region => $region});
    

    $c->stash->{template} = 'region/edit_region_picks.tt';

    return;
}

=head1 AUTHOR

mateu x hunter

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
