use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';
use DBIO::Storage::DBI;
use DBIO::Storage::DBI::Capabilities ();

# ADR 0037: the two engine-specific SQL fragments left in core get a seam.
#
#   A) results_exist / results_exist_async / results_exist_as_query render
#      through the _exists_value_sql storage hook and are gated by the
#      supports_exists_query capability (default 0, no silent fallback).
#   B) the set operations take their keyword from a storage hook instead of
#      comparing sqlt_type to 'Oracle' -- no capability, no connection at
#      query-build time. ADR 0039 later generalised that hook from
#      _except_operator to _set_operation_keyword($op), which is the name
#      used here.
#
# This file covers the capability plumbing, both hooks, driver determination
# and the exception contract. The ResultSet-level SQL shapes live in
# t/helpers/subquery_helpers.t (A) and t/helpers/set_operations.t (B), the
# sync/async SQL parity in t/resultset/async_parity_helpers.t.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# --- 1. the capability is part of the declared contract surface ----------
#
# Named supports_exists_query, so the two-tier accessors spell out as
# _supports_supports_exists_query / _use_supports_exists_query -- the same
# shape as supports_if_exists (ADR 0026) and supports_upsert (ADR 0036).

can_ok 'DBIO::Storage::DBI::Capabilities', '_supports_supports_exists_query';
can_ok 'DBIO::Storage::DBI::Capabilities', '_use_supports_exists_query';
can_ok 'DBIO::Storage::DBI::Capabilities', '_determine_supports_supports_exists_query';

is( DBIO::Storage::DBI::Capabilities->_determine_supports_supports_exists_query, 0,
  'the default _determine_supports_supports_exists_query is conservative (0): '
. 'an engine cannot render a boolean-valued EXISTS query until its driver '
. 'says so' );

# --- 2. tiered accessor plumbing on a live storage object ----------------

{
  my $storage = $schema->storage;

  is $storage->_use_supports_exists_query, 1,
    'the fake storage declares supports_exists_query (ADR 0037 section 7)';

  $storage->_use_supports_exists_query(0);
  is $storage->_use_supports_exists_query, 0, '_use_supports_exists_query(0) is honoured';

  # ADR 0041: DBIO::Test::Storage declares this in tier 2, at class level.
  # Clearing the tier-1 force therefore hands the question back to that
  # declaration -- not through to _determine_supports_*, which would answer
  # core's default 0 and leave the capability off for the life of the storage.
  # The full tier semantics are pinned in t/test/26_capability_tiers.t.
  $storage->_use_supports_exists_query(undef);
  is $storage->_use_supports_exists_query, 1,
    'clearing the force falls back to the class-level declaration, not to the '
  . 'determiner';

  $storage->_use_supports_exists_query(1);
}

# --- 3. the base rendering is the standard CASE form ---------------------
#
# Strictly more portable than what core emitted before: correct on
# PostgreSQL, MySQL/MariaDB, SQLite, DuckDB, SQL Server and Sybase. Only the
# three engines that also refuse a FROM-less SELECT override the hook, each
# appending its own dummy table -- core holds no dummy-table knowledge and
# composes nothing out of parts.

