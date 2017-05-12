use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  '<| 1 | 2 | 3 |>' => [set(intLit(1), intLit(2), intLit(3))],

  '<| |>' => [ set() ],

  '<||>' => [ set() ],

  'even? % <| 1 | 2 | 3 | 5 | 8 | 13 | 21 | 34 |>' => [
    filter_(
      fetch('even?'),
      set(map { intLit($_) } (
        1, 2, 3, 5, 8, 13, 21, 34
      ))
    )
  ]
);

done_testing();
