package Babble::Output::test;

use strict;
use Babble::Output;

sub output {
	my ($self, $babble) = @_;
	my $output;

	foreach my $item ($$babble->all ()) {
		$output .= "Title: " . $item->{title} . "\n";
	}

	return $output;
}

1;

# arch-tag: 2a2bc33e-b19b-4a57-98dd-1354a86b4a6f
