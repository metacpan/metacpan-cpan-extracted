use strict;
use warnings;

use Data::Navigation::Item;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Navigation::Item->new(
	'title' => 'Title',
);
is($obj->location, undef, 'Get location (undef - default).');

# Test.
$obj = Data::Navigation::Item->new(
	'location' => 'http://example.com',
	'title' => 'Title',
);
is($obj->location, 'http://example.com', 'Get location (http://example.com).');
