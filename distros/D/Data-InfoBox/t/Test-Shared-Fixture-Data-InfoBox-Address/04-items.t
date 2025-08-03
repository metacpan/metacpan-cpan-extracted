use strict;
use warnings;

use Test::More 'tests' => 9;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Address;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Test::Shared::Fixture::Data::InfoBox::Address->new;
my $ret_ar = $obj->items;
is(@{$ret_ar}, 3, 'Get number of items (3).');
isa_ok($ret_ar->[0], 'Data::InfoBox::Item');
is($ret_ar->[0]->icon->char, decode_utf8('🏠'),
	'Get icon of first item (🏠).');
is($ret_ar->[0]->text->text, decode_utf8('Prvního pluku 211/5'),
	'Get text of first item (Prvního pluku 211/5).');
isa_ok($ret_ar->[1], 'Data::InfoBox::Item');
is($ret_ar->[1]->text->text, decode_utf8('Karlín'),
	'Get text of second item (Karlín).');
isa_ok($ret_ar->[2], 'Data::InfoBox::Item');
is($ret_ar->[2]->text->text, '18600 Praha 8',
	'Get text of third item (18600 Praha 8).');
