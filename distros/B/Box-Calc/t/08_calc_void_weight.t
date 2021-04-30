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
    void_weight => 2,
});

$calc->add_item(3,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);


$calc->pack_items();
is $calc->count_boxes, 1, 'only one box was used';
is $calc->get_box(-1)->void_weight, 2, 'void weight set to 2';
is $calc->get_box(-1)->fill_weight, 3, 'fill weight calculated correctly';
is $calc->get_box(-1)->calculate_weight, 11, 'weight calculated correctly';

done_testing;
