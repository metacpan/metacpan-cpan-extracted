use strict;
use warnings;

use Data::OFN::Address;
use Data::Text::Simple;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::OFN::Address->new;
is_deeply(
	$obj->cadastral_area_name,
	[],
	'Get cadastral area name (reference to blank array - default).',
);

# Test.
$obj = Data::OFN::Address->new(
	'cadastral_area_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Katastrální území'),
		),
	],
);
isa_ok($obj->cadastral_area_name->[0], 'Data::Text::Simple');
is($obj->cadastral_area_name->[0]->lang, 'cs',
	'Get cadastral area name language (cs).');
is(
	$obj->cadastral_area_name->[0]->text,
	decode_utf8('Katastrální území'),
	decode_utf8('Get cadastral area name (Katastrální území).'),
);
