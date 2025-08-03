use strict;
use warnings;

use Test::More 'tests' => 9;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Person;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Test::Shared::Fixture::Data::InfoBox::Person->new;
my $ret_ar = $obj->items;
is(@{$ret_ar}, 2, 'Get number of items (2).');
isa_ok($ret_ar->[0], 'Data::InfoBox::Item');
is($ret_ar->[0]->icon->char, decode_utf8('🧍'),
	'Get icon of first item (🧍).');
is($ret_ar->[0]->text->text, decode_utf8('Michal Josef Špaček'),
	'Get text of first item (Michal Josef Špaček).');
isa_ok($ret_ar->[1], 'Data::InfoBox::Item');
is($ret_ar->[1]->icon->char, decode_utf8('☎'),
	'Get icon of first item (☎).');
is($ret_ar->[1]->text->text, '+420777623160',
	'Get text of second item (+420777623160).');
is($ret_ar->[1]->uri, 'tel:+420777623160',
	'Get uri of second item (tel:+420777623160).');
