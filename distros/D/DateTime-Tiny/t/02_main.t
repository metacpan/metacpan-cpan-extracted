#!/usr/bin/perl

# Testing for DateTime::Tiny

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;	
}

use Test::More tests => 32;
use DateTime::Tiny;
use utf8;





#####################################################################
# Basic Tests

SCOPE: {
	# Normal date
	my $date = DateTime::Tiny->new(
		year  => 2006,
		month => 12,
		day   => 31,
	);
	isa_ok( $date, 'DateTime::Tiny' );
	is( $date->year,  2006, '->year ok'   );
	is( $date->month, 12,   '->month ok'  );
	is( $date->day,   31,   '->day ok'    );
	is( $date->hour,   0,   '->hour ok'   );
	is( $date->minute, 0,   '->minute ok' );
	is( $date->second, 0,   '->second ok' );

	# Current date
	my $now = DateTime::Tiny->now;
	isa_ok( $date, 'DateTime::Tiny' );
	ok( $now->year =~ /^\d\d\d\d$/, '->year ok' );
	ok( $now->month =~ /^(?:1|2|3|4|5|6|7|8|9|10|11|12)$/, '->month ok' );
	ok( $now->day =~ /^(?:1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)$/, '->day ok' );		

	# Stringification
	is( $date->as_string, '2006-12-31T00:00:00', '->as_string ok' );
	is( "$date", '2006-12-31T00:00:00', 'Stringification ok' );
	is_deeply(
		DateTime::Tiny->from_string( $date->as_string ),
		$date, '->from_string ok',
	);

}





#####################################################################
# DateTime Testing

SKIP: {
	# Do we have DateTime
	eval { require DateTime };
	skip( "Skipping DateTime tests (not installed)", 10 ) if $@;

	# Create a normal date
	my $date = DateTime::Tiny->new(
		year   => 2006,
		month  => 1,
		day    => 31,
		hour   => 3,
		minute => 20,
		second => 30,
	);
	isa_ok( $date, 'DateTime::Tiny' );

	# Expand to a DateTime
	my $dt = $date->DateTime;
	isa_ok( $dt, 'DateTime' );
	# DateTime::Locale version 1.00 changes "C" to "en-US-POSIX".
	# And version 1.33 changes to "en-US".
	my %expected = map { $_ => 1 } qw(C en-US-POSIX en-US);
	ok( $expected{ $dt->locale->id }, '->locale ok' );
	is( $dt->time_zone->name, 'floating', '->timezone ok' );

	# Compare accessor results
	is( $date->year,   $dt->year,   '->year matches'  );
	is( $date->month,  $dt->month,  '->month matches' );
	is( $date->day,    $dt->day,    '->day matches'   );
	is( $date->hour,   $dt->hour,   '->hour matches'  );
	is( $date->minute, $dt->minute, '->minute matches' );
	is( $date->second, $dt->second, '->second matches' );
}





#####################################################################
# Time::Tiny emulation

SCOPE: {
	my $tiny = DateTime::Tiny->new(
		hour   => 1,
		minute => 2,
		second => 3,
	);
	isa_ok( $tiny, 'DateTime::Tiny' );
	is( $tiny->hour,  '1', '->hour ok'   );
	is( $tiny->minute, 2,  '->minute ok' );
	is( $tiny->second, 3,  '->second ok' );
	is( $tiny->as_string,  '1970-01-01T01:02:03', '->as_string ok' );
	is( "$tiny", '1970-01-01T01:02:03', 'Stringification ok' );
	is_deeply(
		DateTime::Tiny->from_string( $tiny->as_string ),
		$tiny, '->from_string ok',
	);
}

SCOPE: {
    eval { DateTime::Tiny->from_string('୭୮୯௦-௧௨-௩௪T௫௬:௭௮:௯౦') };
    my $error = $@;
    like $error, qr/\QInvalid time format (does not match ISO 8601)/,
      'Only ASCII digits are valid in datetime strings';
}
