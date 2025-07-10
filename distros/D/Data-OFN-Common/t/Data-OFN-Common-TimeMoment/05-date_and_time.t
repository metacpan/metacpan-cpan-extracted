use strict;
use warnings;

use Data::OFN::Common::TimeMoment;
use DateTime;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Common::TimeMoment->new(
	'date_and_time' => DateTime->new(
		'day' => 26,
		'month' => 7,
		'year' => 2023,
		'hour' => 12,
		'minute' => 13,
		'second' => 0,
	),
);
my $data = $obj->date_and_time;
isa_ok($data, 'DateTime');
