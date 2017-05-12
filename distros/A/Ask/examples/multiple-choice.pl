use 5.010;
use strict;
use warnings;
use Ask -all;

my $answer = single_choice(
	text    => "If a=1, b=2. What is a+b?",
	choices => [
		[ A => 12 ],
		[ B => 3  ],
		[ C => 2  ],
		[ D => 42 ],
		[ E => "Fish" ],
	],
);

if ($answer eq 'B') {
	info "Correctamundo!";
}

else {
	info "Wrong! ($answer)";
}

my @ingredients = multiple_choice(
	text    => "What do you want on your pizza?",
	choices => [
		[ cheese    => 'Cheese' ],
		[ tomato    => 'Tomato' ],
		[ ham       => 'Ham'    ],
		[ pineapple => 'Pineapple' ],
		[ chocolate => 'Chocolate' ],
	],
);

info "Making pizza dough";
info "Adding $_" for @ingredients;
error "Ooops! Dropped pizza on the floor! Sorry, no pizza for you!";
