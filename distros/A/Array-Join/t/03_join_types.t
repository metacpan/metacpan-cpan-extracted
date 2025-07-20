use Array::Join;
use Test::More;
use List::MoreUtils qw/uniq/;

use Data::Dumper;
sub dumper { Data::Dumper->new([@_])->Indent(0)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump }

use strict;

$\ = "\n"; $, = "\t";

my @arr_a = (
  { id => 1,  key => 'apple',  price => 10 },
  { id => 2,  key => 'banana', price => 20 },
  { id => 3,  key => 'cherry', price => 30 },
  { id => 4,  key => 'date',   price => 40 },
  { id => 5,  key => 'elder',  price => 50 },
  { id => 6,  key => 'fig',    price => 60 },
  { id => 7,  key => 'grape',  price => 70 },
  { id => 8,  key => 'honey',  price => 80 },
  { id => 9,  key => 'kiwi',   price => 90 },
  { id => 10, key => 'lemon',  price => 100 },
  { id => 11, key => 'mango',  price => 110 },
  { id => 12, key => 'nectar', price => 120 },
  { id => 13, key => 'olive',  price => 130 },
  { id => 14, key => 'peach',  price => 140 },
  { id => 15, key => 'quince', price => 150 },
  { id => 16, key => 'rasp',   price => 160 },
  { id => 17, key => 'straw',  price => 170 },
  { id => 18, key => 'tang',   price => 180 },
  { id => 19, key => 'ugli',   price => 190 },
  { id => 20, key => 'voav',   price => 200 },
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


my $lookup_a = Array::Join::make_lookup(\@arr_a, sub { shift->{key} });
my $lookup_b = Array::Join::make_lookup(\@arr_b, sub { shift->{key} });

my $outer = ["apple","banana","carrot","cherry","date","eggplant","elder","fig","grape","honey","iceberg","jalapeno","kiwi","lemon","mango","nectar",
	     "olive","onion","peach","quince","radish","rasp","straw","tang","tomato","ugli","voav"];
my $left  = ["apple","banana","cherry","date","elder","fig","grape","honey","kiwi","lemon","mango","nectar","olive","peach","quince","rasp","straw","tang","ugli","voav"];
my $right = ["apple","banana","carrot","date","eggplant","fig","grape","honey","iceberg","jalapeno","kiwi","lemon","mango","nectar","onion","peach",
	     "quince","radish","straw","tomato"];
my $inner = ["apple","banana","date","fig","grape","honey","kiwi","lemon","mango","nectar","peach","quince","straw"];

is_deeply([ sort (Array::Join::make_keys($lookup_a, $lookup_b, { type => "outer" })) ], $outer, "outer");
is_deeply([ sort (Array::Join::make_keys($lookup_a, $lookup_b, { type => "inner" })) ], $inner, "inner");
is_deeply([ sort (Array::Join::make_keys($lookup_a, $lookup_b, { type => "left" })) ], $left, "left");
is_deeply([ sort (Array::Join::make_keys($lookup_a, $lookup_b, { type => "right" })) ], $right, "right");

done_testing()
