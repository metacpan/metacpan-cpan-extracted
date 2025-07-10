use strict;
use warnings;

use Data::OFN::Common::TimeMoment;
use DateTime;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Common::TimeMoment->new(
	'date' => DateTime->new(
		'day' => 26,
		'month' => 7,
		'year' => 2023,
	),
);
my $ret = $obj->date;
isa_ok($ret, 'DateTime');
