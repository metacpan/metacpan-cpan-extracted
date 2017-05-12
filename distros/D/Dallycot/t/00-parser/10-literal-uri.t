use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  "<http://example.com/foo>" => [uriLit('http://example.com/foo')],

  "<http://www.rottentomatoes.com/m/net/>" => [uriLit('http://www.rottentomatoes.com/m/net/')],

  "<http://www.example.com/>" => [uriLit('http://www.example.com/')],

  '<("http://example.com/" + "foo")>' => [buildUri(
    sum(
      stringLit('http://example.com/'),
      stringLit('foo')
    )
  )],
);

done_testing();
