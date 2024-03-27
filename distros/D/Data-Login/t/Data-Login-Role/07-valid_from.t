use strict;
use warnings;

use Data::Login::Role;
use DateTime;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Login::Role->new(
	'role' => 'admin',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
);
isa_ok($obj->valid_from, 'DateTime');
is($obj->valid_from->ymd, '2024-01-01', 'Get valid from (2024-01-01).');
