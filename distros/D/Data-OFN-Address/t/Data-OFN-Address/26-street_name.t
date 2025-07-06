use strict;
use warnings;

use Data::Text::Simple;
use Data::OFN::Address;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::OFN::Address->new;
is_deeply($obj->street_name, [], 'Get street name (reference to blank array - default).');

# Test.
$obj = Data::OFN::Address->new(
	'street' => 'https://linked.cuzk.cz/resource/ruian/ulice/309184',
	'street_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Bílovecká'),
		),
	],
);
isa_ok($obj->street_name->[0], 'Data::Text::Simple');
is($obj->street_name->[0]->lang, 'cs',
	'Get street name language (cs).');
is(
	$obj->street_name->[0]->text,
	decode_utf8('Bílovecká'),
	'Get street name (Bílovecká).',
);
