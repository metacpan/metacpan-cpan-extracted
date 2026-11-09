use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBIO::Test ':DiffSQL';

# Offline test of _set_operation_keyword (ADR 0039). The hook is a static
# class fact by contract -- no $dbh, no version probe -- so a test that needed
# a database would be testing the wrong thing.

use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::Sybase::Storage::ASE',
  no_deploy    => 1,
  quote_names  => 1,
);
my $storage = $schema->storage;

# --- the four ASE has, inherited from the base map ------------------------

my %ansi = (
  union     => 'UNION',
  union_all => 'UNION ALL',
  intersect => 'INTERSECT',
  except    => 'EXCEPT',
);

is( $storage->_set_operation_keyword($_), $ansi{$_},
  "$_ falls through to next::method and keeps the ANSI spelling" )
  for sort keys %ansi;

# ASE takes minus as an interchangeable synonym for except, so the ANSI
# spelling is a real choice and not an accident of inheritance -- pinned so a
# later author does not "fix" except into MINUS the way Oracle needs.
is( $storage->_set_operation_keyword('except'), 'EXCEPT',
  'except stays EXCEPT rather than ASE\'s equally valid MINUS synonym' );

# --- the two it has never had, refused unconditionally --------------------

for my $op (qw/intersect_all except_all/) {
  throws_ok { $storage->_set_operation_keyword($op) }
    qr/Sybase ASE has no \Q$op\E/,
    "$op is refused, naming the engine and the operation";

  throws_ok { $storage->_set_operation_keyword($op) }
    qr/unconditional/,
    '... and says the refusal is unconditional (ADR 0039 section 7)';

  throws_ok { $storage->_set_operation_keyword($op) }
    qr/not a version compromise/,
    '... explicitly, because the engine fact is unconditional too';
}

throws_ok { $storage->_set_operation_keyword('except_all') }
  qr/->except\(\)/,
  'the message names except() as the nearest operation';

throws_ok { $storage->_set_operation_keyword('except_all') }
  qr/not a substitute/,
  '... while refusing to pass it off as an equivalent (ADR 0039 section 3)';

# --- the two that ARE version-bounded: 16.0 SP03 --------------------------
#
# ADR 0039 section 7 option (b), with the polarity the engine fact dictates.
# intersect and except are NEW in 16.0 SP03, so the servers that lack them are
# the old ones and the default has to be "available" -- defaulting to a
# refusal would take two working operations away from every currently
# supported ASE in order to protect legacy installs.

is( DBIO::Sybase::Storage::ASE->_use_intersect_except, 1,
  'intersect/except default to available (ASE 16.0 SP03 or newer)' );

{
  # per-instance, so nothing leaks into the assertions above or below
  $storage->_use_intersect_except(0);

  for my $op (qw/intersect except/) {
    throws_ok { $storage->_set_operation_keyword($op) }
      qr/Sybase ASE gained \Q$op\E only in version 16\.0 SP03/,
      "$op is refused once the deployment declares a pre-SP03 server";

    throws_ok { $storage->_set_operation_keyword($op) }
      qr/_use_intersect_except/,
      '... naming the declaration that caused it, so it can be undone';
  }

  # the ALL family stays refused for its own, different reason
  throws_ok { $storage->_set_operation_keyword('except_all') }
    qr/unconditional/,
    'and the ALL family is still refused unconditionally, not by the flag';

  # union is not gated at all -- it predates the boundary by decades
  is( $storage->_set_operation_keyword('union'), 'UNION',
    'union is untouched by the opt-out' );
  is( $storage->_set_operation_keyword('union_all'), 'UNION ALL',
    '... and so is union_all' );

  $storage->_use_intersect_except(1);
}

is( $storage->_set_operation_keyword('except'), 'EXCEPT',
  'and the opt-out was per-instance: the default is back' );

# --- an unknown or undefined op is a core programming error ---------------
#
# This is what proves the override hands everything it has no opinion about to
# next::method rather than owning the whole map.

throws_ok { $storage->_set_operation_keyword('sideways_join') }
  qr/Unknown set operation/,
  'an unrecognised operation reaches core\'s base throw through next::method';

throws_ok { $storage->_set_operation_keyword(undef) }
  qr/Unknown set operation/,
  'and so does an undefined one, without warning on the way down';

# --- the ASE facts must not reach the Microsoft SQL Server path -----------
#
# DBIO::MSSQL::Storage::Sybase is @ISA (DBIO::Sybase::Storage,
# DBIO::MSSQL::Storage) under c3, so the shared dispatcher linearises AHEAD of
# the MSSQL half: an override on DBIO::Sybase::Storage would shadow the MSSQL
# refusal on a class that talks DBD::Sybase to Microsoft SQL Server, where an
# ASE engine fact is simply the wrong answer. This driver's opinions therefore
# live on ::ASE only. dbio-mssql's t/55-set-operations.t asserts the same
# thing from its side; this is the assertion that fails first, here.

isnt( DBIO::Sybase::Storage::ASE->can('_set_operation_keyword'),
  DBIO::Storage::DBI->can('_set_operation_keyword'),
  'the ASE class does override the hook' );

is( DBIO::Sybase::Storage->can('_set_operation_keyword'),
  DBIO::Storage::DBI->can('_set_operation_keyword'),
  '... and the shared DBD::Sybase dispatcher deliberately does not' );

SKIP: {
  skip 'DBIO::MSSQL not installed (not a dependency)', 2
    unless eval { require DBIO::MSSQL::Storage::Sybase; 1 };

  # Stated as two assertions on purpose. The second one is vacuously true
  # against an installed DBIO::MSSQL that has no override of its own yet (both
  # sides then resolve to core); the first stays meaningful either way.
  isnt( DBIO::MSSQL::Storage::Sybase->can('_set_operation_keyword'),
    DBIO::Sybase::Storage::ASE->can('_set_operation_keyword'),
    'MSSQL-over-DBD::Sybase does not resolve the hook to the ASE override' );

  is( DBIO::MSSQL::Storage::Sybase->can('_set_operation_keyword'),
    DBIO::MSSQL::Storage->can('_set_operation_keyword'),
    '... it resolves to whatever DBIO::MSSQL::Storage says' );
}

# --- end to end: the keyword reaches the SQL, the refusal reaches nothing --

my $a = $schema->resultset('Artist')->search({ name => 'a' });
my $b = $schema->resultset('Artist')->search({ name => 'b' });

my $cols = '[me].[artistid], [me].[name], [me].[rank], [me].[charfield]';

for my $op (sort keys %ansi) {
  is_same_sql_bind(
    $a->$op($b)->as_query,
    "( SELECT $cols FROM (
         SELECT $cols FROM [artist] [me] WHERE ( [name] = ? )
         $ansi{$op}
         SELECT $cols FROM [artist] [me] WHERE ( [name] = ? )
       ) [me] )",
    [ map { [ { sqlt_datatype => 'varchar', sqlt_size => 100,
                dbic_colname => 'name' } => $_ ] } qw/a b/ ],
    "$op emits $ansi{$op} between the operands",
  );
}

# ADR 0039 section 4: the keyword is resolved before a single operand is
# rendered, so a refused operation throws at query-build time and issues no
# SQL at all. Asserting the empty query log is the only way to tell that apart
# from throwing after the fragment was already built.
for my $op (qw/intersect_all except_all/) {
  $storage->reset_captured;

  throws_ok { $a->$op($b)->as_query } qr/Sybase ASE has no \Q$op\E/,
    "\$rs->$op throws while the query is being built";

  is scalar($storage->captured_queries), 0, '... having issued no SQL';
}

done_testing;
