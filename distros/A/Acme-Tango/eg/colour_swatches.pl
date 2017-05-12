#!/usr/bin/perl

# Creates a set of HTML colour swatches to show
# what Acme::Tango does.

use strict;
use warnings;
use Acme::Tango;

my $i=0;
my @colors;

while (1) {
	my $p = permutation( $i++, 3, [qw( 00 33 66 99 CC FF )] );
	if ( defined $p ) {
		push(@colors, $p);
	} else {
		last;
	}
}


print qq!<html><head><title>Acme::Tango Example</title></head><body>\n<table bgcolor = '#000000'><tr>!;

for my $flavour (qw(orange lemon apple blackcurrant cherry)) {

	print "\n<td><h3><font color = '#ffffff'>".ucfirst($flavour)."</font></h3><table>\n";

	for my $color (@colors) {
		# Tango it
		my $new_color = Acme::Tango::drink($color, $flavour);

		# Print out a line with it
		print qq!<tr><td bgcolor = "#$color">$color</td><td bgcolor = "#$new_color">$new_color</td></tr>!;
	}

	print "</table></td>";

}

print qq!\n</tr></table></body></html>\n!;

sub permutation {
	my ( $desired_permutation, $column_count, $permutation_set ) = @_;
	my $permutation_set_count = @$permutation_set;

	# The total number of permutations
	my $total_permutations = $permutation_set_count ** $column_count;

	# Return if we're being asked for a permutation outside the total number
	# possible
	return if $desired_permutation >= $total_permutations;

	# Calculate the desired_permutation in base x where x = $permutations_set_count
	my $num  = $desired_permutation;
	my $base = $permutation_set_count;

	my $s = [];

	while (1) {
		my $r = $num % $base;
		unshift( @$s, $r );
		$num = int($num / $base);
		last if $num == 0;
	}

	while ( @$s < $column_count ) {
		unshift( @$s, 0 );
	}

	# @$s is now a list corresponding to the permutation, where each number is
	# an index of the permutation set

	# Now we build the permutation by substituting those for the set
	return join '', map { $permutation_set->[$_] } @$s;
}
