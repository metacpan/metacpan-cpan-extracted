package Ascii::Text::Font;

use Moo;

sub default_character {
	my @char = ();
	for (1 .. $_[0]->character_height) {
		my @width = map { " " } 1 .. $_[1];
		push @char, \@width;
	}
	return @char;
}

1;