is( $schema->storage->_exists_value_sql('(SELECT 42 FROM "artist" "me")'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END',
  '_exists_value_sql renders the whole statement in the standard CASE form' );

is( $schema->storage->_set_operation_keyword('except'), 'EXCEPT',
  '_set_operation_keyword answers ANSI EXCEPT for except by default' );

# --- 4. both hooks fire driver determination -----------------------------
#
# A never-connected storage must answer with the rendering driver
# determination leaves it with, not the one of the class it had before. A
# schema declares its driver (ADR 0067); determination adapts the declared
# class to the access path of the DSN (ADR 0059), without a connection. The
# fake driver below keeps its rendering on the class of its access path, so
# a hook asked before determination would answer with the base form.

{
  package T::EQ::DriverStorage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  sub _adapt_to_access_path {
    my ($self, $dbd) = @_;
    bless $self, 'T::EQ::DriverStorage::Path'
      if defined $dbd and $dbd eq 'FakeExistsDrv';
  }
}
{
  package T::EQ::DriverStorage::Path;
  use base 'T::EQ::DriverStorage';
  use mro 'c3';
  sub _exists_value_sql { "SELECT CASE WHEN EXISTS $_[1] THEN 1 ELSE 0 END FROM DUAL" }
  sub _set_operation_keyword {
    my ($self, $op) = @_;
    return 'MINUS' if $op eq 'except';
    return $self->next::method($op);
  }
}

DBIO::Storage::DBI->register_driver('FakeExistsDrv' => 'T::EQ::DriverStorage');

{
  my $storage = T::EQ::DriverStorage->new($schema);
  $storage->connect_info([ 'dbi:FakeExistsDrv:', '', '' ]);

  is $storage->_exists_value_sql('(SELECT 42)'),
    'SELECT CASE WHEN EXISTS (SELECT 42) THEN 1 ELSE 0 END FROM DUAL',
    '_exists_value_sql is on the _determine_driver list: the driver answers on '
  . 'a never-connected storage';
  isa_ok $storage, 'T::EQ::DriverStorage::Path',
    'asking the hook determined the driver';
}

{
  my $storage = T::EQ::DriverStorage->new($schema);
  $storage->connect_info([ 'dbi:FakeExistsDrv:', '', '' ]);

  is $storage->_set_operation_keyword('except'), 'MINUS',
    '_set_operation_keyword is on the _determine_driver list too';
  isa_ok $storage, 'T::EQ::DriverStorage::Path',
    'asking the keyword hook determined the driver';
}

# --- 5. the executed statement is the hook's, on the normal path ---------

{
  my $storage = $schema->storage;
  $storage->reset_captured;
  $storage->mock(qr/CASE WHEN EXISTS/, [ [ 1 ] ]);

  my $rs = $schema->resultset('Artist')->search({ name => 'Miles Davis' });
  is $rs->results_exist, 1, 'results_exist reads 1 off the CASE statement';

  my @q = $storage->captured_queries;
  is scalar @q, 1, 'exactly one statement was issued';

  is_same_sql_bind(
    \[ $q[0]{sql}, @{ $q[0]{bind} } ],
    'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me" WHERE ( "name" = ? ))'
      . ' THEN 1 ELSE 0 END',
    [ [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'Miles Davis' ] ],
    'the storage receives the hook\'s complete statement, binds and all',
  );

  unlike $q[0]{sql}, qr/_existence_subq/,
    'the SELECT * FROM ( ... ) AS _existence_subq wrapper is gone (ADR 0037 section 2)';

  # The 'f'-is-true footgun, closed by construction: the old spelling asked
  # the engine for a boolean-typed value, and with pg_bool_tf => 1 an empty
  # set comes back as the string 'f', which is TRUE in Perl. A CASE
  # expression yields an integer on every engine, so there is no boolean
  # column left to mis-read.
  unlike $q[0]{sql}, qr/SELECT \s+ EXISTS/xi,
    'no bare SELECT EXISTS: the value is an integer CASE result, not an '
  . 'engine-typed boolean';
}

{
  my $storage = $schema->storage;
  $storage->reset_captured;
  $storage->mock(qr/CASE WHEN EXISTS/, [ [ 0 ] ]);

  is $schema->resultset('Artist')->results_exist, 0,
    'a 0 from the CASE statement reads as false';
}

# --- 6. a driver's own rendering is what gets executed -------------------

{
  package T::EQ::OracleForm;
  our @ISA = ('DBIO::Test::Storage');
  sub _exists_value_sql { "SELECT CASE WHEN EXISTS $_[1] THEN 1 ELSE 0 END FROM DUAL" }
}

{
  my $oracle_schema = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = T::EQ::OracleForm->new($oracle_schema);
  $oracle_schema->storage($storage);

  $storage->mock(qr/CASE WHEN EXISTS/, [ [ 1 ] ]);
  my $rs = $oracle_schema->resultset('Artist');
  is $rs->results_exist, 1, 'the overridden rendering still yields a boolean';

  my ($q) = $storage->captured_queries;
  is $q->{sql},
    'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END FROM DUAL',
    'a storage subclass that overrides _exists_value_sql gets exactly its SQL executed';

  is_same_sql_bind(
    $rs->results_exist_as_query,
    '( SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END FROM DUAL )',
    [],
    'results_exist_as_query parenthesises the driver\'s statement and adds nothing else',
  );
}

# --- 6b. the pre-rendered path is still a driver-reshapeable path --------
#
# The statement does not pass through _prep_for_execute (there is nothing to
# generate), so a driver that rewrites statements on the way out has to be
# asked separately -- otherwise the one statement core renders itself would
# reach an engine with no usable placeholders with its ? intact. Sybase is
# both a NoBindVars driver and one of the five engines this ADR exists for.

{
  my $nbv_schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::Storage::DBI::NoBindVars',
  );
  my $storage = $nbv_schema->storage;
  isa_ok $storage, 'DBIO::Storage::DBI::NoBindVars', 'the hybrid fake storage';

  $storage->mock(qr/CASE WHEN EXISTS/, [ [ 1 ] ]);
  is $nbv_schema->resultset('Artist')->search({ rank => 13 })->results_exist, 1,
    'results_exist works on a placeholder-less driver';

  my ($q) = $storage->captured_queries;
  is $q->{sql},
    'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me" WHERE ( "rank" = 13 ))'
      . ' THEN 1 ELSE 0 END',
    'the bind value was interpolated into the rendered statement';
  is_deeply $q->{bind}, [],
    'and no placeholder is left to bind';
}

