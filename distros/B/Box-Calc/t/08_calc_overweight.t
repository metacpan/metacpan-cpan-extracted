use Test::More;
use Test::Deep;
use Ouch;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc';

my $calc = Box::Calc->new();

my $box_type = $calc->add_box_type({
    x => 3,
    y => 3,
    z => 3,
    weight => 6,
    max_weight => 15,
    name => 'holds 15',
});

is $box_type->max_weight, 15, 'can set a max weight';

$calc->add_box_type({
    x => 3,
    y => 3,
    z => 3,
    max_weight => 90,
    weight => 9,
    name => 'holds 90',
});

is $calc->count_box_types, 2, 'two box types';

$calc->add_item(3,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);

is $calc->count_items, 3, '7 items to pack';

$calc->pack_items();
is $calc->count_boxes, 1, 'only one box was used';
is $calc->get_box(-1)->name, 'holds 15', 'smallest box was used';
is $calc->get_box(-1)->max_weight, 15, 'max weight copied to box';

$calc->reset_boxes;

$calc->add_item(7,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);

$calc->pack_items();
is $calc->count_boxes, 1, 'only one box was used';
is $calc->get_box(-1)->fill_weight, 10, 'fill weight calculated correctly';
is $calc->get_box(-1)->calculate_weight, 25.3, 'weight calculated correctly';
is $calc->get_box(-1)->name, 'holds 90', 'largest box was used';

done_testing;
