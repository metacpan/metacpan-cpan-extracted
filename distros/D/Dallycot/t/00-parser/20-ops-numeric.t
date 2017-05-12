use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  "4 * 1.23" => [product(intLit(4), floatLit(1.23))],

  '1 = 2'       => [equality(intLit(1), intLit(2))],

  '1 = 2 = 3'   => [equality(intLit(1), intLit(2), intLit(3))],

  '1 < 2'       => [strictly_increasing(intLit(1), intLit(2))],

  '1 < 2 < 3'   => [strictly_increasing(intLit(1), intLit(2), intLit(3))],

  '1 <= 2'      => [increasing(intLit(1), intLit(2))],

  '1 <= 2 <= 3' => [increasing(intLit(1), intLit(2), intLit(3))],

  '1 > 2 > 3'   => [strictly_decreasing(intLit(1), intLit(2), intLit(3))],

  '1 >= 2 >= 3' => [decreasing(intLit(1), intLit(2), intLit(3))],

  '1 <> 2 <> 3' => [unique(intLit(1), intLit(2), intLit(3))],

  '1 * 2' => [product(intLit(1), intLit(2))],

  '1 * 2 div 3 * 4 div 5' => [product(intLit(1), intLit(2), intLit(4), reciprocal(product(intLit(3), intLit(5))))],

  '1 + 2 - 3 + 4 - 5' => [sum(intLit(1), intLit(2), intLit(4), negation(sum(intLit(3), intLit(5))))],

  "1 = 1 and 3 > 2" => [all_(equality(intLit(1),intLit(1)), strictly_decreasing(intLit(3), intLit(2)))],

  "1 = 1 or 3 > 2" => [any_(equality(intLit(1),intLit(1)), strictly_decreasing(intLit(3), intLit(2)))],

  "- 1" => [negation(intLit(1))],
  "- - 1" => [intLit(1)],

);

done_testing();
