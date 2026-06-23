use strict;
use warnings;

# test relies on the original default
BEGIN { delete @ENV{qw( DBIO_TEST_SWAPOUT_SQLAC_WITH )} }

use Test::More;

use DBIO::Test ':DiffSQL';

my $base_schema = DBIO::Test->init_schema(
  no_deploy => 1,
);

# Manually invoke rebase_sqlmaker on the fake storage
# (the on_connect_call mechanism requires a real connect cycle,
# but we can call connect_call_rebase_sqlmaker directly)
$base_schema->storage->sql_maker; # ensure sql_maker is built
$base_schema->storage->connect_call_rebase_sqlmaker('DBIO::Test::SQLMRebase');

is(
  $base_schema->storage->sql_maker->__select_counter,
  undef,
  "No statements registered yet",
);

is_deeply(
  mro::get_linear_isa( ref( $base_schema->storage->sql_maker ) ),
  [
    qw(
      DBIO::SQLMaker__REBASED_ON__DBIO::Test::SQLMRebase
      DBIO::SQLMaker
      DBIO::Test::SQLMRebase
      DBIO::SQLMaker::ClassicExtensions
    ),
    @{ mro::get_linear_isa( 'DBIO::Base' ) },
    @{ mro::get_linear_isa( 'SQL::Abstract' ) },
  ],
  'Expected SQLM object inheritance after rebase',
);


$base_schema->resultset('Artist')->count_rs->as_query;

is(
  $base_schema->storage->sql_maker->__select_counter,
  1,
  "1 SELECT fired off, tickling override",
);

done_testing;
