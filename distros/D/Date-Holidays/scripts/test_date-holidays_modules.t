# $Id$

use strict;
use Date::Holidays;
use Test::More tests => 24;

my $verbose = 1;
my $t = 1;

#Adding a country adds 3 tests
my @countrycodes = qw(dk no uk fr pt nz au de); #jp left out



foreach my $cc (@countrycodes) {

	print STDERR "\n[$t]: Testing country code: $cc\n" if $verbose;
	my $dh = Date::Holidays->new(
		countrycode => $cc,
	);
	ok(ref $dh); #tests 1, 4, 7, 10, 13, 16
	$t++;
	
	#test 2, 5, 8, 11, 14, 17
	print STDERR "\n[$t]: Testing holidays for: $cc\n" if $verbose;
	ok($dh->holidays(
		year => 2004
	));
	$t++;

	#test 3, 6, 9, 12, 15, 18
	print STDERR "\n[$t]: Testing is_holiday for: $cc\n" if $verbose;
	ok($dh->is_holiday(
		year  => 2004,
		month => 1,
		day   => 1
	));
	$t++;
}
