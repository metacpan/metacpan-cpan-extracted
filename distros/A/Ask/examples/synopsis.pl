use 5.010;
use Ask;

my $ask = Ask->detect;
if ($ask->question(text => "Are you happy?")
and $ask->question(text => "Do you know it?")
and $ask->question(text => "Really want to show it?")) {
	$ask->info(text => "Then clap your hands!");
}
