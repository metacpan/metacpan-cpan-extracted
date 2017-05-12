use Test::More;
use Test::Deep;
use Ouch;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc';

my $calc = Box::Calc->new();

isa_ok $calc, 'Box::Calc';

my $box_type = $calc->add_box_type({
    x => 5.5,
    y => 3.5,
    z => 1,
    weight => 3,
    name => 'small pro box',
});

$calc->add_box_type({
    x => 8.2,
    y => 4.7,
    z => 1.25,
    weight => 6,
    name => 'medium pro box',
});

my $item = $calc->add_item(50,
    x => 3.5,
    y => 3.5,
    z => 0.015,
    name => 'square card',
    weight => 0.01,
);

$calc->add_item(2,
    x => 0.5,
    y => 0.5,
    z => 0.5,
    name => 'd6',
    weight => 1,
);

$calc->add_item(3,
    x => 0.5,
    y => 0.25,
    z => 0.35,
    name => 'rice resource',
    weight => 0.1,
);

is $calc->find_tallest_z, 0.5, 'tallest z';

is scalar(@{$calc->stack_like_items}), 6, 'from 55 down to 6';

my $items = $calc->sort_items_by_zA( $calc->stack_like_items );

$calc->pack_items(items => $items );

is $calc->count_boxes, 1, 'only one box was used';
is $calc->get_box(-1)->name, 'small pro box', 'smallest box was used';

done_testing;
