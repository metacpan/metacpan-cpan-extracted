use Array::Join;
use Test::More;
use Data::Dumper;
use List::MoreUtils qw/uniq/;

sub dumper { Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Purity(1)->Deepcopy(1)->Dump }

use strict;

$\ = "\n"; $, = " ";

my @arr_a = (
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

my @arr_b = (
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


my $lookup_a = Array::Join::make_lookup(\@arr_a, sub { shift->{color} });
my $lookup_b = Array::Join::make_lookup(\@arr_b, sub { shift->{color} });

my @outer_keys  = uniq ((keys $lookup_a->%*), (keys $lookup_b->%*));

my $i;
for (sort @outer_keys) {
    my @cross = Array::Join::cross_product($lookup_a->{$_}, $lookup_b->{$_});
    ok((scalar @cross) == (scalar $lookup_a->{$_}->@*) * (scalar $lookup_b->{$_}->@*), "cross $_")
}

done_testing()
