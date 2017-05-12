use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  '<1,2,3>' => [vector(intLit(1), intLit(2), intLit(3))],

  '<<this is four words>>' => [vectorLit(stringLit('this'), stringLit('is'), stringLit('four'), stringLit('words'))],

  '<<this\ is two\ words>>' => [vectorLit(stringLit('this is'), stringLit('two words'))],

  '<<this\nis two\nwords\too>>' => [vectorLit(stringLit("this\nis"), stringLit("two\nwords\too"))],

  '< <1,2,3>,<4,5,6> >' => [
    vectorLit(
      vectorLit(intLit(1), intLit(2), intLit(3)),
      vectorLit(intLit(4), intLit(5), intLit(6))
    )
  ]
);

done_testing();
