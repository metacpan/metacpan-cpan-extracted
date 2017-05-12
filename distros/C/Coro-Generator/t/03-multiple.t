use strict;
use warnings;
use Test::More tests => 8;
use Coro::Generator;

my $even = generator {
  my $x = 0;
  while(1) {
    $x++; $x++;
    yield $x;
  }
};

my $odd = generator {
  my $x = 1;
  while(1) {
    $x++; $x++;
    yield $x;
  }
};

is($even->(), 2);
is($odd->(),  3);
is($even->(), 4);
is($odd->(),  5);
is($even->(), 6);
is($odd->(),  7);
is($even->(), 8);
is($odd->(),  9);


