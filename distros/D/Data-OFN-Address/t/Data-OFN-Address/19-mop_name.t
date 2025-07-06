use strict;
use warnings;

use Data::Text::Simple;
use Data::OFN::Address;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Address->new;
is_deeply($obj->mop_name, [], 'Get mop name (reference to blank array - default).');

# Test.
$obj = Data::OFN::Address->new(
	'mop' => 'https://linked.cuzk.cz/resource/ruian/mop/60',
	'mop_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => 'Praha 6',
		),
	],
);
isa_ok($obj->mop_name->[0], 'Data::Text::Simple');
is($obj->mop_name->[0]->lang, 'cs',
	'Get mop name language (cs).');
is(
	$obj->mop_name->[0]->text,
	'Praha 6',
	'Get mop name (Praha 6).',
);
