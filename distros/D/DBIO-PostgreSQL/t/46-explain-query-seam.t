use strict;
use warnings;

use Test::More;

# karr k48 / core ADR 0040 -- the _explain_query seam, as this driver answers
# it. OFFLINE: no DBI, no DSN, no server; every statement below is one the mock
# storage captured instead of executing.
#
# WHAT THIS FILE IS FOR, and it is not "EXPLAIN renders as the string EXPLAIN":
# explain() must not have SIDE EFFECTS. This driver used to spell the plan
# statement "EXPLAIN ANALYZE", and on PostgreSQL ANALYZE does not merely add
# measured timings to the output -- it RUNS the query. Full runtime, and
# everything the query touches goes with it: nextval() and other volatile
# functions advance, a data-modifying CTE writes, triggers fire. A caller
# asking what the planner intends does not expect its sequence counter to move.
#
# So the assertion that matters is the negative one: the statement this driver
# actually puts on the wire for $rs->explain carries NO ANALYZE. It is made
# against the captured statement rather than against the hook's return value,
# because the hook now owns the whole operation and the statement is the only
# place the side effect could enter.

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;

# --- 1. the old string hook is gone on both sides ---------------------------
#
# ADR 0040 REMOVED _explain_sql -- not deprecated, not aliased -- and put
# _explain_query in its slot. That is why the driver's old
# "EXPLAIN ANALYZE $_[1]" override had to go rather than be retargeted: core
# stopped calling it, so it claimed a behaviour the code no longer had. Pinned
# on both classes, because a re-appearance on either side is the failure this
# test exists to catch: on core it would mean the removal was reverted, on the
# driver it would mean somebody wrote an override that is never called.

ok !DBIO::Storage::DBI->can('_explain_sql'),
  'core has no _explain_sql -- ADR 0040 removed the string hook';

ok !DBIO::PostgreSQL::Storage->can('_explain_sql'),
  '... and this driver carries no dead override of it';

# --- 2. and this driver takes core's base operation -------------------------
#
# The same shape as the _exists_value_sql decision in t/44: a non-override is a
# decision, and identity is how it is asserted. A private override that happened
# to produce the same statement today would still be an undocumented divergence
# -- and it is exactly where an ANALYZE would come back.

is(DBIO::PostgreSQL::Storage->can('_explain_query'),
   DBIO::Storage::DBI->can('_explain_query'),
  'the driver does not override _explain_query -- it takes core\'s base operation');

# --- 3. the statement a PostgreSQL resultset actually issues ----------------

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::PostgreSQL::Storage',
  );
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('Artist')->search({ name => 'foo', rank => 13 });

  $storage->mock(qr/^EXPLAIN /, [ ['Seq Scan on artist  (cost=0.00..1.01 rows=1 width=8)'] ]);
  $storage->reset_captured;

  my $plan = $rs->explain;

  is_deeply $plan, [ ['Seq Scan on artist  (cost=0.00..1.01 rows=1 width=8)'] ],
    'explain returns the plan rows the statement produced';

  my @q = $storage->captured_queries;
  is scalar @q, 1, '... having issued exactly one statement';

  # THE assertion of this file. Not "the SQL equals X" -- an ANALYZE, an
  # (ANALYZE, BUFFERS), a VERBOSE ANALYZE, anywhere in the statement, all mean
  # the same thing: the query ran.
  unlike $q[0]{sql}, qr/\bANALY[SZ]E\b/i,
    '... which does NOT carry ANALYZE -- explain plans the query, it does not run it';

  like $q[0]{sql}, qr/^EXPLAIN SELECT /,
    '... it is a plain EXPLAIN of the resultset\'s SELECT';
  unlike $q[0]{sql}, qr/^\s*\(/,
    '... with the parens as_query wraps its output in stripped off';

  # The binds travelling into the plan statement are the proof the operation
  # went down the storage's statement path at all: the mock captures nothing
  # else, so a hook reaching for $self->dbh would leave this empty (core ADR
  # 0040 section 3, the rule this driver keeps by not overriding).
  is_deeply
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $q[0]{bind} } ],
    [ 'foo', 13 ],
    '... and the query\'s bind values reached it through _execute_rendered';
}

# --- 4. the documented way to get ANALYZE anyway ----------------------------
#
# The seam is a method, not a setting, so there is no option to add and none is
# invented. A caller who genuinely wants measured runtimes overrides
# _explain_query on a storage subclass -- routing through _execute_rendered as
# the contract requires, never $self->dbh -- and connects through it. This is
# the worked example from the POD of DBIO::PostgreSQL::Storage, executed: the
# escape hatch is part of the decision, so a change that closes it fails here
# rather than silently leaving the POD lying.

{
  package T::PgAnalyze::Storage;
  use base 'DBIO::PostgreSQL::Storage';

  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    my (undef, $sth) = $self->_execute_rendered("EXPLAIN ANALYZE $sql", $bind);
    return $sth->fetchall_arrayref;
  }
}
$INC{'T/PgAnalyze/Storage.pm'} = __FILE__;

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'T::PgAnalyze::Storage',
  );
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('Artist')->search({ name => 'foo' });

  $storage->mock(qr/^EXPLAIN ANALYZE /, [ ['Seq Scan on artist (actual time=0.01..0.02 rows=1 loops=1)'] ]);
  $storage->reset_captured;

  my $plan = $rs->explain;
  is_deeply $plan, [ ['Seq Scan on artist (actual time=0.01..0.02 rows=1 loops=1)'] ],
    'a storage subclass CAN opt into ANALYZE, and gets the measured plan back';

  my @q = $storage->captured_queries;
  is scalar @q, 1, '... from exactly one statement';
  like $q[0]{sql}, qr/^EXPLAIN ANALYZE SELECT /,
    '... which is the ANALYZE form the subclass asked for -- opt-in, not default';
  is_deeply
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $q[0]{bind} } ],
    [ 'foo' ],
    '... captured, i.e. it went through _execute_rendered and not the raw dbh';
}

# --- 5. who else has to answer this: nobody ---------------------------------
#
# karr k48 asks whether the dists built on this driver redefine the hook.
# Checked in dbio-postgresql-ev, dbio-postgresql-age and dbio-postgresql-postgis:
# none of them mentions _explain_sql or _explain_query at all. None of them is a
# SUBCLASS either -- the extensions ship storage LAYERS (core karr k70) composed
# in front of this class -- so the mechanism, not the absence, is what is pinned
# here: a composed class resolves the same base operation along its linearised
# @ISA. A synthetic layer stands in for the real ones, because this dist must not
# depend on them.

{
  { package T::PGExplainExt::Storage; sub pg_explain_ext_marker { 'layer' } }

  my $composed = DBIO::Storage::Composed->compose(
    'DBIO::PostgreSQL::Storage', ['T::PGExplainExt::Storage'],
  );

  is $composed->can('_explain_query'), DBIO::Storage::DBI->can('_explain_query'),
    'a composed extension layer resolves the same base _explain_query';
  ok !$composed->can('_explain_sql'),
    '... and no _explain_sql reappears through composition';
}

done_testing;
