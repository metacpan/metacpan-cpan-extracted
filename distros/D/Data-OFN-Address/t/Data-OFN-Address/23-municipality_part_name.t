use strict;
use warnings;

use Data::Text::Simple;
use Data::OFN::Address;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is_deeply($obj->municipality_part_name, [],
	'Get municipality part name (reference to blank array - default).');

# Test.
$obj = Data::OFN::Address->new(
	'municipality_part' => 'https://linked.cuzk.cz/resource/ruian/cast-obce/413551',
	'municipality_part_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => 'Fulnek',
		),
	],
);
isa_ok($obj->municipality_part_name->[0], 'Data::Text::Simple');
is($obj->municipality_part_name->[0]->lang, 'cs',
	'Get municipality part name language (cs).');
is(
	$obj->municipality_part_name->[0]->text,
	'Fulnek',
	'Get municipality part name (Fulnek).',
);
