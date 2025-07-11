use strict;
use warnings;

use Data::OFN::Thing;
use Data::Text::Simple;
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::OFN::Thing->new;
is_deeply(
	$obj->name,
	[],
	'Get names ([] - default).',
);

# Test.
$obj = Data::OFN::Thing->new(
	'name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Jméno'),
		),
		Data::Text::Simple->new(
			'lang' => 'en',
			'text' => 'Name',
		),
	],
);
isa_ok($obj->name->[0], 'Data::Text::Simple');
isa_ok($obj->name->[1], 'Data::Text::Simple');
