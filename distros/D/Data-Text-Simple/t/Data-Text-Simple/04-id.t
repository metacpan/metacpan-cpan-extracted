use strict;
use warnings;

use Data::Text::Simple;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Text::Simple->new(
	'text' => 'This is text.',
);
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::Text::Simple->new(
	'id' => 7,
	'lang' => 'en',
	'text' => 'This is text.',
);
is($obj->id, 7, 'Get id (7).');
