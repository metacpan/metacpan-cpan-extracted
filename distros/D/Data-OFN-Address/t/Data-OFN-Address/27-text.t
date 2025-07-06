use strict;
use warnings;

use Data::Text::Simple;
use Data::OFN::Address;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::OFN::Address->new;
is_deeply($obj->text, [], 'Get street name (reference to blank array - default).');

# Test.
$obj = Data::OFN::Address->new(
	'text' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Bílovecká 386, 74245 Fulnek'),
		),
	],
);
isa_ok($obj->text->[0], 'Data::Text::Simple');
is($obj->text->[0]->lang, 'cs',
	'Get text language (cs).');
is(
	$obj->text->[0]->text,
	decode_utf8('Bílovecká 386, 74245 Fulnek'),
	'Get text (Bílovecká 386, 74245 Fulnek).',
);
