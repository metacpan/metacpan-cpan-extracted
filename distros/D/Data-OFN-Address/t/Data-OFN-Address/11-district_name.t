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
	$obj->district_name,
	[],
	'Get district name (reference to blank array - default).',
);

# Test.
$obj = Data::OFN::Address->new(
	'district_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Nový Jičín'),
		),
	],
);
isa_ok($obj->district_name->[0], 'Data::Text::Simple');
is($obj->district_name->[0]->lang, 'cs',
	'Get district name language (cs).');
is(
	$obj->district_name->[0]->text,
	decode_utf8('Nový Jičín'),
	'Get district name (Nový Jičín).',
);
