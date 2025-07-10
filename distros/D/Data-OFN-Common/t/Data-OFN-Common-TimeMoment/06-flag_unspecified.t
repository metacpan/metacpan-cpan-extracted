use strict;
use warnings;

use Data::OFN::Common::TimeMoment;
use DateTime;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Common::TimeMoment->new(
	'flag_unspecified' => 1,
);
is($obj->flag_unspecified, 1, 'Flag unspecified (1).');

# Test.
$obj = Data::OFN::Common::TimeMoment->new(
	'date' => DateTime->new(
		'day' => 26,
		'month' => 7,
		'year' => 2023,
	),
	'flag_unspecified' => 0,
);
is($obj->flag_unspecified, 0, 'Flag unspecified (0).');

# Test.
$obj = Data::OFN::Common::TimeMoment->new(
	'date' => DateTime->new(
		'day' => 26,
		'month' => 7,
		'year' => 2023,
	),
);
is($obj->flag_unspecified, 0, 'Flag unspecified (0 - default).');
