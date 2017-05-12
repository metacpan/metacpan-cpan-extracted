use Test::More;
use Test::Deep;

use lib '../lib';
use 5.010;
use strict;

use_ok 'Box::Calc::Box';

use Time::HiRes qw/gettimeofday tv_interval/;

my $t = [gettimeofday()];

my $box = Box::Calc::Box->new(x => 12, y => 12, z => 12, weight => 20, name => 'test');
my $box2 = Box::Calc::Box->new(x => 2, y => 3, z => 4, weight => 5, name => 'test2', outer_x => 3, outer_y => 4, outer_z => 5);
cmp_deeply $box2->outer_dimensions, [5,4,3], 'outer dimensions';

isa_ok $box, 'Box::Calc::Box';

is $box->x, 12, 'x defaults to largest';
is $box->y, 12, 'y defaults to 12';
is $box->z, 12, 'z defaults to smallest';
is $box->fill_x, '0.0000', 'fill_x 0';
is $box->fill_y, '0.0000', 'fill_y 0';
is $box->fill_z, '0.0000', 'fill_z 0';
is $box->name, 'test', 'overriding the default name';
is $box->calculate_weight, 34, 'taking box weight and void filler weight into account in weight calculations';

cmp_deeply $box->dimensions, [12,12,12], 'dimensions';
cmp_deeply $box->outer_dimensions, [12,12,12], 'outer dimensions same as inner dimensions when not specified';

is $box->count_layers, 1, 'A new box has a layer created automatically';
cmp_deeply $box->packing_instructions, {
          'calculated_weight' => 34,
          'fill_z' => '0.0000',
          'volume' => 1728,
          'used_volume' => '0',
          'name' => 'test',
          'x' => 12,
          'y' => 12,
          'fill_y' => '0.0000',
          'weight' => 20,
          'fill_x' => '0.0000',
          'id' => ignore(),
          'z' => 12,
          'layers' => [
                        {
                          'calculated_weight' => 0,
                          'fill_z' => '0.0000',
                          'fill_y' => '0.0000',
                          'fill_x' => '0.0000',
                          'rows' => [
                                      {
                                        'calculated_weight' => 0,
                                        'fill_z' => 0,
                                        'fill_y' => 0,
                                        'fill_x' => 0,
                                        'items' => []
                                      }
                                    ]
                        }
                      ]
        }, 'Empty packing list for an empty box';

can_ok($box, 'pack_item');

use Box::Calc::Item;
my $deck = Box::Calc::Item->new(x => 3.5, y => 2.5, z => 1, name => 'Deck', weight => 3);
my $tarot_deck = Box::Calc::Item->new(x => 4.75, y => 2.75, z => 1.25, name => 'Tarot Deck', weight => 4);
my $pawn = Box::Calc::Item->new(x => 1, y => 0.5, z => 0.5, name => 'Pawn', weight => 0.1);
my $die  = Box::Calc::Item->new(x => 0.75, y => 0.75, z => 0.75, name => 'Die', weight => 0.1);
my $mgbox = Box::Calc::Item->new(x => 8.75, y => 6.5, z => 1.25, name => 'Medium Game Box', weight => 6);
my $lgbox = Box::Calc::Item->new(x => 10.75, y => 10.75, z => 1.5, name => 'Large Game Box', weight => 12);

note 'Begin packing';
$box->pack_item($deck);
$box->pack_item($deck);
$box->pack_item($deck);
$box->pack_item($deck);
$box->pack_item($tarot_deck);
is $box->count_layers, 1, 'Still on one layer';
cmp_deeply $box->packing_instructions, {
          'calculated_weight' => 50,
          'fill_z' => '1.2500',
          'volume' => 1728,
          'used_volume' => '51.328125',
          'name' => 'test',
          'x' => 12,
          'y' => 12,
          'fill_y' => '5.2500',
          'weight' => 20,
          'fill_x' => '10.5000',
          'id' => ignore(),
          'z' => 12,
          'layers' => [
                        {
                          'calculated_weight' => 16,
                          'fill_z' => '1.2500',
                          'fill_y' => '5.2500',
                          'fill_x' => '10.5000',
                          'rows' => [
                                      {
                                        'calculated_weight' => 9,
                                        'fill_z' => 1,
                                        'fill_y' => 2.5,
                                        'fill_x' => 10.5,
                                        'items' => [
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     },
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     },
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     }
                                                   ]
                                      },
                                      {
                                        'calculated_weight' => 7,
                                        'fill_z' => 1.25,
                                        'fill_y' => 2.75,
                                        'fill_x' => 8.25,
                                        'items' => [
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     },
                                                     {
                                                       'y' => '2.75',
                                                       'weight' => 4,
                                                       'name' => 'Tarot Deck',
                                                       'x' => '4.75',
                                                       'z' => '1.25'
                                                     }
                                                   ]
                                      }
                                    ]
                        }
                      ]
        }, 'packing list before adding the large box';
