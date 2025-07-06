use strict;
use warnings;

use Data::Text::Simple;
use Data::OFN::Address;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is_deeply($obj->municipality_name, [], 'Get municipality name (reference to blank array - default).');

# Test.
$obj = Data::OFN::Address->new(
	'municipality' => 'https://linked.cuzk.cz/resource/ruian/obec/599352',
	'municipality_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => 'Fulnek',
		),
	],
);
isa_ok($obj->municipality_name->[0], 'Data::Text::Simple');
is($obj->municipality_name->[0]->lang, 'cs',
	'Get municipality name language (cs).');
is(
	$obj->municipality_name->[0]->text,
	'Fulnek',
	'Get municipality name (Fulnek).',
);
