package Ascii::Text::Font;

use Rope;

function default_character => sub {
	my @char = ();
	for (1 .. $_[0]->character_height) {
		my @width = map { " " } 1 .. $_[1];
		push @char, \@width;
	}
	return @char;
};

1;
