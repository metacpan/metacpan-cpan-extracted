use strict;
use warnings;
use Test::More tests => 6;
use Coro::Generator;

my $even = generator {
  my $x = 0;
  while($x < 10) {
    $x++; $x++;
    yield $x;
  }
};

is($even->(), 2);
is($even->(), 4);
is($even->(), 6);
is($even->(), 8);
is($even->(), 10);
is($even->(), 2);

