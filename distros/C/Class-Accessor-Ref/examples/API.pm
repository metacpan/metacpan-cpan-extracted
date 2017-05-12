# example of a library that expects in-out variables in calls.
package API;
use strict;

use vars qw(%colors %rev_colors);

%colors = (
	Black  => [ qw(night cave) ],
	Red    => [ qw(blood ferrari sexy strawberry) ],
	Blue   => [ qw(ocean sky) ],
	Orange => [ qw(sunset cpan orange) ],
	Green  => [ qw(envy forest grape) ],
	Brown  => [ qw(coconut) ],
);

foreach my $color (keys %colors) {
	foreach my $hint (@{ $colors{$color} }) {
		warn "conflicting hints for color!" if exists $rev_colors{$hint};
		$rev_colors{$hint} = $color;
	}
}

# find the color of something based on hints about what it looks like.
# return true if an educated guess was found, false otherwise.
# The color is set into the first argument (which is expected to hold
# a reference to an exiting scalar).

sub find_color_by_hints {
	my($r_color, @hints) = @_;
	my %guesses;
	HINT: foreach my $hint (@hints) {
		my $guess = $rev_colors{$hint} or next HINT;
		$guesses{$guess}++;
	}
	# find highest scoring color (or random best guess if several found)
	my %rev_guesses = reverse %guesses;
	my $best = max_list([keys %rev_guesses]) or return;
	$$r_color = $rev_guesses{$best};
	return 1;
}

sub max_list {
	my $listref = shift;
	my $greatest = 0;
	do { $greatest = $_ if $_ > $greatest } for @$listref;
	return $greatest;
}

1;