# --- 7. an engine that does not have the capability throws, in all three
#        methods ---------------------------------------------------------
#
# No silent fallback to has_rows: the caller asked for the cheap server-side
# check and would get a different query shape without being told (ADR 0037
# section 4, the reason ADR 0036 refused it for upsert). The alternative is
# named in the message instead.
#
# The storage says so at class level, the way a driver does. It cannot be
# expressed by clearing the force instead: the mock parent declares the
# capability in tier 2 and ADR 0041 made clearing hand the question back to
# that declaration, which is the whole point. Core's own default of 0 -- the
# never-declared case -- is pinned in section 1 above.

{
  package T::EQ::Undeclared;
  our @ISA = ('DBIO::Test::Storage');
  __PACKAGE__->_use_supports_exists_query(0);
}

my $undeclared_schema = DBIO::Test->init_schema(no_deploy => 1);
my $undeclared        = T::EQ::Undeclared->new($undeclared_schema);
$undeclared_schema->storage($undeclared);

is $undeclared->_use_supports_exists_query, 0,
  'the storage reads the capability as false';

my $branch = '$storage->_use_supports_exists_query ? $rs->results_exist : $rs->has_rows';

for my $method (qw( results_exist results_exist_as_query results_exist_async )) {
  my $rs = $undeclared_schema->resultset('Artist');
  $undeclared->reset_captured;

  throws_ok { $rs->$method } 'DBIO::Exception',
    "$method throws a typed exception when the capability is false";

  # The async twin throws SYNCHRONOUSLY -- this is a static precondition,
  # decidable without I/O, exactly the class _rs_run_async already throws
  # synchronously for ("not an async connection"). A failed Future here would
  # pass the throws_ok above only if the exception escaped, which it must not.
  throws_ok { $rs->$method }
    qr/\Q$method\E/,
    "$method names the method the caller called";

  throws_ok { $rs->$method }
    qr/T::EQ::Undeclared/,
    "$method names the storage class";

  throws_ok { $rs->$method }
    qr/supports_exists_query/,
    "$method names the capability exactly as a driver declares it";

  throws_ok { $rs->$method }
    qr/has not declared/,
    "$method says why";

  throws_ok { $rs->$method }
    qr/\Q$branch\E/,
    "$method names has_rows and the capability branch";

  is scalar($undeclared->captured_queries), 0,
    "$method throws before any SQL is built or executed";
}

# results_exist_async must die on the spot, not hand back a failed Future --
# a caller that only ever inspects the Future would otherwise never see it.
{
  my $rs = $undeclared_schema->resultset('Artist');
  my $f = eval { $rs->results_exist_async };
  ok !defined $f, 'results_exist_async returns nothing -- it throws synchronously';
}

done_testing;
