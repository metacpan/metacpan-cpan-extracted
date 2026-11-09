use strict;
use warnings;

use Test::More;

use DBIO::Test;

# _random_function and _explain_sql were the oldest two members of
# the driver-spelling hook family (ADR 0011 rebuilt rand/explain onto them
# instead of DBIx::Introspector), but they were only half rolled out -- missing
# from the _determine_driver list at the top of DBIO::Storage::DBI and from
# both of DBIO::Replicated::Storage's delegation lists, which the newer members
# _exists_value_sql / _set_operation_keyword were given from the start
# (ADR 0037, the latter renamed from _except_operator by ADR 0039).
#
# ADR 0040: _explain_sql is gone, replaced by
# _explain_query($sql, \@bind) -> \@rows, which owns the whole operation rather
# than one statement's spelling -- four engines cannot express a query plan as
# one statement. It keeps its slot on the _determine_driver list for exactly
# the reason it was put there; what changed is the delegation list it rides on
# in DBIO::Replicated::Storage (reader now, not writer), tested in
# t/test/08_replicated.t. _random_function is untouched: one scalar function
# name fits all ten engines.
#
# What is tested here is the mechanism, not the per-engine spellings: those are
# the driver dists' to declare and to verify against a live engine. What core
# owns is that the declaration is REACHABLE -- on a storage that has never
# connected, and through a replicated storage.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# --- 1. the base spellings ------------------------------------------------
#
# Both defaults are wrong on several of the engines this family ships, which
# is the whole point of the hook: RANDOM() does not exist on Oracle, and a
# bare EXPLAIN is rejected by Oracle and SQL Server and silently answers with
# VM bytecode rather than a query plan on SQLite.

is $schema->storage->_random_function, 'RANDOM()',
  '_random_function defaults to RANDOM() (PostgreSQL / SQLite / DuckDB)';

# _explain_query executes rather than returning a string, so its default is
# observed at the mock: one statement, the bare EXPLAIN prefix. The full
# behaviour of the base implementation and of an override lives in
# t/helpers/explain.t.
{
  $schema->storage->mock(qr/^EXPLAIN /, [ ['plan row'] ]);
  $schema->storage->reset_captured;

  my $rows = $schema->storage->_explain_query('SELECT 1', []);

  is_deeply $rows, [ ['plan row'] ],
    '_explain_query returns the rows of the plan statement';

  my ($stmt) = $schema->storage->captured_queries;
  is $stmt->{sql}, 'EXPLAIN SELECT 1',
    '_explain_query defaults to the bare EXPLAIN prefix';
}

# --- 2. both hooks fire driver determination ------------------------------
#
# Without this a never-connected storage answers with the spelling of the
# class it had before driver determination -- and rand() builds its order_by
# at query-build time, so "connect first" is not a workaround available to it.
# A schema declares its driver (ADR 0067); determination adapts the declared
# class to the access path of the DSN (ADR 0059). The fake driver keeps its
# spelling on the class of its access path.

{
  package T::Spell::DriverStorage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  sub _adapt_to_access_path {
    my ($self, $dbd) = @_;
    bless $self, 'T::Spell::DriverStorage::Path'
      if defined $dbd and $dbd eq 'FakeSpellDrv';
  }
}
{
  package T::Spell::DriverStorage::Path;
  use base 'T::Spell::DriverStorage';
  use mro 'c3';
  sub _random_function { 'NEWID()' }
  # A deliberately statement-free double: this storage has a DSN that no DBI
  # driver answers, so the point here is only that the driver's OWN method is
  # the one reached. A real _explain_query issues its statements through
  # _execute_rendered, which is required by the contract and pinned in
  # t/helpers/explain.t.
  sub _explain_query   { [ [ 'SHOWPLAN', $_[1] ] ] }
}

DBIO::Storage::DBI->register_driver('FakeSpellDrv' => 'T::Spell::DriverStorage');

{
  my $storage = T::Spell::DriverStorage->new($schema);
  $storage->connect_info([ 'dbi:FakeSpellDrv:', '', '' ]);

  is $storage->_random_function, 'NEWID()',
    '_random_function is on the _determine_driver list: the driver answers on '
  . 'a never-connected storage';
  isa_ok $storage, 'T::Spell::DriverStorage::Path',
    'asking for the random function determined the driver';
}

{
  my $storage = T::Spell::DriverStorage->new($schema);
  $storage->connect_info([ 'dbi:FakeSpellDrv:', '', '' ]);

  is_deeply $storage->_explain_query('SELECT 1', []),
    [ [ 'SHOWPLAN', 'SELECT 1' ] ],
    '_explain_query is on the _determine_driver list too';
  isa_ok $storage, 'T::Spell::DriverStorage::Path',
    'asking for the query plan determined the driver';
}

# --- 3. rand() renders the driver's spelling ------------------------------
#
# The end-to-end for _random_function; the one for _explain_query lives in
# t/helpers/explain.t, which can run the statement now that explain() goes
# down the storage path.

{
  package My::Rand::Storage;
  use base 'DBIO::Storage::DBI';
  sub _random_function { 'RAND()' }
}
$INC{'My/Rand/Storage.pm'} = __FILE__;

{
  my $rand_schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'My::Rand::Storage',
  );

  my $sql = ${ $rand_schema->resultset('Artist')->rand(3)->as_query }->[0];

  like $sql, qr/ORDER BY RAND\(\)/,
    'rand() orders by the driver\'s function, not the base RANDOM()';
  unlike $sql, qr/RANDOM\(\)/,
    'the base spelling is gone, not merely accompanied';
}

done_testing;
