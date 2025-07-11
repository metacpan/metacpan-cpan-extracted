use strict;
use warnings;

use Data::OFN::Thing;
use Data::Text::Simple;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Thing->new;
is_deeply(
	$obj->description,
	[],
	'Get descriptions ([] - default).',
);

# Test.
$obj = Data::OFN::Thing->new(
	'description' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => 'Toto je popis',
		),
		Data::Text::Simple->new(
			'lang' => 'en',
			'text' => 'This is description',
		),
	],
);
isa_ok($obj->description->[0], 'Data::Text::Simple');
isa_ok($obj->description->[1], 'Data::Text::Simple');
