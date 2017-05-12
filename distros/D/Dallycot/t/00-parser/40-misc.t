use lib 't/lib';

use Test::More;

use ParserHelper;

test_parses(
  'a := 3' => [assignment('a', intLit(3))],

  'xmlns:foo := "http://example.com/"' => [
    xmlns_def('foo', stringLit('http://example.com/'))
  ],

  "?s" => [Defined(fetch('s'))],
);

done_testing();
