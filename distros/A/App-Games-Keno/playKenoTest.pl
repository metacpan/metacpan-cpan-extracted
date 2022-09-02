use v5.36;
use lib 'lib';
use App::Games::Keno;

my $first_game = App::Games::Keno->new( num_spots => 5, draws => 1000 );
$first_game->PlayKeno;
say "You won \$"
  . $first_game->winnings . " on "
  . $first_game->draws
  . " draws.";

my $second_game = App::Games::Keno->new(
	spots => [ 45, 33, 12, 20, 75 ],
	draws => 1000
);
$second_game->PlayKeno;
say "You won \$"
  . $second_game->winnings . " on "
  . $second_game->draws
  . " draws.";
