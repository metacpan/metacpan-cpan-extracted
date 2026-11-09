use strict;
use warnings;

use Test::More;

use DBIO::Test ':DiffSQL';
use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;

# karr #32 / core ADR 0037 -- the supports_exists_query declaration.
#
# The capability is core's assertion that somebody CHECKED the rendering
# against this engine, not that a hook was overridden, so what this file pins
# is exactly that check: the driver takes core's base CASE form, unmodified,
# and says so on the class both DBD drivers and both server products share.
#
# Fully offline. Nothing here depends on a server: the statement is pure
# rendering, and the two things it asks of the engine (a FROM-less SELECT, and
# EXISTS in a condition position) are documented for MySQL and MariaDB alike --
# see the POD section this file guards.

# --- 1. the declaration, on the class that owns it -----------------------

is( DBIO::MySQL::Storage->_use_supports_exists_query, 1,
  'DBIO::MySQL::Storage declares supports_exists_query' );

# The declaration is a fact about the SERVER's SQL, not about the DBD, so it
# has to hold for a dbi:MariaDB: connection as well -- and it does by
# inheritance rather than by a second declaration, which is the karr #28 rule
# (DBIO::MySQL::Storage::MariaDB is the DBD::MariaDB binding, nothing else).
is( DBIO::MySQL::Storage::MariaDB->_use_supports_exists_query, 1,
  'the DBD::MariaDB subclass inherits it instead of re-declaring it' );

ok ! DBIO::MySQL::Storage::MariaDB->can('_exists_value_sql')
   || DBIO::MySQL::Storage::MariaDB->can('_exists_value_sql')
        == DBIO::Storage::DBI->can('_exists_value_sql'),
  'neither class overrides _exists_value_sql -- the base rendering is the one';

# --- 2. the rendering is core's base CASE form, byte for byte ------------
#
# Pinned as a literal rather than through is_same_sql_bind: the point is that
# this driver adds NOTHING to the statement (no dummy table, no wrapper), and
# a normaliser is exactly what would hide such an addition.

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::MySQL::Storage',
);

is $schema->storage->_exists_value_sql('(SELECT 42 FROM `artist` `me`)'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM `artist` `me`) THEN 1 ELSE 0 END',
  '_exists_value_sql renders the standard CASE form with no MySQL decoration';

# --- 3. end to end, offline ----------------------------------------------

{
  my $storage = $schema->storage;
  $storage->reset_captured;
  $storage->mock(qr/CASE WHEN EXISTS/, [ [ 1 ] ]);

  my $rs = $schema->resultset('Artist')->search({ name => 'Miles Davis' });

  is $rs->results_exist, 1, 'results_exist reads its answer off the statement';

  my @q = $storage->captured_queries;
  is scalar @q, 1, 'exactly one statement was issued';

  is_same_sql_bind(
    \[ $q[0]{sql}, @{ $q[0]{bind} } ],
    'SELECT CASE WHEN EXISTS (SELECT 42 FROM `artist` `me` WHERE ( `name` = ? ))'
      . ' THEN 1 ELSE 0 END',
    [ [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 }
        => 'Miles Davis' ] ],
    'the executed statement is the CASE form, backtick-quoted',
  );
}

{
  my $storage = $schema->storage;
  $storage->reset_captured;

  my $rs = $schema->resultset('Artist')->search({ name => 'Miles Davis' });

  my ($sql, @bind) = @{ ${ $rs->results_exist_as_query } };

  # parenthesised, because as_query hands back a subquery reference meant to
  # be embedded -- the statement inside is the same one results_exist runs
  is_same_sql_bind(
    \[ $sql, @bind ],
    '( SELECT CASE WHEN EXISTS (SELECT 42 FROM `artist` `me` WHERE ( `name` = ? ))'
      . ' THEN 1 ELSE 0 END )',
    [ [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 }
        => 'Miles Davis' ] ],
    'results_exist_as_query yields the same statement without executing it',
  );

  is scalar($schema->storage->captured_queries), 0,
    '... and issued no query to build it -- no connection to pick a rendering';
}

done_testing;
