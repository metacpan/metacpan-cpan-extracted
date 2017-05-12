use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
 "123" => [intLit(123)],

  "0" => [intLit(0)],

  "0.0" => [floatLit("0.0")],

  "1.23" => [floatLit("1.23")],

  "1.23e+23" => [floatLit("1.23e+23")],
);

done_testing();
