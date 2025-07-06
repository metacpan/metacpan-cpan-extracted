use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::String;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Test::Shared::Fixture::Data::OFN::Address::String->new;
isa_ok($obj->text->[0], 'Data::Text::Simple');
is($obj->text->[0]->lang, 'cs',
	'Get text language (cs).');
is(
	$obj->text->[0]->text,
	decode_utf8('Pod Panskou strání 262/12, Chvojkonosy, 33205 Lysostírky'),
	'Get text (Pod Panskou strání 262/12, Chvojkonosy, 33205 Lysostírky).',
);