$box->pack_item($lgbox); 

is $box->count_layers, 2, 'Added another layer';
is $box->fill_z, '2.7500', 'fill_z for two layers';
cmp_deeply $box->packing_instructions, {
          'calculated_weight' => 62,
          'fill_z' => '2.7500',
          'volume' => 1728,
          'used_volume' => '224.671875',
          'name' => 'test',
          'x' => 12,
          'y' => 12,
          'fill_y' => '10.7500',
          'weight' => 20,
          'fill_x' => '10.7500',
          'id' => ignore(),
          'z' => 12,
          'layers' => [
                        {
                          'calculated_weight' => 16,
                          'fill_z' => '1.2500',
                          'fill_y' => '5.2500',
                          'fill_x' => '10.5000',
                          'rows' => [
                                      {
                                        'calculated_weight' => 9,
                                        'fill_z' => 1,
                                        'fill_y' => 2.5,
                                        'fill_x' => 10.50,
                                        'items' => [
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     },
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     },
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     }
                                                   ]
                                      },
                                      {
                                        'calculated_weight' => 7,
                                        'fill_z' => 1.25,
                                        'fill_y' => 2.75,
                                        'fill_x' => 8.25,
                                        'items' => [
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     },
                                                     {
                                                       'y' => '2.75',
                                                       'weight' => 4,
                                                       'name' => 'Tarot Deck',
                                                       'x' => '4.75',
                                                       'z' => '1.25'
                                                     }
                                                   ]
                                      }
                                    ]
                        },
                        {
                          'calculated_weight' => 12,
                          'fill_z' => '1.5000',
                          'fill_y' => '10.7500',
                          'fill_x' => '10.7500',
                          'rows' => [
                                      {
                                        'calculated_weight' => 12,
                                        'fill_z' => 1.5,
                                        'fill_y' => 10.75,
                                        'fill_x' => 10.75,
                                        'items' => [
                                                     {
                                                       'y' => '10.75',
                                                       'weight' => 12,
                                                       'name' => 'Large Game Box',
                                                       'x' => '10.75',
                                                       'z' => '1.5'
                                                     }
                                                   ]
                                      }
                                    ]
                        }
                      ]
        }, 'packing list, showing two layers';

