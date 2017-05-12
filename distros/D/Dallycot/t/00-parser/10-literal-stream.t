use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  '[1, 2, 3]' => [list(intLit(1), intLit(2), intLit(3))],

  "[ n, yf(yf, n+1)]" => [list(fetch('n'), apply(fetch('yf'), fetch('yf'), sum(fetch('n'), intLit(1))))],

  "[]" => [list()],

  "1.." => [range(intLit(1))],

  "3..19" => [range(intLit(3), intLit(19))],
);

done_testing();
