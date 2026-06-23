use strict;
use warnings;

use Test::More;
use DBIO::Test ':DiffSQL';

# Verify :DiffSQL exports are available
can_ok('main', 'is_same_sql_bind');
can_ok('main', 'is_same_sql');
can_ok('main', 'is_same_bind');

# is_same_sql ignores whitespace differences
is_same_sql(
  'SELECT  foo,  bar   FROM   baz   WHERE   x = 1',
  'SELECT foo, bar FROM baz WHERE x = 1',
  'whitespace normalization works'
);

# is_same_bind
is_same_bind(
  [[ {} => 'foo' ], [ {} => 'bar' ]],
  [[ {} => 'foo' ], [ {} => 'bar' ]],
  'bind comparison works'
);

done_testing;
