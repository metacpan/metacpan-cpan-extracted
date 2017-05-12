use strict;
use Test::More tests => 2;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}

# test whole SQL script
ok(
  PgLinkTestUtil::psql(
    'file'    => 't/t_util.sql',
    'options' => '--single-transaction',
  ), 
  'utility functions'
);
