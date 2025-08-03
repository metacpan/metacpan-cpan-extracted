use strict;
use warnings;

use Test::More 'tests' => 20;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Company;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Test::Shared::Fixture::Data::InfoBox::Company->new;
my $ret_ar = $obj->items;
is(@{$ret_ar}, 6, 'Get number of items (6).');
isa_ok($ret_ar->[0], 'Data::InfoBox::Item');
is($ret_ar->[0]->text->text, decode_utf8('Volvox Globator'),
	'Get text of first item (Volvox Globator).');
is($ret_ar->[0]->uri, 'https://volvox.cz',
	'Get url of first item (https://volvox.cz).');
isa_ok($ret_ar->[1], 'Data::InfoBox::Item');
is($ret_ar->[1]->text->text, decode_utf8('Prvního pluku 211/5'),
	'Get text of second item (Prvního pluku 211/5).');
is($ret_ar->[1]->icon->char, decode_utf8('🏠'),
	'Get icon of second item (🏠).');
isa_ok($ret_ar->[2], 'Data::InfoBox::Item');
is($ret_ar->[2]->text->text, decode_utf8('Karlín'),
	'Get text of third item (Karlín).');
isa_ok($ret_ar->[3], 'Data::InfoBox::Item');
is($ret_ar->[3]->text->text, '18600 Praha 8',
	'Get text of fourth item (18600 Praha 8).');
isa_ok($ret_ar->[4], 'Data::InfoBox::Item');
is($ret_ar->[4]->icon->char, decode_utf8('✉'),
	'Get icon of fifth item (✉).');
is($ret_ar->[4]->text->text, 'volvox@volvox.cz',
	'Get text of fifth item (volvox@volvox.cz).');
is($ret_ar->[4]->uri, 'mailto:volvox@volvox.cz',
	'Get url of fifth item (mailto:volvox@volvox.cz).');
isa_ok($ret_ar->[5], 'Data::InfoBox::Item');
is($ret_ar->[5]->icon->char, decode_utf8('☎'),
	'Get icon of sixth item (☎).');
is($ret_ar->[5]->text->text, '+420739639506',
	'Get text of sixth item (+420739639506).');
is($ret_ar->[5]->uri, 'tel:+420739639506',
	'Get url of sixth item (tel:+420739639506).');
