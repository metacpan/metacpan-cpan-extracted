use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  'primes Z primes...' => [zip(fetch('primes'), tail(fetch('primes')))],

  "[1, 2, 3]'" => [head(list(intLit(1), intLit(2), intLit(3)))],

  "[1, 2, 3]...'" => [head(tail(list(intLit(1), intLit(2), intLit(3))))],

  "[1, 2, 3]......'" => [head(tail(tail(list(intLit(1), intLit(2), intLit(3)))))],

  "upfrom(1)..." => [ tail(apply(fetch("upfrom"), intLit(1))) ],

  "{ #[2] - #[1] = 2 } % prime-pairs" => [
    filter_(
      lambda(['#'], {}, equality(
        sum(
          index_( fetch('#'), intLit(2) ),
          negation(
            index_( fetch('#'), intLit(1) )
          )
        ),
        intLit(2)
      )),
      fetch('prime-pairs')
    )
  ],

#  "0 << { #1 + #2 }/2 << [1,2,3,4,5]" => [
#    reduce(
#      intLit(0),
#      lambda(['#1', '#2'], {}, sum(fetch('#1'), fetch('#2'))),
#      list(intLit(1),intLit(2),intLit(3),intLit(4),intLit(5))
#    )
#  ],

  "1 ::> []" => [cons(list(), intLit(1))],

  "1 ::> 2 ::> []" => [cons(list(), intLit(2), intLit(1))],

  "1 ::> 2 ::> f(3)" => [cons(apply(fetch("f"), intLit(3)), intLit(2), intLit(1))],

  "[1] ::: [2, 3]" => [listCons(list(intLit(1)), list(intLit(2), intLit(3)))],

  "[1,2] ::: 3..5" => [listCons(list(intLit(1), intLit(2)), range(intLit(3), intLit(5)))],
);

done_testing();
