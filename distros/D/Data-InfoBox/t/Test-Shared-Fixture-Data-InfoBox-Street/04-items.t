use strict;
use warnings;

use Test::More 'tests' => 8;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Street;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Test::Shared::Fixture::Data::InfoBox::Street->new;
my $ret_ar = $obj->items;
is(@{$ret_ar}, 3, 'Get number of items (3).');
isa_ok($ret_ar->[0], 'Data::InfoBox::Item');
is($ret_ar->[0]->text->text, decode_utf8('Nábřeží Rudoarmějců'),
	'Get text of first item (Nábřeží Rudoarmějců).');
isa_ok($ret_ar->[1], 'Data::InfoBox::Item');
is($ret_ar->[1]->text->text, decode_utf8('Příbor'),
	'Get text of first item (Příbor).');
isa_ok($ret_ar->[2], 'Data::InfoBox::Item');
is($ret_ar->[2]->text->text, decode_utf8('Česká republika'),
	'Get text of first item (Česká republika).');
