use strict;
use warnings;

use Data::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new;
is($obj->comment, undef, 'Get comment (undef - default value).');

# Test.
$obj = Data::Image->new(
	'comment' => 'Michal from Czechia',
);
is($obj->comment, 'Michal from Czechia', 'Get comment (Michal from Czechia)');
