use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::Struct;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Test::Shared::Fixture::Data::OFN::Address::Struct->new;
isa_ok($obj->municipality_name->[0], 'Data::Text::Simple');
is($obj->municipality_name->[0]->lang, 'cs',
	'Get municipality name language (cs).');
is(
	$obj->municipality_name->[0]->text,
	decode_utf8('Horní Datová'),
	'Get municipality name (Horní Datová).',
);
