use strict;
use warnings;
use Test::More tests => 8;
use Coro::Generator;

my $nth = generator {
  my $n = shift;
  my $x = 0;
  while(1) {
    $x += $n;
    yield $x;
  }
};

is($nth->(3), 3);
is($nth->(), 6);
is($nth->(), 9);
is($nth->(17), 12, "Parameter is unused and ignored");

my $add_n = generator {
  my $n = shift;
  my $x = 0;
  while(1) {
    $x += $n;
    $n = yield $x;
  }
};

is($add_n->(3), 3);
is($add_n->(7), 10);
is($add_n->(17), 27);
is($add_n->(-1), 26);

