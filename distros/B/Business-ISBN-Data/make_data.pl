#!/usr/local/bin/perl5.10.0
use 5.010;

use strict;
use warnings;

use lib qw(lib);

use Business::ISBN::Data;

my %data = Business::ISBN::Data->_get_data();

foreach my $group ( sort { $a <=> $b } keys %data ) {
	next if $group =~ /\A_/;

	my $array = $data{$group};
	my( $group_name, $ranges ) = @$array;
	
	$group_name =~ s/'/\\'/g;

	printf "%-5s => [ %s => [ ",
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

#     0 => ['English',               ['00' => '19', '200' => '699', '7000' => '8499', '85000' => '89999', '900000' => '949999', '9500000' => '9999999' ] ],
