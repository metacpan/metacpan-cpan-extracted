use strict;
use warnings;

use Data::Image;
use DateTime;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new;
is($obj->dt_created, undef, 'Get dt_created (undef = default).');

# Test.
$obj = Data::Image->new(
	'author' => 'Zuzana Zonova',
	'dt_created' => DateTime->new(
		'day' => 14,
		'month' => 7,
		'year' => 2022,
	),
);
is($obj->dt_created, '2022-07-14T00:00:00', 'Get dt_created (2022-07-14T00:00:00).');
