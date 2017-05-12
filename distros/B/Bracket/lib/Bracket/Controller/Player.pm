package Bracket::Controller::Player;

use Moose;
BEGIN { extends 'Catalyst::Controller' }
use Perl6::Junction qw/ any /;

=head1 NAME

Bracket::Controller::Player - Individual and all player homes

=cut

sub home : Path('/player') {
	my ( $self, $c, $player_id ) = @_;

	$c->stash->{template} = 'player/home.tt';

	# If we pass a player id in exlicity we want to view that players home page.
	my $player;
	if ($player_id) {
		$player = $c->model('DBIC::Player')->find($player_id);
		$c->go('/error_404') if !$player;
	}
	else {
		$player    = $c->user;
		$player_id = $c->user->id;
	}
	$c->stash->{player}    = $player;
	$c->stash->{player_id} = $player_id;
	
	# Get regions 
	my @regions = $c->model('DBIC::Region')->search({},{order_by => 'id'})->all;
	$c->stash->{regions} = \@regions;
    # Picks made per region
    my $number_of_picks_per_region = $c->model('DBIC')->count_region_picks($player_id);
    $c->stash->{picks_per_region} = $number_of_picks_per_region;	
    # Number of Final 4 picks
    my $number_of_picks_per_final4 = $c->model('DBIC')->count_final4_picks($player_id);
    $c->stash->{picks_per_final4} = $number_of_picks_per_final4;	
	return;
}

sub account : Global {
	my ( $self, $c ) = @_;

	$c->stash( template => 'player/account.tt', );
}

=head2 all 

View of all players.  Includes links to players picks
and score/status.

=cut

sub all : Global {
	my ( $self, $c ) = @_;
	
	$c->stash->{template} = 'player/all_home.tt';

	my @players = $c->model('DBIC::Player')->search( { active => 1 } )->all;
	$c->stash->{players} = \@players;
	my @regions = $c->model('DBIC::Region')->search({},{order_by => 'id'})->all;
	$c->stash->{regions} = \@regions;

	if ($c->stash->{is_game_time}) {
      # Count of correct picks per player
      $c->stash->{correct_picks_per_player} = $c->model('DBIC')->count_player_picks_correct;
      $c->stash->{upset_picks_per_player} = $c->model('DBIC')->count_player_picks_upset;
	}
	else {
      # Count of picks already made per player
	    # This is useful to see overall pick status.
      $c->stash->{picks_per_player} = $c->model('DBIC')->count_player_picks;
	}


}


__PACKAGE__->meta->make_immutable;
1
