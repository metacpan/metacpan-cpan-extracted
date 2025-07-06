use strict;
use warnings;

use Test::Shared::Fixture::Data::OFN::Address::Struct;
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Test::Shared::Fixture::Data::OFN::Address::Struct->new;
isa_ok($obj->street_name->[0], 'Data::Text::Simple');
is($obj->street_name->[0]->lang, 'cs',
	'Get street name language (cs).');
is(
	$obj->street_name->[0]->text,
	decode_utf8('Hlavní'),
	'Get street name (Hlavní).',
);
