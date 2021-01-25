#!/usr/local/bin/perl5.10.0
use 5.010;

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Business::ISBN::Data;

my %data = Business::ISBN::Data->_get_data();

foreach my $isbn_prefix ("978", "979") {
	printf "\t%s => {\n", $isbn_prefix;
	foreach my $group ( sort { $a <=> $b } keys %{$data{$isbn_prefix}} ) {
		my $array = $data{$isbn_prefix}->{$group};
		my( $group_name, $ranges ) = @$array;

		$group_name =~ s/'/\\'/g;

		printf "\t\t%-5s => [ %s => [ ",
			$group,
			qq|'$group_name'|;
			;

		unless( @$ranges ) {
			print " ] ],\n";
			next;
		}

		@$ranges = map { qq('$_') } @$ranges;

		foreach my $i ( 0 .. $#$ranges - 1 ) {
			print $ranges->[$i], ( " => ", ", " )[$i % 2];
		}
		print $ranges->[-1], "] ],\n";
	}
	print "\t},\n";
}

