use strict;
use warnings;

use Test::More;

# Core ADR 0037 -- the supports_exists_query capability and the
# _exists_value_sql rendering seam, as this driver answers them. OFFLINE: no
# DBI, no DSN, no server. Every answer below is a static class fact plus the
# SQL the mock storage captured; reading them never touches a handle.
#
# What this file is for: the declaration is the ONLY thing standing between
# $rs->results_exist and a typed exception (core defaults the capability to 0
# and all three results_exist* methods throw without it), and it asserts that
# somebody checked the base rendering against PostgreSQL rather than assumed
# it. So both halves are pinned here -- the declaration, and the fact that the
# base rendering is taken unchanged.

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;

# --- the declaration --------------------------------------------------------
#
# Paired with get_inherited(), which is defined only for a value this class set
# itself. Asserting the value alone would pass just as well if the driver
# declared nothing and rested on a core default -- and core's default is 0, so
# that reading would be actively wrong.

is(DBIO::PostgreSQL::Storage->_use_supports_exists_query, 1,
  'supports_exists_query is 1 -- PostgreSQL takes the base EXISTS rendering');

isnt(DBIO::PostgreSQL::Storage->get_inherited('_use_supports_exists_query'), undef,
  '... and the driver states it, rather than inheriting core\'s default');

# --- and NO rendering override ----------------------------------------------
#
# The other half of the ADR 0037 decision, and the half a bare value check
# would miss. PostgreSQL documents both things the base statement needs --
# EXISTS returning a boolean VALUE ("Subquery Expressions": "All of the
# expression forms documented in this section return Boolean (true/false)
# results") and a FROM-less SELECT (SELECT reference, Compatibility:
# "PostgreSQL allows one to omit the FROM clause") -- so the driver overrides
# nothing. Only the engines that refuse a FROM-less SELECT (Oracle, DB2,
# Firebird) append a dummy table.
#
# Identity, not string equality: an override that happened to produce the same
# string today would still be an undocumented divergence to maintain.

is(DBIO::PostgreSQL::Storage->can('_exists_value_sql'),
   DBIO::Storage::DBI->can('_exists_value_sql'),
  'the driver does not override _exists_value_sql -- it takes core\'s base form');

is(DBIO::PostgreSQL::Storage->_exists_value_sql('(SELECT 42 FROM "artist")'),
   'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist") THEN 1 ELSE 0 END',
  '... which is the standard-conforming CASE WHEN EXISTS statement');

# --- end to end, through a real PostgreSQL storage ---------------------------
#
# INTENT: the statement a PostgreSQL resultset actually issues, byte for byte,
# rather than the hook's return value in isolation. Core adds parentheses to
# results_exist_as_query and nothing else; results_exist runs the bare
# statement through _execute_rendered, so the mock captures exactly it.
#
# NOTE what this does NOT prove: the hybrid test storage puts DBIO::Test::Storage
# first in @ISA and that class declares supports_exists_query itself, so the
# capability GATE here would open with or without the driver's declaration.
# The declaration is proven above, on the real class. This block proves the SQL.
{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::PostgreSQL::Storage',
  );
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('Artist')->search({ name => 'foo' });

  my $expected =
    'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me" WHERE ( "name" = ? ))'
  . ' THEN 1 ELSE 0 END';

  my ($frag, @frag_bind) = @{ ${ $rs->results_exist_as_query } };
  is $frag, "( $expected )",
    'results_exist_as_query is the storage rendering in one pair of parens';
  is scalar(@frag_bind), 1, '... carrying the inner query\'s one bind value';
  is $frag_bind[0][1], 'foo', '... which is the searched name';

  $storage->reset_captured;
  is $rs->results_exist, 0, 'results_exist answers from the mocked empty result';

  my @q = $storage->captured_queries;
  is scalar @q, 1, '... having issued exactly one statement';
  is $q[0]{sql}, $expected,
    '... and it is the complete statement, with no derived-table wrapper';
}

# --- who else has to declare this: nobody ------------------------------------
#
# karr k47 asks whether "the subclasses" inherit the declaration. Neither of
# the two families that extend this driver IS a subclass, so the question has
# two different answers and both are pinned here.

# 1. Extension dists (dbio-postgresql-age, dbio-postgresql-postgis) ship storage
#    LAYERS (core karr k70), composed into a class whose @ISA is
#    (@layers, DBIO::PostgreSQL::Storage). The capability accessors are
#    inherited-type class data resolved along the linearised @ISA, so the
#    composed class answers with this driver's declaration -- as a CLASS method,
#    and without the layer mentioning the capability at all. A synthetic layer
#    stands in for the real ones: this dist must not depend on them, and the
#    mechanism under test is core's composition, not any extension's content.
{
  { package T::PGExistsExt::Storage; sub pg_exists_ext_marker { 'layer' } }

  my $composed = DBIO::Storage::Composed->compose(
    'DBIO::PostgreSQL::Storage', ['T::PGExistsExt::Storage'],
  );

  ok !T::PGExistsExt::Storage->can('_use_supports_exists_query'),
    'sanity: the layer is a plain package with no capability accessors';

  is $composed->_use_supports_exists_query, 1,
    'a composed extension layer sees the driver declaration through the base';
  is $composed->can('_exists_value_sql'), DBIO::Storage::DBI->can('_exists_value_sql'),
    '... and resolves the same base rendering';
}

# 2. The async backends are NOT subclasses of this driver either -- they descend
#    from DBIO::Storage::Async and therefore have no capability accessors at
#    all. That is correct, not a gap: async is a per-connection mode on the SYNC
#    storage (core ADR 0030), so results_exist_async probes the capability and
#    renders the statement on DBIO::PostgreSQL::Storage and hands the backend
#    only finished SQL for its _query_async seam. If this ever inverts -- if a
#    backend starts answering results_exist_async itself -- these assertions
#    fail and the declaration has to move or be repeated, deliberately.
SKIP: {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or skip 'DBIO::Async not installed (recommends only)', 3;

  ok(!DBIO::PostgreSQL::Storage::Async->isa('DBIO::PostgreSQL::Storage'),
    'the future_io transport is not a subclass of the driver storage');
  ok(!DBIO::PostgreSQL::Storage::Async->can('_use_supports_exists_query'),
    '... so it carries no supports_exists_query of its own -- and needs none');
  ok(DBIO::PostgreSQL::Storage::Async->can('_query_async'),
    '... the seam core hands it the already-rendered statement on');
}

# ... and the sync/async parity that makes the single declaration sufficient:
# the async twin resolves the IDENTICAL statement, because it is resolved on
# the same storage. In the mock's default 'immediate' mode there is no separate
# backend, so this exercises the resolution, not a transport -- the transport
# round-trip is a live concern and belongs to t/37-future-io-live.t.
{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::PostgreSQL::Storage',
  );
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('Artist')->search({ name => 'foo' });

  $storage->reset_captured;
  my $f = $rs->results_exist_async;
  ok $f->is_ready && !$f->is_failed,
    'results_exist_async resolves in the immediate mode';
  is scalar($f->get), 0, '... with the same answer as the sync call';

  my @q = $storage->captured_queries;
  is scalar @q, 1, '... from exactly one statement';
  is $q[0]{sql},
    'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me" WHERE ( "name" = ? ))'
    . ' THEN 1 ELSE 0 END',
    '... byte-identical to the statement the sync path issues';
}

done_testing;
