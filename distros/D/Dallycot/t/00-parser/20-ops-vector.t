use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  '<1,2,3>[2]' => [index_(vector(intLit(1), intLit(2), intLit(3)), intLit(2))],

  'quintuple @ <1,2,3>' => [map_(fetch('quintuple'), vector(intLit(1), intLit(2), intLit(3)))],

);

done_testing();
