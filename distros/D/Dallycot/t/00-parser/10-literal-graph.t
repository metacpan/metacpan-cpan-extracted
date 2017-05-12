use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  '{ f -> g }' => [build_node(right_property(fetch('f'), fetch('g')))],

  '{ g <- f }' => [build_node(left_property(fetch('g'), fetch('f')))],
);

done_testing();
