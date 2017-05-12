use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  "(
    (?s) : 1 + ff(ff, s...)
    (  ) : 0
  )" => [conditions(
    condition(
      Defined(
        fetch('s')
      ),
      sum(
        intLit(1),
        apply(
          fetch('ff'),
          fetch('ff'),
          tail(
            fetch('s')
          )
        )
      )
    ),
    otherwise(
      intLit(0)
    )
  )],

  "(
    (evenq(s')) : [ s', evens_f(f, s...) ]
    (         ) : evens_f(f, s...)
  )" => [conditions(
    condition(
      apply(
        fetch('evenq'),
        head(fetch('s'))
      ),
      list(
        head(fetch('s')),
        apply(
          fetch('evens_f'),
          fetch('f'),
          tail(fetch('s'))
        )
      )
    ),
    otherwise(
      apply(
        fetch('evens_f'),
        fetch('f'),
        tail(fetch('s'))
      )
    )
  )],

  "evens_f(f, s) :> (
    (evenq(s')) : [ s', f(f, s...) ]
    (         ) :       f(f, s...)
  )" => [assignment(
    evens_f => lambda(
      [qw(f s)],
      {},
      conditions(
        condition(
          apply(
            fetch('evenq'),
            head(fetch('s'))
          ),
          list(
            head(fetch('s')),
            apply(
              fetch('f'),
              fetch('f'),
              tail(fetch('s'))
            )
          )
        ),
        otherwise(
          apply(
            fetch('f'),
            fetch('f'),
            tail(fetch('s'))
          )
        )
      )
    )
  )],

  "odds := (
    odds_f(f, s) :> (
      (oddq(s')) : [ s', f(f, s...) ]
      (        ) :       f(f, s...)
    );
    odds_f(odds_f, _)
  )" => [assignment(
    odds => sequence(
      assignment(
        odds_f => lambda(
          [qw(f s)],
          {},
          conditions(
            condition(
              apply(
                fetch('oddq'),
                head(fetch('s'))
              ),
              list(
                head(fetch('s')),
                apply(
                  fetch('f'),
                  fetch('f'),
                  tail(fetch('s'))
                )
              )
            ),
            otherwise(
              apply(
                fetch('f'),
                fetch('f'),
                tail(fetch('s'))
              )
            )
          )
        )
      ),
      apply(
        fetch('odds_f'),
        fetch('odds_f'),
        placeholder()
      )
    )
  )],
);

done_testing();
