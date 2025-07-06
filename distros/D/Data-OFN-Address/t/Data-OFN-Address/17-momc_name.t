use strict;
use warnings;

use Data::Text::Simple;
use Data::OFN::Address;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is_deeply($obj->momc_name, [], 'Get momc name (reference to blank array - default).');

# Test.
$obj = Data::OFN::Address->new(
	'momc' => 'https://linked.cuzk.cz/resource/ruian/momc/556904',
	'momc_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => 'Liberec',
		),
	],
);
isa_ok($obj->momc_name->[0], 'Data::Text::Simple');
is($obj->momc_name->[0]->lang, 'cs',
	'Get momc name language (cs).');
is(
	$obj->momc_name->[0]->text,
	'Liberec',
	'Get momc name (Liberec).',
);
