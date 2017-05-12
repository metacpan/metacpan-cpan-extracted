use Test::More;
use Test::Deep;
use Ouch;

use lib '../lib';
use 5.010;

use Box::Calc;

my $calc = Box::Calc->new();

my $box_type = $calc->add_box_type({
    x => 5.5,
    y => 3.5,
    z => 1,
    weight => 1,
    name => 'smallpro',
});

my $poker_card = $calc->add_item(2,
    x => 2.5,
    y => 3.5,
    z => 0.0140,
    name => 'poker card',
    weight => 0.0576,
);

$calc->pack_items;

is $calc->count_boxes, 1, 'Only needed 1 box';
is $calc->get_box(-1)->count_layers, 1, 'Only needed 1 layer';

$calc->reset_boxes;
$calc->reset_items;

my $mini_card = $calc->add_item(4,
    x => 1.75,
    y => 2.5,
    z => 0.0140,
    name => 'poker card',
    weight => 0.0288,
);

$calc->pack_items;

is $calc->count_boxes, 1, 'Only needed 1 box';
is $calc->get_box(-1)->count_layers, 1, 'Only needed 1 layer';

done_testing;
