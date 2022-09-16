use warnings;
use strict;
use lib 'lib';
use App::Games::Keno;
use feature 'say';

my ( $num_spots, $draws, $verbose ) = @ARGV;

my $first_game = App::Games::Keno->new(
	num_spots => $num_spots,
	draws     => $draws,
	verbose => $verbose
);
$first_game->PlayKeno;
my $net_gain   = $draws - $first_game->winnings;
my $net_gain_d = commify( abs($net_gain) );
my $winnings   = commify( $first_game->winnings );
my $draws_d    = commify($draws);
say "You won \$$winnings on $draws_d draws.";
if ( $net_gain > 0 ) {
	say "That's a loss of \$$net_gain_d";
}
else {
	say "You came out ahead by \$$net_gain_d";
}

sub commify {
	my $text = reverse $_[0];
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
}
