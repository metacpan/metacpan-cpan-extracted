use strict;
use warnings;

use Data::Commons::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->license, undef, 'Get license (undef - default value).');

# Test.
$obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
	'license' => 'cc-by-sa-4.0',
);
is($obj->license, 'cc-by-sa-4.0', 'Get license (cc-by-sa-4.0)');
