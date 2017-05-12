use Test::More;
use Test::Deep;
use Ouch;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc';

my $calc = Box::Calc->new();

##Example Game - Pixel Quest
# 70 Circle shards
# 12 poker cards
# 1 MGB
# Failure is that it takes more than 1 Virtual Box.
# Probably related to stacking?

my $box_type = $calc->add_box_type({
    x => 2.5,
    y => 3.5,
    z => 0.81,
    weight => 0.256,
    name => 'poker tuck box 54',
});

my $item = $calc->add_item(108,
    x => 1.75,
    y => 2.5,
    z => 0.015,
    name => 'Mini Card',
    weight => 0.0045,
);

$calc->pack_items();
note "This test was built because a poker tuck box 54 wouldn't hold 108 mini cards";
is $calc->count_boxes, 1, 'only one box was used';
is $calc->get_box(-1)->name, 'poker tuck box 54', 'tuck box was used';

done_testing;
