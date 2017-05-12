use Test::More;
use Test::Deep;
use Ouch;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc';

my $calc = Box::Calc->new();

isa_ok $calc, 'Box::Calc';

my $box_type = $calc->add_box_type({
    x => 5,
    y => 7,
    z => 3,
    weight => 5,
    name => 'pizza',
});

isa_ok $box_type, 'Box::Calc::BoxType';
is $calc->count_box_types, 1, 'Added one box type to calc';

$calc->add_box_type({
    x => 1,
    y => 1,
    z => 1,
    weight => 2,
    name => 'unit',
});

is $calc->count_box_types, 2, 'Added another box type to calc';

my $sorted_box_types = $calc->sort_box_types_by_volume;

my @names = map { $_->name } @{ $sorted_box_types };

cmp_deeply \@names, [qw/unit pizza/], 'sorted box types by volume';

my $item = $calc->add_item(1,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);
isa_ok $item, 'Box::Calc::Item';
is $calc->count_items, 1, 'Added one item to calc';

$calc->add_item(2,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);
is $calc->count_items, 3, 'Added two more items to calc';

$calc->add_item(1,
    x => 9,
    y => 2,
    z => 1,
    name => 'big die',
    weight => 80,
);

$calc->add_item(1,
    x => 3,
    y => 3,
    z => 1,
    name => 'tank',
    weight => 9,
);

$calc->add_item(1,
    x => 2,
    y => 2,
    z => 2,
    name => 'octobox',
    weight => 5,
);

cmp_deeply $calc->find_max_dimensions_of_items, [9, 3, 2], 'find_max_dimensions_of_items';

my $sorted_items = $calc->sort_items_by_volume;

@names = map { $_->name } @{ $sorted_items };

cmp_deeply \@names, [('small die')x3, 'octobox', 'tank', 'big die'], 'sorted items by volume';

eval { $calc->determine_viable_box_types };
ok hug('no viable box types'), 'Exception thrown when no viable box types';

$calc->add_box_type(
    x => 12,
    y => 12,
    z => 12,
    weight => 20,
    name => 'square foot a',
    categories  => ['a'],
);


is scalar @{$calc->determine_viable_box_types}, 1, 'there is only one viable type';

$calc->add_box_type(
    x => 12,
    y => 12,
    z => 12,
    weight => 20,
    name => 'square foot b',
    categories  => ['b'],
);

is scalar @{$calc->determine_viable_box_types('b')}, 1, 'only one type b box';

$calc->add_box_type(
    x => 12,
    y => 12,
    z => 12,
    weight => 20,
    name => 'square foot ab',
    categories  => ['a','b'],
);

$calc->add_box_type(
    x => 12,
    y => 12,
    z => 12,
    weight => 20,
    name => 'square foot',
);

cmp_deeply  $calc->box_type_categories, ['a','b'], 'box_type_categories';

is scalar @{$calc->determine_viable_box_types}, 5, 'now there are 5 viable types, because of the category duplication';
is scalar @{$calc->determine_viable_box_types('a')}, 2, 'two type a boxes';
is scalar @{$calc->determine_viable_box_types('b')}, 2, 'two type b boxes';

my $dump1 = $calc->dump;
my $calc2 = Box::Calc->new;
$calc2->load($dump1);
my $dump2 = $calc2->dump;
cmp_deeply $dump1, $dump2, 'dump/load';



done_testing;
