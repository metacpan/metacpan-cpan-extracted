use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
    '{ #[2] - #[1] = 2 } % primes Z primes...' => [
    filter_(
      lambda(
        ['#'], {},
        equality(
          sum(
            index_(
              fetch('#'),
              intLit(2)
            ),
            negation(
              index_(
                fetch('#'),
                intLit(1)
              )
            )
          ),
          intLit(2)
        )
      ),
      zip(
        fetch('primes'),
        tail(fetch('primes'))
      )
    )
  ],

  '(a) :> (a + 3)' => [lambda(['a'], {}, sum(fetch('a'), intLit(3)))],

  '(function) :> function(function, ___)' => [lambda(['function'], {},
    apply(fetch('function'),
      fetch('function'),
      fullPlaceholder
    )
  )],

  'foldl( <0,0>, ( (pad, element) :> <pad[1] + 1, pad[2] + element> ), _)' => [
    apply( fetch('foldl'),
      vector(intLit(0), intLit(0)),
      lambda(['pad', 'element'], {},
        vector(
          sum(
            index_(fetch('pad'), intLit(1)),
            intLit(1)
          ),
          sum(
            index_(fetch('pad'), intLit(2)),
            fetch('element')
          )
        )
      ),
      placeholder
    )
  ],

  '{ # + 3 }'     => [lambda(['#'], {}, sum(fetch('#'), intLit(3)))],

  '{ #1 + #2 }/2' => [lambda(['#1', '#2'], {}, sum(fetch('#1'), fetch('#2')))],

  'f(x,y) :> x + y' => [assignment(f => lambda(['x', 'y'], {}, sum(fetch('x'), fetch('y'))))],

  'f(x, y, a -> 3, b -> "foo", c -> <1,2,3>) :> x + y' => [
    assignment(
      f => lambda(
        ['x','y'],
        {
          a => intLit(3),
          b => stringLit("foo"),
          c => vectorLit(intLit(1), intLit(2), intLit(3)),
        },
        sum(
          fetch('x'),
          fetch('y'),
        )
      )
    )
  ],

  "Y(f) :> f(f, ___)" => [
    assignment( Y => lambda(
      ['f'],
      {},
      apply( fetch('f'),
        fetch('f'),
        fullPlaceholder
      )
    ))
  ],

  "Y((f,n) :> [ n, f(f, n+1) ])" => [
    apply( fetch('Y'),
      lambda(
        ['f', 'n'],
        {},
        list( fetch('n'),
          apply(fetch('f'),
            fetch('f'),
            sum(fetch('n'), intLit(1))
          )
        )
      )
    )
  ],

  "(f) :> f(f, ___)" => [
    lambda(
      ['f'],
      {},
      apply(fetch('f'),
        fetch('f'),
        fullPlaceholder
      )
    )
  ],

  "foo()" => [apply( fetch('foo') )],

  'string-take("The bright red spot.", <4,9>)' => [
    apply(
      fetch('string-take'),
      stringLit("The bright red spot."),
      vector(intLit(4), intLit(9))
    )
  ],

  'string-take("The bright red spot.", <10>)' => [
    apply(
      fetch('string-take'),
      stringLit("The bright red spot."),
      vector(intLit(10))
    )
  ],

  "yf(a, b, opt -> 14, foo -> <1,2,3>)" => [
    apply_with_options(
      fetch('yf'),
      {
        opt => intLit(14),
        foo => vector(intLit(1), intLit(2), intLit(3))
      },
      fetch('a'),
      fetch('b')
    )
  ],

  "f @ g" => [map_(fetch('f'), fetch('g'))],

  "f % g" => [filter_(fetch('f'), fetch('g'))],

  "f . g" => [compose_(fetch('f'), fetch('g'))],

  "f . g . h" => [compose_(fetch('f'), fetch('g'), fetch('h'))],

  "f @ g % s" => [ map_(fetch('f'), filter_(fetch('g'), fetch('s'))) ],

  "{ # }" => [lambda(['#'], {}, fetch('#'))],

  "{ # } @ g" => [map_(lambda(['#'], {}, fetch('#')), fetch('g'))],

  'f @ g @ <1,2,3>' => [map_(
    fetch('f'), fetch('g'), vector(intLit(1), intLit(2), intLit(3))
  )],

  "upfrom_f(yf, n) :> [ n, yf(yf, n+1)]" => [assignment(
    upfrom_f => lambda(
      [qw(yf n)],
      {},
      list(
        fetch('n'),
        apply(
          fetch('yf'),
          fetch('yf'),
          sum(
            fetch('n'),
            intLit(1)
          )
        )
      )
    )
  )],

  "upfrom := upfrom_f(upfrom_f, _)" => [assignment(
    upfrom => apply(
      fetch('upfrom_f'),
      fetch('upfrom_f'),
      placeholder()
    )
  )],

  "upfrom_f(yf, n) :> [ n, yf(yf, n+1)];
   upfrom := upfrom_f(upfrom_f, _)" => [
   sequence(
    assignment(
      upfrom_f => lambda(
        [qw(yf n)],
        {},
        list(
          fetch('n'),
          apply(
            fetch('yf'),
            fetch('yf'),
            sum(
              fetch('n'),
              intLit(1)
            )
          )
        )
      )
    ),
    assignment(
      upfrom => apply(
        fetch('upfrom_f'),
        fetch('upfrom_f'),
        placeholder()
      )
    )
    )
  ],

  "upfrom_f(self, n) :> [ n, self(self, n+1) ]" => [assignment(upfrom_f => lambda(['self', 'n'], {}, list(fetch('n'), apply(fetch('self'), fetch('self'), sum(fetch('n'), intLit(1))))))],

  "evenq(n) :> n mod 2 = 0" => [assignment(
    evenq => lambda(
      ['n'],
      {},
      equality(
        modulus(
          fetch('n'),
          intLit(2)
        ),
        intLit(0)
      )
    )
  )],

  "map( { # * 5 }, upfrom(1))'" => [
    head(
      apply(
        fetch('map'),
        lambda(
          ['#'],
          {},
          product(
            fetch('#'),
            intLit(5)
          )
        ),
        apply(
          fetch('upfrom'),
          intLit(1)
        )
      )
    )
  ],

  " ({ # * 5 } @ upfrom(1))'" => [
    head(
      map_(
        lambda(
          ['#'],
          {},
          product(
            fetch('#'),
            intLit(5)
          )
        ),
        apply(
          fetch('upfrom'),
          intLit(1)
        )
      )
    )
  ]
);

done_testing();
