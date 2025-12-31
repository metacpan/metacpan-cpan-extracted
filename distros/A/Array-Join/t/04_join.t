use Array::Join;
use Test::More;
use Data::Dumper;

sub dumper { Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Deepcopy(1)->Dump }

use strict;

$\ = "\n"; $, = "\t";

my @arr_a = (
  { id => 1, foo => 'apple',  price => 10 },
  { id => 2, foo => 'banana', price => 20 },
  { id => 3, foo => 'cherry', price => 30 },
  { id => 4, foo => 'date',   price => 40 },
  { id => 5, foo => 'elder',  price => 50 },
  { id => 6, foo => 'fig',    price => 60 },
  { id => 7, foo => 'grape',  price => 70 },
  { id => 8, foo => 'honey',  price => 80 },
  { id => 9, foo => 'kiwi',   price => 90 },
  { id => 10,foo => 'lemon',  price => 100 },
  { id => 11,foo => 'mango',  price => 110 },
  { id => 12,foo => 'nectar', price => 120 },
  { id => 13,foo => 'olive',  price => 130 },
  { id => 14,foo => 'peach',  price => 140 },
  { id => 15,foo => 'quince', price => 150 },
  { id => 16,foo => 'rasp',   price => 160 },
  { id => 17,foo => 'straw',  price => 170 },
  { id => 18,foo => 'tang',   price => 180 },
  { id => 19,foo => 'ugli',   price => 190 },
  { id => 20,foo => 'voav',   price => 200 },
);

my @arr_b = (
  { key => 'apple',    color => 'red',    desc => 'fruit' },
  { key => 'banana',   color => 'yellow', desc => 'fruit' },
  { key => 'carrot',   color => 'orange', desc => 'vegetable' },
  { key => 'date',     color => 'brown',  desc => 'fruit' },
  { key => 'eggplant', color => 'purple', desc => 'vegetable' },
  { key => 'fig',      color => 'purple', desc => 'fruit' },
  { key => 'grape',    color => 'green',  desc => 'fruit' },
  { key => 'honey',    color => 'gold',   desc => 'sweetener' },
  { key => 'iceberg',  color => 'green',  desc => 'lettuce' },
  { key => 'jalapeno', color => 'green',  desc => 'pepper' },
  { key => 'kiwi',     color => 'brown',  desc => 'fruit' },
  { key => 'lemon',    color => 'yellow', desc => 'fruit' },
  { key => 'mango',    color => 'orange', desc => 'fruit' },
  { key => 'nectar',   color => 'orange', desc => 'fruit' },
  { key => 'onion',    color => 'white',  desc => 'vegetable' },
  { key => 'peach',    color => 'pink',   desc => 'fruit' },
  { key => 'quince',   color => 'yellow', desc => 'fruit' },
  { key => 'radish',   color => 'red',    desc => 'vegetable' },
  { key => 'straw',    color => 'red',    desc => 'fruit' },
  { key => 'tomato',   color => 'red',    desc => 'fruit' },
);

my @arr_c = (
  # ── red ───────────────────────────
  { color => 'red',    country => 'USA'        },
  { color => 'red',    country => 'UK'         },
  { color => 'red',    country => 'Japan'      },

  # ── yellow ────────────────────────
  { color => 'yellow', country => 'USA'        },
  { color => 'yellow', country => 'Germany'    },
  { color => 'yellow', country => 'Spain'      },

  # ── orange ────────────────────────
  { color => 'orange', country => 'Canada'     },
  { color => 'orange', country => 'Italy'      },
  { color => 'orange', country => 'Brazil'     },

  # ── brown ─────────────────────────
  { color => 'brown',  country => 'Germany'    },
  { color => 'brown',  country => 'Mexico'     },
  { color => 'brown',  country => 'Australia'  },

  # ── purple ────────────────────────
  { color => 'purple', country => 'France'     },
  { color => 'purple', country => 'UK'         },
  { color => 'purple', country => 'Japan'      },

  # ── green ─────────────────────────
  { color => 'green',  country => 'USA'        },
  { color => 'green',  country => 'Brazil'     },
  { color => 'green',  country => 'India'      },

  # ── gold ──────────────────────────
  { color => 'gold',   country => 'UAE'        },
  { color => 'gold',   country => 'Saudi Arabia' },
  { color => 'gold',   country => 'Switzerland'  },

  # ── white ─────────────────────────
  { color => 'white',  country => 'Canada'     },
  { color => 'white',  country => 'USA'        },
  { color => 'white',  country => 'Japan'      },

  # ── pink ──────────────────────────
  { color => 'pink',   country => 'France'     },
  { color => 'pink',   country => 'UK'         },
  { color => 'pink',   country => 'Brazil'     },
);


ok (60 == scalar Array::Join::join_arrays(\@arr_b, \@arr_c, {
							     on => [ sub { shift()->{color} }, sub { shift()->{color} } ],
							     type => "inner"
							    }), "size");

ok ("ARRAY" eq ref [ Array::Join::join_arrays(\@arr_b, \@arr_c, {
								 on => [ sub { shift()->{color} }, sub { shift()->{color} } ], type => "inner"
								}
					     ) ]->[0], "result type");

is_deeply(
	  [qw/color country desc key/],
	  [ sort keys [ Array::Join::join_arrays(\@arr_b, \@arr_c,
						 {
						  on => [ sub { shift()->{color} }, sub { shift()->{color} } ],
						  type => "inner", merge => 1
						 }
						) ]->[0]->%* ],
	  "merge keys"
	 );
is_deeply(
	  [qw/a.color a.desc a.key b.color b.country/],
	  [ sort keys [ Array::Join::join_arrays(\@arr_b, \@arr_c,
						 {
						  on => [ sub { shift()->{color} }, sub { shift()->{color} } ],
						  type => "inner", merge => [qw/a b/]
						 }
						) ]->[0]->%* ],
	  "tag keys"
	 );

done_testing()
