package Bracket::Controller::Final4;
use Moose;
BEGIN { extends 'Catalyst::Controller' }
use Perl6::Junction qw/ any /;
use Data::Dumper::Concise;

=head1 NAME

Bracket::Controller::Final4 - Edit/View Final 4 Picks

=cut

my %region_winner_picks = (
    1 => 15,
    2 => 30,
    3 => 45,
    4 => 60,
);

sub make : Local {
    my ($self, $c, $player_id) = @_;

    # Restrict edits to user or admin role.
    my @user_roles = $c->user->roles;
    $c->go('/error_404') if (($player_id != $c->user->id) && !('admin' eq any(@user_roles)));

    my $player = $c->model('DBIC::Player')->find($player_id);
    $c->stash->{player} = $player;

    # Get the player's regional winner picks.  Later we deal w/ whether they actually won or not.
    # region_id => game_id
    foreach my $region_id (keys %region_winner_picks) {
        my $region_name = 'region' . "_${region_id}";
        my $game        = $region_winner_picks{$region_id};
        $c->stash->{$region_name} =
          $c->model('DBIC::Pick')->search({ player => $player_id, game => $game })->first;
    }

    # Get all player picks for loading when in edit of existing picks mode
    my @picks = $c->model('DBIC::Pick')->search({ player => $player_id });
    my %picks;
    foreach my $pick (@picks) {
        $picks{ $pick->game->id } = $pick->pick;
    }
    $c->stash->{picks} = \%picks;

    # Create Class for Final Four Teams
    my %class_for;
    foreach my $player_pick (@picks) {
        my ($winning_pick) =
          $c->model('DBIC::Pick')->search({ player => 1, game => $player_pick->game->id });
        if (defined $winning_pick) {
            if ($winning_pick->pick->id == $player_pick->pick->id) {
                $class_for{ $player_pick->game->id } = 'in';
            }
            else {
                $class_for{ $player_pick->game->id } = 'out';
            }
        }
        else {
            if ($player_pick->game->round >= $player_pick->pick->round_out) {

                #if ($player_pick->game == 63) {
#                warn "round: " . $player_pick->game->round . "\n";
#                warn "round_out: " . $player_pick->pick->round_out . "\n";

                #}
                $class_for{ $player_pick->game->id } = 'out';
            }
            else {
                $class_for{ $player_pick->game->id } = 'pending';
            }
        }
    }
    $c->stash->{class_for} = \%class_for;

    # Inform to load final 4 javascript
    $c->stash->{final_4_javascript} = 1;
    $c->stash->{template}           = 'final4/make_final4_picks.tt';

    return;
}

sub save_picks : Local {
    my ($self, $c, $player_id) = @_;

    my $player = $c->model('DBIC::Player')->find($player_id);
    $c->stash->{player}    = $player;
    $c->stash->{player_id} = $player_id;

    my $params = $c->request->params;

    # Do database insert
    foreach my $pgame (keys %{$params}) {
        $pgame =~ m{p(\d+)};
        my $game_id = $1;
        my $team_id = ${$params}{$pgame};
        my ($pick) = $c->model('DBIC::Pick')->search({ player => $player_id, game => $game_id });
        if (defined $pick) {
            $pick->pick($team_id);
            $pick->update;
        }
        else {
            my $new_pick = $c->model('DBIC::Pick')->new(
                {
                    player => $player_id,
                    game   => $game_id,
                    pick   => $team_id
                }
            );
            $new_pick->insert;
        }
    }
    $c->stash->{params} = $params;
    $c->response->redirect(
        $c->uri_for($c->controller('Player')->action_for('home'))
        . "/${player_id}"
    );

    return;
}

sub view : Local {
    my ($self, $c, $player_id) = @_;

    my $player = $c->model('DBIC::Player')->find($player_id);
    $c->stash->{player} = $player;

    # Get the player's regional winner picks.
    foreach my $region_id (keys %region_winner_picks) {
        my $region_name = 'region' . "_${region_id}";
        my $game        = $region_winner_picks{$region_id};
        $c->stash->{$region_name} =
          $c->model('DBIC::Pick')->search({ player => $player_id, game => $game })->first;
    }

    # Get all player picks for loading when in edit of existing picks mode
    my @picks = $c->model('DBIC::Pick')->search({ player => $player_id });
    my %picks;
    foreach my $pick (@picks) {
        $picks{ $pick->game->id } = $pick->pick;
    }
    $c->stash->{picks} = \%picks;

    # Create Class for Final Four Teams
    my %class_for;
    foreach my $player_pick (@picks) {
        my ($winning_pick) =
          $c->model('DBIC::Pick')->search({ player => 1, game => $player_pick->game->id });
        if (defined $winning_pick) {
            if ($winning_pick->pick->id == $player_pick->pick->id) {
                $class_for{ $player_pick->game->id } = 'in';
            }
            else {
                $class_for{ $player_pick->game->id } = 'out';
            }
        }
        else {
            if ($player_pick->game->round >= $player_pick->pick->round_out) {
                $class_for{ $player_pick->game->id } = 'out';
            }
            else {
                $class_for{ $player_pick->game->id } = 'pending';
            }
        }
    }
    $c->stash->{class_for} = \%class_for;
    $c->stash->{regions}      = $c->model('DBIC::Region')->search({},{order_by => 'id'});

    # Turn off javascript
    $c->stash->{no_javascript} = 1;
    $c->stash->{template}      = 'final4/view_final4_picks.tt';
    return;
}

=head1 AUTHOR

mateu x hunter

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