foreach (1..6) {
    $box->pack_item($lgbox);
}
is $box->count_layers, 8, 'Added eight layers';
is $box->fill_z, '11.7500', 'fill_z for 8 layers';
cmp_deeply $box->packing_instructions,  {
          'calculated_weight' => 134,
          'fill_z' => '11.7500',
          'volume' => 1728,
          'used_volume' => '1264.734375',
          'name' => 'test',
          'x' => 12,
          'y' => 12,
          'fill_y' => '10.7500',
          'weight' => 20,
          'fill_x' => '10.7500',
          'id' => ignore(),
          'z' => 12,
          'layers' => [
                        {
                          'calculated_weight' => 16,
                          'fill_z' => '1.2500',
                          'fill_y' => '5.2500',
                          'fill_x' => '10.5000',
                          'rows' => [
                                      {
                                        'calculated_weight' => 9,
                                        'fill_z' => 1,
                                        'fill_y' => 2.5,
                                        'fill_x' => 10.5,
                                        'items' => [
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     },
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     },
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     }
                                                   ]
                                      },
                                      {
                                        'calculated_weight' => 7,
                                        'fill_z' => 1.25,
                                        'fill_y' => 2.75,
                                        'fill_x' => 8.25,
                                        'items' => [
                                                     {
                                                       'y' => '2.5',
                                                       'weight' => 3,
                                                       'name' => 'Deck',
                                                       'x' => '3.5',
                                                       'z' => 1
                                                     },
                                                     {
                                                       'y' => '2.75',
                                                       'weight' => 4,
                                                       'name' => 'Tarot Deck',
                                                       'x' => '4.75',
                                                       'z' => '1.25'
                                                     }
                                                   ]
                                      }
                                    ]
                        },
                        {
                          'calculated_weight' => 12,
                          'fill_z' => '1.5000',
                          'fill_y' => '10.7500',
                          'fill_x' => '10.7500',
                          'rows' => [
                                      {
                                        'calculated_weight' => 12,
                                        'fill_z' => 1.5,
                                        'fill_y' => 10.75,
                                        'fill_x' => 10.75,
                                        'items' => [
                                                     {
                                                       'y' => '10.75',
                                                       'weight' => 12,
                                                       'name' => 'Large Game Box',
                                                       'x' => '10.75',
                                                       'z' => '1.5'
                                                     }
                                                   ]
                                      }
                                    ]
                        },
                        {
                          'calculated_weight' => 12,
                          'fill_z' => '1.5000',
                          'fill_y' => '10.7500',
                          'fill_x' => '10.7500',
                          'rows' => [
                                      {
                                        'calculated_weight' => 12,
                                        'fill_z' => 1.5,
                                        'fill_y' => 10.75,
                                        'fill_x' => 10.75,
                                        'items' => [
                                                     {
                                                       'y' => '10.75',
                                                       'weight' => 12,
                                                       'name' => 'Large Game Box',
                                                       'x' => '10.75',
                                                       'z' => '1.5'
                                                     }
                                                   ]
                                      }
                                    ]
                        },
                        {
                          'calculated_weight' => 12,
                          'fill_z' => '1.5000',
                          'fill_y' => '10.7500',
                          'fill_x' => '10.7500',
                          'rows' => [
                                      {
                                        'calculated_weight' => 12,
                                        'fill_z' => 1.5,
                                        'fill_y' => 10.75,
                                        'fill_x' => 10.75,
                                        'items' => [
                                                     {
                                                       'y' => '10.75',
                                                       'weight' => 12,
                                                       'name' => 'Large Game Box',
                                                       'x' => '10.75',
                                                       'z' => '1.5'
                                                     }
                                                   ]
                                      }
                                    ]
                        },
                        {
                          'calculated_weight' => 12,
                          'fill_z' => '1.5000',
                          'fill_y' => '10.7500',
                          'fill_x' => '10.7500',
                          'rows' => [
                                      {
                                        'calculated_weight' => 12,
                                        'fill_z' => 1.5,
                                        'fill_y' => 10.75,
                                        'fill_x' => 10.75,
                                        'items' => [
                                                     {
                                                       'y' => '10.75',
                                                       'weight' => 12,
                                                       'name' => 'Large Game Box',
                                                       'x' => '10.75',
                                                       'z' => '1.5'
                                                     }
                                                   ]
                                      }
                                    ]
                        },
                        {
                          'calculated_weight' => 12,
                          'fill_z' => '1.5000',
                          'fill_y' => '10.7500',
                          'fill_x' => '10.7500',
                          'rows' => [
                                      {
                                        'calculated_weight' => 12,
                                        'fill_z' => 1.5,
                                        'fill_y' => 10.75,
                                        'fill_x' => 10.75,
                                        'items' => [
                                                     {
                                                       'y' => '10.75',
                                                       'weight' => 12,
                                                       'name' => 'Large Game Box',
                                                       'x' => '10.75',
                                                       'z' => '1.5'
                                                     }
                                                   ]
                                      }
                                    ]
                        },
                        {
                          'calculated_weight' => 12,
                          'fill_z' => '1.5000',
                          'fill_y' => '10.7500',
                          'fill_x' => '10.7500',
                          'rows' => [
                                      {
                                        'calculated_weight' => 12,
                                        'fill_z' => 1.5,
                                        'fill_y' => 10.75,
                                        'fill_x' => 10.75,
                                        'items' => [
                                                     {
                                                       'y' => '10.75',
                                                       'weight' => 12,
                                                       'name' => 'Large Game Box',
                                                       'x' => '10.75',
                                                       'z' => '1.5'
                                                     }
                                                   ]
                                      }
                                    ]
                        },
                        {
                          'calculated_weight' => 12,
                          'fill_z' => '1.5000',
                          'fill_y' => '10.7500',
                          'fill_x' => '10.7500',
                          'rows' => [
                                      {
                                        'calculated_weight' => 12,
                                        'fill_z' => 1.5,
                                        'fill_y' => 10.75,
                                        'fill_x' => 10.75,
                                        'items' => [
                                                     {
                                                       'y' => '10.75',
                                                       'weight' => 12,
                                                       'name' => 'Large Game Box',
                                                       'x' => '10.75',
                                                       'z' => '1.5'
                                                     }
                                                   ]
                                      }
                                    ]
                        }
                      ]
        }, 'packing list, showing multiple layers';


my ($weight, $list) = $box->packing_list;

cmp_deeply $list, {Deck => 4, 'Tarot Deck' => 1, 'Large Game Box' => 7}, 'packing list correlates to packing instructions';



ok !$box->pack_item($lgbox), 'Caught Z too big exception';

note tv_interval($t);

done_testing;

