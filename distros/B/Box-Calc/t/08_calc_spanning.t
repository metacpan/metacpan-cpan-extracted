use Test::More;
use Test::Deep;
use Ouch;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc';

my $calc = Box::Calc->new();

my $box_type = $calc->add_box_type({
    x => 2,
    y => 2,
    z => 2,
    weight => 6,
    name => '8 cube',
});

$calc->add_box_type({
    x => 3,
    y => 3,
    z => 3,
    weight => 9,
    name => '27 cube',
});

is $calc->count_box_types, 2, 'two box types';

$calc->add_item(7,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);

is $calc->count_items, 7, '7 items to pack';

$calc->pack_items();
is $calc->count_boxes, 1, 'only one box was used';
is $calc->get_box(-1)->name, '8 cube', 'smallest box was used';
cmp_deeply
    $calc->packing_instructions,
        [
          {
            'calculated_weight' => '17.2',
            'fill_z' => '2.0000',
            'volume' => 8,
            'used_volume' => '7',
            'fill_volume' => '8',
            'name' => '8 cube',
            'x' => 2,
            'y' => 2,
            'fill_y' => '2.0000',
            'weight' => 6,
            'fill_x' => '2.0000',
            'id' => ignore(),
            'z' => 2,
            'layers' => [
                          {
                            'calculated_weight' => 4,
                            'fill_z' => '1.0000',
                            'fill_y' => '2.0000',
                            'fill_x' => '2.0000',
                            'rows' => [
                                        {
                                          'calculated_weight' => 2,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 2,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 2,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 2,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        }
                                      ]
                          },
                          {
                            'calculated_weight' => 3,
                            'fill_z' => '1.0000',
                            'fill_y' => '2.0000',
                            'fill_x' => '2.0000',
                            'rows' => [
                                        {
                                          'calculated_weight' => 2,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 2,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 1,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 1,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        }
                                      ]
                          }
                        ]
          }
        ],   
    'top-level packing instructions, 7 items';

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
is $calc->get_box(-1)->name, '27 cube', 'largest box was used';
cmp_deeply
    $calc->packing_instructions,
    [
          {
            'calculated_weight' => '29.3',
            'fill_z' => '2.0000',
            'volume' => 27,
            'used_volume' => '14',
            'fill_volume' => '18',
            'name' => '27 cube',
            'x' => 3,
            'y' => 3,
            'fill_y' => '3.0000',
            'weight' => 9,
            'fill_x' => '3.0000',
            'id' => ignore(),
            'z' => 3,
            'layers' => [
                          {
                            'calculated_weight' => 9,
                            'fill_z' => '1.0000',
                            'fill_y' => '3.0000',
                            'fill_x' => '3.0000',
                            'rows' => [
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        }
                                      ]
                          },
                          {
                            'calculated_weight' => 5,
                            'fill_z' => '1.0000',
                            'fill_y' => '2.0000',
                            'fill_x' => '3.0000',
                            'rows' => [
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 2,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 2,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        }
                                      ]
                          }
                        ]
          }
        ],
    'top-level packing instructions, 14 items';

$calc->reset_boxes;

$calc->add_item(14,
    x => 1,
    y => 1,
    z => 1,
    name => 'small die',
    weight => 1,
);
is $calc->count_items, 28, '28 items';
$calc->pack_items();
is $calc->count_boxes, 2, 'only one box was used';
@names = map { $_->name } @{ $calc->boxes };
cmp_deeply \@names, [('27 cube') x 2], 'used two boxes, both the largest';
cmp_deeply
    $calc->packing_instructions,
    [
          {
            'calculated_weight' => '42.3',
            'fill_z' => '3.0000',
            'volume' => 27,
            'used_volume' => '27',
            'fill_volume' => '27',
            'name' => '27 cube',
            'x' => 3,
            'y' => 3,
            'fill_y' => '3.0000',
            'weight' => 9,
            'fill_x' => '3.0000',
            'id' => ignore(),
            'z' => 3,
            'layers' => [
                          {
                            'calculated_weight' => 9,
                            'fill_z' => '1.0000',
                            'fill_y' => '3.0000',
                            'fill_x' => '3.0000',
                            'rows' => [
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        }
                                      ]
                          },
                          {
                            'calculated_weight' => 9,
                            'fill_z' => '1.0000',
                            'fill_y' => '3.0000',
                            'fill_x' => '3.0000',
                            'rows' => [
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        }
                                      ]
                          },
                          {
                            'calculated_weight' => 9,
                            'fill_z' => '1.0000',
                            'fill_y' => '3.0000',
                            'fill_x' => '3.0000',
                            'rows' => [
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        },
                                        {
                                          'calculated_weight' => 3,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 3,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       },
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        }
                                      ]
                          }
                        ]
          },
          {
            'calculated_weight' => '16.3',
            'fill_z' => '1.0000',
            'volume' => 27,
            'used_volume' => '1',
            'fill_volume' => '1',
            'name' => '27 cube',
            'x' => 3,
            'y' => 3,
            'fill_y' => '1.0000',
            'weight' => 9,
            'fill_x' => '1.0000',
            'id' => ignore(),
            'z' => 3,
            'layers' => [
                          {
                            'calculated_weight' => 1,
                            'fill_z' => '1.0000',
                            'fill_y' => '1.0000',
                            'fill_x' => '1.0000',
                            'rows' => [
                                        {
                                          'calculated_weight' => 1,
                                          'fill_z' => 1,
                                          'fill_y' => 1,
                                          'fill_x' => 1,
                                          'items' => [
                                                       {
                                                         'y' => 1,
                                                         'weight' => 1,
                                                         'name' => 'small die',
                                                         'x' => 1,
                                                         'z' => 1
                                                       }
                                                     ]
                                        }
                                      ]
                          }
                        ]
          }
        ],
    'top-level packing instructions, 28 items';

cmp_deeply
    $calc->packing_list,
    [
        {
            id => ignore(),
            name            => '27 cube',
            weight          => 36,
            packing_list    => {
                'small die' => 27
            }
        },
        {
            id => ignore(),
            name            => '27 cube',
            weight          => 10,
            packing_list    => {
                'small die' => 1
            }
        }
    ],
    'top-level packing list, 28 items';

done_testing;
