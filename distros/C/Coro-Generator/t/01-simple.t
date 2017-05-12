use strict;
use warnings;
use Test::More tests => 4;
use Coro::Generator;

my $even = generator {
  my $x = 0;
  while(1) {
    $x++; $x++;
    yield $x;
  }
};

is($even->(), 2);
is($even->(), 4);
is($even->(), 6);
is($even->(), 8);

