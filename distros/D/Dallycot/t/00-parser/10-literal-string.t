use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  '"String"^^URL' => [type_promotion(stringLit("String"), "URL")],

  '"String"^^x:Foo' => [type_promotion(stringLit("String"), "x:Foo")],

  '"String"^^URL^^HTML' => [type_promotion(stringLit("String"), "URL", "HTML")],

  '"This is a string"' => [stringLit("This is a string")],

  '"This is a string in French"@fr' => [stringLit("This is a string in French", "fr")],

  '"This is a string in US english"@en_US' => [stringLit("This is a string in US english", "en_US")],
);

done_testing();
