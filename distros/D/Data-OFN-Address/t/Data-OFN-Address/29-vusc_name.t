use strict;
use warnings;

use Data::Text::Simple;
use Data::OFN::Address;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::OFN::Address->new;
is_deeply($obj->vusc_name, [], 'Get street name (reference to blank array - default).');

# Test.
$obj = Data::OFN::Address->new(
	'vusc' => 'https://linked.cuzk.cz/resource/ruian/vusc/132',
	'vusc_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Moravskoslezský kraj'),
		),
	],
);
isa_ok($obj->vusc_name->[0], 'Data::Text::Simple');
is($obj->vusc_name->[0]->lang, 'cs',
	'Get vusc name language (cs).');
is(
	$obj->vusc_name->[0]->text,
	decode_utf8('Moravskoslezský kraj'),
	'Get vusc name (Moravskoslezský kraj).',
);
