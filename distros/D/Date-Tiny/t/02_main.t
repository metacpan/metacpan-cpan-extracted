#!/usr/bin/perl

# Testing for Date::Tiny

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;	
}

use Test::More tests => 19;
use Date::Tiny;





#####################################################################
# Basic Tests

SCOPE: {
	# Normal date
	my $date = Date::Tiny->new(
		year  => 2006,
		month => 12,
		day   => 31,
	);
	isa_ok( $date, 'Date::Tiny' );
	is( $date->year,  2006, '->year ok'  );
	is( $date->month, 12,   '->month ok' );
	is( $date->day,   31,   '->day ok'   );

	# Current date
	my $now = Date::Tiny->now;
	isa_ok( $date, 'Date::Tiny' );
	ok( $now->year =~ /^\d\d\d\d$/, '->year ok' );
	ok( $now->month =~ /^(?:1|2|3|4|5|6|7|8|9|10|11|12)$/, '->month ok' );
	ok( $now->day =~ /^(?:1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)$/, '->day ok' );		
}





#####################################################################
# DateTime Testing

SKIP: {
	# Do we have DateTime
	eval { require DateTime };
	skip( "Skipping DateTime tests (not installed)", 7 ) if $@;

	# Create a normal date
	my $date = Date::Tiny->new(
		year  => 2006,
		month => 1,
		day   => 31,
	);
	isa_ok( $date, 'Date::Tiny' );

	# Expand to a DateTime
	my $dt = $date->DateTime;
	# DateTime::Locale version 1.00 changes "C" to "en-US-POSIX".
	my $expected = eval { DateTime::Locale->VERSION(1) } ? "en-US-POSIX" : "C";
	is( $dt->locale->id,      $expected,  '->locale ok'   );
	isa_ok( $dt, 'DateTime' );
	is( $dt->time_zone->name, 'floating', '->timezone ok' );

	# Compare accessor results
	is( $date->year,  $dt->year,  '->year matches'  );
	is( $date->month, $dt->month, '->month matches' );
	is( $date->day,   $dt->day,   '->day matches'   );
}

# Testing from_string
SCOPE: {
	my $date = Date::Tiny->from_string( '2006-01-31' );
        isa_ok( $date, 'Date::Tiny' );
	is( $date->year, 2006, '->year ok' );
	is( $date->month, 1, '->month ok' );
	is( $date->day, 31, '->day ok' );
}
