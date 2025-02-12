use strict;
use warnings;

use Test::More 'tests' => 10;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Items;

# Test.
my $obj = Test::Shared::Fixture::Data::InfoBox::Items->new;
my $ret_ar = $obj->items;
is(@{$ret_ar}, 4, 'Get number of items (4).');
isa_ok($ret_ar->[0], 'Data::InfoBox::Item');
is($ret_ar->[0]->text->text, 'Create project',
	'Get text of first item (Create project).');
isa_ok($ret_ar->[1], 'Data::InfoBox::Item');
is($ret_ar->[1]->text->text, 'Present project',
	'Get text of second item (Preset project).');
isa_ok($ret_ar->[2], 'Data::InfoBox::Item');
is($ret_ar->[2]->text->text, 'Add money to project',
	'Get text of third item (Add money to project).');
isa_ok($ret_ar->[3], 'Data::InfoBox::Item');
is($ret_ar->[3]->text->text, 'Finish project',
	'Get text of fourth item (Finish project).');
