use strict;
use warnings;

# test relies on the original default
BEGIN { delete @ENV{qw( DBIO_TEST_SWAPOUT_SQLAC_WITH )} }

use Test::More;

use DBIO::SQLite::Test ':DiffSQL';

my $base_schema = DBIO::SQLite::Test->init_schema(no_deploy => 1,
);

my $schema = $base_schema->connect(
  sub {
    $base_schema->storage->dbh
  },
  {
    on_connect_call => [ [ rebase_sqlmaker => 'DBIO::Test::SQLMRebase' ] ],
  },
);

ok (! $base_schema->storage->connected, 'No connection on base schema yet');
ok (! $schema->storage->connected, 'No connection on experimental schema yet');

$schema->storage->ensure_connected;

is(
  $schema->storage->sql_maker->__select_counter,
  undef,
  "No statements registered yet",
);

is_deeply(
  mro::get_linear_isa( ref( $schema->storage->sql_maker ) ),
  [
    qw(
      DBIO::SQLite::SQLMaker__REBASED_ON__DBIO::Test::SQLMRebase
      DBIO::SQLite::SQLMaker
      DBIO::SQLMaker
      DBIO::Test::SQLMRebase
      DBIO::SQLMaker::ClassicExtensions
    ),
    @{ mro::get_linear_isa( 'DBIO::Base' ) },
    @{ mro::get_linear_isa( 'SQL::Abstract' ) },
  ],
  'Expected SQLM object inheritance after rebase',
);


$schema->resultset('Artist')->count_rs->as_query;

is(
  $schema->storage->sql_maker->__select_counter,
  1,
  "1 SELECT fired off, tickling override",
);


$base_schema->resultset('Artist')->count_rs->as_query;

is(
  ref( $base_schema->storage->sql_maker ),
  'DBIO::SQLite::SQLMaker',
  'Expected core SQLM object on original schema remains',
);

is(
  $schema->storage->sql_maker->__select_counter,
  1,
  "No further SELECTs seen by experimental override",
);


done_testing;
