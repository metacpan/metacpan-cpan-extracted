use strict;
use warnings;

use CommonsLang;
use Test::More;

##
is_deeply(a_concat([ "a", "b" ], [ "1", "2" ]), [ "a", "b", "1", "2" ], 'a_concat.');
is_deeply(
    a_concat([ { a => 1 }, { a => 2 } ], [ { a => 3 }, { a => 4 } ]),
    [ { a => 1 }, { a => 2 }, { a => 3 }, { a => 4 } ], 'a_concat.'
);


##
my $element1 = { a => 1 };
is(
    a_concat([ $element1, { a => 2 } ], [ { a => 3 }, { a => 4 } ])->[0],
    $element1, 'a_concat.'
  );

############
done_testing();
