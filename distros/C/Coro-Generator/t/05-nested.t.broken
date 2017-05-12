use strict;
use warnings;
use Test::More tests => 6;
use Coro::Generator;

my $outside = generator {
  my $inside_even = generator {
    my $x = 0;
    while(1) {
      $x++; $x++;
      yield($x);
    }
  };
  while(1) {
    for my $i (0..3) {
      yield($inside_even->());
    }
    yield(0);
  }
};

is($outside->(), 2);
is($outside->(), 4);
is($outside->(), 6);
is($outside->(), 8);
is($outside->(), 0);
is($outside->(), 10);

