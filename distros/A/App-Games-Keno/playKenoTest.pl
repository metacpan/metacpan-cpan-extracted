use warnings;
use strict;
use lib 'lib';
use App::Games::Keno;
use feature 'say';

my $first_game = App::Games::Keno->new( num_spots => 5, draws => 1000 );
$first_game->PlayKeno;
say "You won \$"
  . $first_game->winnings . " on "
  . $first_game->draws
  . " draws.";

my $second_game = App::Games::Keno->new(
	spots => [ 45, 33, 12, 20 ],
	draws => 1000
);
$second_game->PlayKeno;
say "You won \$"
  . $second_game->winnings . " on "
  . $second_game->draws
  . " draws.";
