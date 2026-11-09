use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

# ADR 0036: $rs->upsert -- the flat, single-table atomic upsert.
#
# Core's job stops at the seam: normalize the caller's options into one
# on_conflict structure and hand it to sql_maker->insert on the same options
# transport RETURNING already rides. Rendering the clause is the driver's job,
# so the engine-specific SQL strings (ON CONFLICT / ON DUPLICATE KEY) are
# tested in the driver dists, never here. What is tested here is the
# structure that crosses the seam, and every refusal that happens before it.

# A stand-in for a driver SQLMaker: it consumes $options->{on_conflict},
# records the structure it was handed, and marks the statement so the
# captured SQL shows the clause was placed by the driver, not by core.
{
  package DBIO::Test::UpsertSQLMaker;
  use base 'DBIO::SQLMaker';
  our @SEEN;

  sub insert {
    my ($self, $table, $data, $options) = @_;

    my $on_conflict = $options ? delete $options->{on_conflict} : undef;
    return $self->next::method($table, $data, $options) unless $on_conflict;

    push @SEEN, $on_conflict;
    my ($sql, @bind) = $self->next::method($table, $data, $options);
    return ("$sql /*CONFLICT*/", @bind);
  }
}

sub upsert_schema {
  my $schema = DBIO::Test->init_schema;
  my $storage = $schema->storage;
  $storage->sql_maker_class('DBIO::Test::UpsertSQLMaker');
  $storage->_use_supports_upsert(1);
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $storage->reset_captured;
  return $schema;
}

# The last on_conflict structure that crossed the seam.
sub last_conflict { $DBIO::Test::UpsertSQLMaker::SEEN[-1] }

my $schema = upsert_schema();
my $rs     = $schema->resultset('Artist');

# --- 1. the structure that crosses the seam ------------------------------

# Default: conflict target is the primary key (the data supplies it), and the
# conflict branch sets every supplied column that is neither target nor PK to
# the value that was attempted to be inserted. Core stays abstract about the
# engine's EXCLUDED / VALUES() token -- it says "the attempted value".
{
  $schema->storage->reset_captured;
  @DBIO::Test::UpsertSQLMaker::SEEN = ();

  $rs->upsert({ artistid => 5, name => 'Aphex Twin', rank => 3 }, { result => 'void' });

  is_deeply last_conflict(), {
    target => ['artistid'],
    action => 'update',
    set    => {
      name => { -attempted => 'name' },
      rank => { -attempted => 'rank' }
    }
  }, 'default: PK target, attempted-value set over the non-key columns';

  my @q = $schema->storage->captured_queries;
  is scalar @q, 1, 'an upsert is exactly one statement';
  is $q[0]{op}, 'insert', 'it rides the insert op';
  like $q[0]{sql}, qr{^INSERT INTO "artist" \("artistid", "name", "rank"\) VALUES \(\?, \?, \?\) /\*CONFLICT\*/$},
    'the statement is a plain INSERT plus whatever the driver appended';
}

# key => names a unique constraint, and travels as BOTH halves: the name for
# an engine that can name a constraint (PostgreSQL's ON CONSTRAINT) and the
# resolved columns for the engines whose grammar knows a column list only
# (SQLite). A SQLMaker gets no ResultSource, so it could not resolve the name
# itself -- with the name alone, key => $constraint is unusable there.
{
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $rs->upsert({ artistid => 5, name => 'x' }, { key => 'artist_artistid', result => 'void' });

  is_deeply last_conflict()->{target},
    { constraint => 'artist_artistid', columns => ['artistid'] },
    'key => $constraint travels as the name AND its resolved columns';
  is_deeply last_conflict()->{set}, { name => { -attempted => 'name' } },
    'the constraint columns are excluded from the default set';
}

# ... and the columns keep the constraint's own order, so a driver can render
# the column list without re-deriving anything.
{
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $rs->upsert(
    { artistid => 5, name => 'x', charfield => 'c', rank => 2 },
    { key => 'u_nullable', result => 'void' }
  );

  is_deeply last_conflict()->{target},
    { constraint => 'u_nullable', columns => [qw/charfield rank/] },
    'a multi-column constraint resolves in its declared column order';
}

# conflict_target => \@cols, on a source whose unique constraint is not the PK
{
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $schema->resultset('CD')->upsert(
    { artist => 1, title => 'Bad', year => 1987 },
    { conflict_target => [qw/artist title/], result => 'void' }
  );

  is_deeply last_conflict(), {
    target => [qw/artist title/],
    action => 'update',
    set    => { year => { -attempted => 'year' } }
  }, 'conflict_target => \@cols travels verbatim';
}

# a single column name is accepted as a one-column target
{
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $rs->upsert({ name => 'x', rank => 2 }, { conflict_target => 'name', result => 'void' });
  is_deeply last_conflict()->{target}, ['name'],
    'a scalar conflict_target is a single-column target';
}

# 'any' is the engine-native "whichever unique collides" -- it must survive as
# itself, because only the driver knows whether its grammar has that shape.
{
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $rs->upsert({ artistid => 5, name => 'x' }, { conflict_target => 'any', result => 'void' });

  is last_conflict()->{target}, 'any', "conflict_target => 'any' travels as itself";
  is_deeply last_conflict()->{set}, { name => { -attempted => 'name' } },
    "with 'any' the PK is still kept out of the update set";
}

# DO NOTHING carries no set at all
{
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $rs->upsert({ artistid => 5, name => 'x' }, { on_conflict => 'nothing', result => 'void' });

  is last_conflict()->{action}, 'nothing', "on_conflict => 'nothing' travels";
  is last_conflict()->{set}, undef, 'DO NOTHING has no update set';
}

# update => \@cols restricts the default set
{
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $rs->upsert(
    { artistid => 5, name => 'x', rank => 2, charfield => 'c' },
    { update => ['rank'], result => 'void' }
  );
  is_deeply last_conflict()->{set}, { rank => { -attempted => 'rank' } },
    'update => \@cols restricts the set to the listed columns';
}

# update => \%exprs replaces the set and passes literals through verbatim, so
# a driver renders "rank = rank + 1" rather than an attempted value
{
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $rs->upsert(
    { artistid => 5, name => 'x' },
    { update => { rank => \'rank + 1', charfield => 'z' }, result => 'void' }
  );
  is_deeply last_conflict()->{set}, { rank => \'rank + 1', charfield => 'z' },
    'update => \%exprs is the set, verbatim';
}

# The conditional conflict branch (ADR 0036). A driver that has never heard
# of it must render exactly the statement it rendered before the option
# existed, so the key is present only when there is a condition.
{
  @DBIO::Test::UpsertSQLMaker::SEEN = ();
  $rs->upsert({ artistid => 5, name => 'x' }, { result => 'void' });

  ok ! exists last_conflict()->{where},
    'no update_where, no where key in the structure at all';
}

# The last-write-wins guard, and the reason the feature exists: "update only
# if the incoming row is newer". Both sides of that comparison are sayable
# without an engine token -- an unqualified column is the stored row, and
# { -attempted => $col } is the value the statement tried to insert, the same
# marker the update set already carries.
{
  my $s = upsert_schema();
  $s->storage->_use_supports_upsert_where(1);

  my $cond = { rank => { '<' => { -attempted => 'rank' } } };
  $s->resultset('Artist')->upsert(
    { artistid => 5, name => 'x', rank => 7 },
    { update_where => $cond, result => 'void' },
  );

  is_deeply last_conflict(), {
    target => ['artistid'],
    action => 'update',
    set    => {
      name => { -attempted => 'name' },
      rank => { -attempted => 'rank' },
    },
    where  => { rank => { '<' => { -attempted => 'rank' } } },
  }, 'update_where travels as a fourth key, next to the set it conditions';

  # core does not look inside: what crosses the seam is the caller's own
  # structure, so a driver renders the condition the caller wrote
  is_deeply last_conflict()->{where}, $cond,
    'the condition crosses the seam unexamined and unrewritten';

  my @q = $s->storage->captured_queries;
  is scalar @q, 1, 'a conditional upsert is still exactly one statement';
}

# A literal is the escape hatch for what the abstract form cannot say. It is
# engine-specific by construction, which is the honest trade -- and it must
# reach the driver verbatim, bind values and all.
{
  my $s = upsert_schema();
  $s->storage->_use_supports_upsert_where(1);

  $s->resultset('Artist')->upsert(
    { artistid => 5, name => 'x' },
    { update_where => \'excluded.rank > artist.rank', result => 'void' },
  );
  is_deeply last_conflict()->{where}, \'excluded.rank > artist.rank',
    'a scalarref literal passes through verbatim';

  $s->resultset('Artist')->upsert(
    { artistid => 5, name => 'x' },
    { update_where => \[ 'artist.rank < ?', 3 ], result => 'void' },
  );
  is_deeply last_conflict()->{where}, \[ 'artist.rank < ?', 3 ],
    'a literal with bind values passes through verbatim too';

  $s->resultset('Artist')->upsert(
    { artistid => 5, name => 'x' },
    { update_where => [ { rank => 1 }, { rank => 2 } ], result => 'void' },
  );
  is_deeply last_conflict()->{where}, [ { rank => 1 }, { rank => 2 } ],
    'an arrayref condition (SQL::Abstract OR) is accepted and travels as-is';
}

# --- 2. return shapes ----------------------------------------------------

# row_or_undef with an engine that names the row (here: RETURNING, mocked)
{
  my $s = upsert_schema();
  $s->storage->_use_insert_returning(1);
  $s->storage->mock(qr/INSERT INTO "artist"/, [ [ 42 ] ]);

  my $row = $s->resultset('Artist')->upsert({ name => 'Named', rank => 1 },
    { conflict_target => 'name' });

  isa_ok $row, 'DBIO::Test::Schema::Artist', 'row_or_undef returns a Result';
  is $row->artistid, 42, 'the identity the engine returned is folded in';
  ok $row->in_storage, 'the returned Result is marked stored';
  ok !$row->is_changed, 'and clean';

  # this pins the RETURNING tail as really being emitted here, which is what
  # makes the "no RETURNING" assertions for count / void below mean something
  my @q = $s->storage->captured_queries;
  like $q[0]{sql}, qr/RETURNING "artistid"/,
    'the row shapes do ask the engine for the identity';
}

# count hands back the statement return value, and asks for no identity work
{
  my $s = upsert_schema();
  $s->storage->_use_insert_returning(1);

  my $count = $s->resultset('Artist')->upsert({ name => 'Named', rank => 1 },
    { conflict_target => 'name', result => 'count' });

  is $count, 1, 'result => count returns the affected-row count';

  my @q = $s->storage->captured_queries;
  is scalar @q, 1, 'still one statement';
  unlike $q[0]{sql}, qr/RETURNING/i,
    'result => count spends no RETURNING tail on an identity nobody asked for';
}

# A conflicting upsert can legitimately affect no row at all (DO NOTHING on
# PG/SQLite, an update that changed no value on MySQL). DBI reports that as
# the string '0E0' -- numerically zero, boolean TRUE -- and handing that on
# would make "if (my $n = $rs->upsert(...))" true for "nothing happened".
# upsert throws on failure, so zero-but-true carries no information here.
{
  my $s = upsert_schema();
  $s->storage->_use_insert_returning(1);
  $s->storage->mock_affected_rows('0E0');

  my $count = $s->resultset('Artist')->upsert({ name => 'Named', rank => 1 },
    { conflict_target => 'name', result => 'count' });

  is $count, 0, 'a statement that affected no rows counts as a plain 0';
  ok !$count, "... and is false -- DBI's '0E0' never reaches the caller";
}

# void returns nothing and buys nothing: one round-trip, no RETURNING tail,
# no follow-up SELECT
{
  my $s = upsert_schema();
  $s->storage->_use_insert_returning(1);

  my @ret = $s->resultset('Artist')->upsert({ name => 'Named', rank => 1 },
    { conflict_target => 'name', result => 'void' });

  is scalar @ret, 0, 'result => void returns nothing';

  my @q = $s->storage->captured_queries;
  is scalar @q, 1, 'result => void is exactly one round-trip';
  unlike $q[0]{sql}, qr/RETURNING/i, 'result => void emits no RETURNING tail';
}

# The engine cannot always name what it wrote. A source with no primary key
# is the engine-independent instance of that: nothing identifies the row.
# Passing result explicitly is the documented way to silence the warning, so
# check the silent case first -- carp_once only fires once per message.
{
  my $s = upsert_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $row = $s->resultset('NoPrimaryKey')->upsert(
    { foo => 1, bar => 2, baz => 3 },
    { conflict_target => [qw/foo bar/], result => 'row_or_undef' }
  );

  is $row, undef, 'row_or_undef is undef when the written row cannot be named';
  is scalar @warnings, 0,
    'an explicitly passed result => row_or_undef silences the warning';
}

# DO NOTHING hitting an existing row is the other way to get undef, and it is
# nothing like the one above: RETURNING yields zero rows because no row was
# written, exactly as asked for. Telling the caller the engine "could not name
# the row it wrote" would be false -- nothing was written.
{
  my $s = upsert_schema();
  $s->storage->_use_insert_returning(1);
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  # no mock: the INSERT ... RETURNING comes back with zero rows, which is what
  # a conflicting DO NOTHING does on PostgreSQL / SQLite
  my $row = $s->resultset('Artist')->upsert(
    { name => 'Already there', rank => 1 },
    { conflict_target => 'name', on_conflict => 'nothing' }
  );

  is $row, undef, "on_conflict => 'nothing' returns undef when nothing was written";
  is scalar @warnings, 0,
    'and does not warn about an identity that was never promised';
}

# ... and without an explicit result, the default has to teach the caller,
# because the default is the one value nobody ever types.
{
  my $s = upsert_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $row = $s->resultset('NoPrimaryKey')->upsert(
    { foo => 1, bar => 2, baz => 3 },
    { conflict_target => [qw/foo bar/] }
  );

  is $row, undef, 'the default result is row_or_undef';
  is scalar @warnings, 1, 'the unnameable path warns once';
  like $warnings[0], qr/could not name the row it wrote/,
    'the warning says what happened';
  like $warnings[0], qr/NoPrimaryKey/, 'and names the source';
}

# row_or_die keeps its name exact: no row means an exception, not undef
{
  my $s = upsert_schema();
  throws_ok {
    $s->resultset('NoPrimaryKey')->upsert(
      { foo => 1, bar => 2, baz => 3 },
      { conflict_target => [qw/foo bar/], result => 'row_or_die' }
    );
  } qr/row_or_die.*did not name it/s,
    'row_or_die throws where row_or_undef would return undef';
}

# --- 3. the capability gate ----------------------------------------------

# No capability, no upsert. Never a silent client-side two-step: that is the
# exact over-promise this feature exists to stop making.
{
  my $s = DBIO::Test->init_schema;
  is $s->storage->_use_supports_upsert, 0, 'stock storage has no atomic upsert';

  throws_ok {
    $s->resultset('Artist')->upsert({ artistid => 5, name => 'x' });
  } qr/does not declare the supports_upsert capability/,
    'upsert throws on an engine without the capability';

  is scalar($s->storage->captured_queries), 0, 'and issued no statement at all';
}

# The conditional branch has a capability of its own, and this is why: it is
# the only part of the structure a driver can drop without a symptom. A
# missing conflict target is invalid SQL on PostgreSQL, an ignored DO NOTHING
# leaves no set to write -- but a dropped WHERE renders a perfectly valid
# unconditional UPDATE, which is the overwrite the caller wrote the condition
# to prevent. So a driver that renders conflict clauses is still not handed
# one until it says it renders conditions.
{
  my $s = upsert_schema();
  is $s->storage->_use_supports_upsert, 1, 'this storage does have upsert';
  is $s->storage->_use_supports_upsert_where, 0,
    '... and does not claim to render conditional ones';

  throws_ok {
    $s->resultset('Artist')->upsert(
      { artistid => 5, name => 'x' },
      { update_where => { rank => 1 } },
    );
  } qr/does not declare the supports_upsert_where capability/,
    'update_where throws on a driver that renders no condition';

  is scalar($s->storage->captured_queries), 0,
    '... rather than silently writing unconditionally';
}

# The gates are ordered, and the order is load-bearing. ADR 0036
# section 3 pins supports_upsert_where as a fact about the conditional branch
# alone -- never derived from supports_upsert -- and one of the reasons is
# that a second flag reporting the same 0 would add nothing diagnostically:
# whatever closed the upsert gate is already named there. That argument only
# holds while supports_upsert is checked FIRST, so a conditional upsert on an
# engine with no atomic upsert at all must be blamed on the missing upsert,
# not on the missing condition -- the caller has to drop far more than the
# update_where.
sub upsert_error {
  my ($s, %opts) = @_;
  local $@;
  eval {
    $s->resultset('Artist')->upsert({ artistid => 5, name => 'x' }, \%opts);
  };
  return "$@";
}

{
  my $s = DBIO::Test->init_schema;
  is $s->storage->_use_supports_upsert, 0, 'neither capability is declared';
  is $s->storage->_use_supports_upsert_where, 0, '... including the where flag';

  my $err = upsert_error($s, update_where => { rank => 1 });
  like $err, qr/does not declare the supports_upsert capability/,
    'a conditional upsert on an engine without upsert names the upsert gate';
  unlike $err, qr/supports_upsert_where/,
    '... and not the second gate behind it';

  is scalar($s->storage->captured_queries), 0, 'and issued no statement';
}

# Declaring the where flag alone is a legal state, not a contradiction: it
# says the SQL generator renders the conditional branch, and says nothing
# about why the upsert gate is shut (PostgreSQL's also requires RETURNING,
# which is about naming the written row -- something a condition that does not
# hold has no need of, as it writes no row). Core's answer is unchanged.
{
  my $s = DBIO::Test->init_schema;
  $s->storage->_use_supports_upsert_where(1);
  is $s->storage->_use_supports_upsert, 0,
    'declaring supports_upsert_where does not turn on supports_upsert';

  my $err = upsert_error($s, update_where => { rank => 1 });
  like $err, qr/does not declare the supports_upsert capability/,
    'the shut gate is still the one reported';
  unlike $err, qr/supports_upsert_where/,
    '... not the flag the driver declared';

  is scalar($s->storage->captured_queries), 0, 'and still no statement';
}

# The explicit, per-call escape hatch. The caller asked for the race, so it
# runs without a warning -- and the return mapping is pinned so the same call
# does not change return *type* with the engine.
{
  my $s = DBIO::Test->init_schema;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $row = $s->resultset('Artist')->upsert(
    { artistid => 5, name => 'Fallback' },
    { fallback => 'update_or_create' }
  );

  isa_ok $row, 'DBIO::Test::Schema::Artist',
    'fallback => update_or_create satisfies row_or_undef';
  is scalar @warnings, 0, 'an explicitly requested fallback does not warn';

  is $s->resultset('Artist')->upsert(
    { artistid => 6, name => 'Fallback' },
    { fallback => 'update_or_create', result => 'count' }
  ), 1, 'the fallback reports a synthetic count of 1';

  my @void = $s->resultset('Artist')->upsert(
    { artistid => 7, name => 'Fallback' },
    { fallback => 'update_or_create', result => 'void' }
  );
  is scalar @void, 0, 'the fallback honours result => void';

  isa_ok $s->resultset('Artist')->upsert(
    { artistid => 8, name => 'Fallback' },
    { fallback => 'update_or_create', result => 'row_or_die' }
  ), 'DBIO::Test::Schema::Artist', 'the fallback satisfies row_or_die';
}

# The fallback has to look the row up by the constraint the atomic statement
# would have conflicted on. With no target given that is the primary key --
# find()'s heuristics mode would instead OR every satisfiable unique
# constraint together, so a row matching on 'name' alone would be updated
# where the atomic path would have inserted.
{
  my $s = DBIO::Test->init_schema;
  $s->storage->reset_captured;

  $s->resultset('Artist')->upsert(
    { artistid => 9, name => 'Fallback' },
    { fallback => 'update_or_create' }
  );

  my ($lookup) = grep { $_->{op} eq 'select' } $s->storage->captured_queries;
  ok $lookup, 'the fallback does look the row up first (it is the racy path)';

  my ($where) = ($lookup->{sql} || '') =~ /\bWHERE\b(.*)\z/s;
  like $where, qr/\bartistid\b/,
    'the fallback lookup targets the primary key, as the atomic path would';
  unlike $where, qr/\bname\b/,
    'and only the primary key -- not an OR over every unique constraint';
}

# --- 4. every refusal ----------------------------------------------------

my $usc = upsert_schema();
my $urs = $usc->resultset('Artist');

throws_ok { $urs->upsert() } qr/non-empty hashref of column data/,
  'upsert without data throws';

throws_ok { $urs->upsert({}) } qr/non-empty hashref of column data/,
  'upsert with empty data throws';

throws_ok { $urs->upsert([ artistid => 1 ]) } qr/non-empty hashref of column data/,
  'upsert with a non-hashref throws';

throws_ok { $urs->upsert({ artistid => 1 }, [ 'key' ]) }
  qr/hashref of options/, 'a non-hashref options argument throws';

throws_ok { $urs->upsert({ artistid => 1 }, { keys => 'artist' }) }
  qr/unknown option\(s\) 'keys'/, 'a mistyped option is caught, not ignored';

# relations belongs to the cascade (t/resultset/upsert_cascade.t). Naming a
# relationship the data does not nest is a typo on the flat path: the caller
# believes a cascade is happening and none is.
throws_ok { $urs->upsert({ artistid => 1, name => 'x' }, { relations => { cds => {} } }) }
  qr/relations names 'cds', but %col_data has no nested data/,
  'a per-relation target with no nested part to apply it to throws';

throws_ok { $urs->upsert({ artistid => 1, name => 'x' }, { relations => [] }) }
  qr/relations must be a hashref/, 'a nonsense relations option throws';

throws_ok { $urs->upsert({ artistid => 1 }, { on_conflict => 'replace' }) }
  qr/on_conflict must be 'update' or 'nothing'/, 'an unknown on_conflict throws';

throws_ok { $urs->upsert({ artistid => 1 }, { result => 'row' }) }
  qr/result must be one of/,
  "there is deliberately no plain 'row' return shape";

throws_ok { $urs->upsert({ artistid => 1 }, { result => 'row_or_count' }) }
  qr/result must be one of/, 'an unknown result shape throws';

# row_or_die promises a row; DO NOTHING exists in order to possibly write
# none. Refused at option-validation time, before any SQL is built.
throws_ok {
  $urs->upsert({ artistid => 1 }, { result => 'row_or_die', on_conflict => 'nothing' })
} qr/row_or_die.*cannot be combined with.*'nothing'/s,
  "row_or_die refuses on_conflict => 'nothing' up front";

throws_ok { $urs->upsert({ artistid => 1 }, { fallback => 'find_or_create' }) }
  qr/only supported fallback is 'update_or_create'/,
  'an unknown fallback throws';

# --- update_where: the shape, and the combinations in which a condition on
# --- the conflict branch cannot mean anything. All before any SQL is built,
# --- and all on a storage that HAS the capability, so none of them is an
# --- engine difference in disguise.

my $uws = upsert_schema();
$uws->storage->_use_supports_upsert_where(1);
my $uwrs = $uws->resultset('Artist');

throws_ok { $uwrs->upsert({ artistid => 1, name => 'x' }, { update_where => 'rank < 1' }) }
  qr/update_where must be a SQL::Abstract condition/,
  'a bare string is not a condition -- a forgotten backslash is caught, not run';

throws_ok { $uwrs->upsert({ artistid => 1, name => 'x' }, { update_where => sub { 1 } }) }
  qr/update_where must be a SQL::Abstract condition/,
  'nor is anything else that is not a cond or a literal';

# An empty condition is what a condition built from an empty variable looks
# like, and it would write unconditionally -- the one outcome the option
# exists to prevent.
throws_ok { $uwrs->upsert({ artistid => 1, name => 'x' }, { update_where => {} }) }
  qr/update_where is empty/, 'an empty hashref condition throws';

throws_ok { $uwrs->upsert({ artistid => 1, name => 'x' }, { update_where => [] }) }
  qr/update_where is empty/, 'an empty arrayref condition throws';

throws_ok {
  $uwrs->upsert({ artistid => 1, name => 'x' },
    { on_conflict => 'nothing', update_where => { rank => 1 } })
} qr/update_where has no meaning with on_conflict => 'nothing'/,
  'there is no update branch to condition when the action is DO NOTHING';

# The same class of refusal as row_or_die + DO NOTHING: a conditional update
# exists in order to possibly write nothing. Refused at option-validation
# time rather than at runtime -- the runtime throw blames the table shape,
# which would be exactly the wrong diagnosis for a condition that held false.
throws_ok {
  $uwrs->upsert({ artistid => 1, name => 'x' },
    { result => 'row_or_die', update_where => { rank => 1 } })
} qr/row_or_die.*cannot be combined with update_where/s,
  'row_or_die refuses a conditional update up front';

throws_ok {
  $uwrs->upsert({ artistid => 1, name => 'x' },
    { fallback => 'update_or_create', update_where => { rank => 1 } })
} qr/fallback.*cannot express update_where/s,
  'the fallback refuses a condition rather than writing over it unconditionally';

is scalar($uws->storage->captured_queries), 0,
  'not one of the update_where refusals issued a statement';

# The fallback must not quietly mean something else than the atomic path.
throws_ok {
  $urs->upsert({ artistid => 1 }, { fallback => 'update_or_create', on_conflict => 'nothing' })
} qr/fallback.*cannot express.*'nothing'/s,
  "the fallback refuses on_conflict => 'nothing' rather than writing anyway";

throws_ok {
  $urs->upsert({ artistid => 1, name => 'x' },
    { fallback => 'update_or_create', update => ['name'] })
} qr/fallback.*cannot express a restricted/s,
  'the fallback refuses a restricted update set rather than writing everything';

# update_or_create finds by a *named* constraint, so a column list has no
# expression on the fallback path. Dropping it silently is what made the
# fallback aim at another constraint than the atomic statement.
throws_ok {
  $urs->upsert({ artistid => 1, name => 'x', rank => 2 },
    { fallback => 'update_or_create', conflict_target => ['name'] })
} qr/fallback.*cannot express conflict_target/s,
  'the fallback refuses conflict_target rather than targeting another constraint';

throws_ok {
  $urs->upsert({ artistid => 1, name => 'x', rank => 2 },
    { fallback => 'update_or_create', conflict_target => ['name'] })
} qr/key => \$constraint/,
  '... and the message names the way to ask for a fallback with a target';

# the refusal is engine-independent: it fires on a storage that HAS the
# capability too, where the fallback would never engage
throws_ok {
  $urs->upsert({ artistid => 1, name => 'x', rank => 2 },
    { fallback => 'update_or_create', conflict_target => 'any' })
} qr/fallback.*cannot express conflict_target/s,
  'including on an engine whose fallback would never run';

throws_ok {
  $urs->upsert({ artistid => 1 }, { key => 'artist_artistid', conflict_target => ['artistid'] })
} qr/mutually exclusive/, 'key and conflict_target are mutually exclusive';

# Nested data is the cascading upsert and lives in t/resultset/upsert_cascade.t.
# What belongs here is that the flat path recognises it as nested rather than
# flattening or dropping it: without a per-relation target it is refused by the
# same three-way rule the flat target obeys, naming the part.
throws_ok {
  $usc->resultset('CD')->upsert({ title => 'x', year => 1, artist => { name => 'y' } })
} qr/for Artist for the nested 'artist'/,
  'a nested belongs_to hashref is routed to the cascade, not flattened';

throws_ok {
  $urs->upsert({ artistid => 1, name => 'x', cds => [ { title => 'y' } ] })
} qr/for CD for the nested 'cds'/,
  'a nested has_many arrayref is routed to the cascade too';

$usc->storage->reset_captured;
throws_ok { $urs->upsert({ artistid => 1 }, { key => 'no_such_constraint' }) }
  qr/Unknown unique constraint no_such_constraint/,
  'an unknown constraint name throws';
is scalar($usc->storage->captured_queries), 0,
  '... resolving the constraint, and failing, happens before any SQL is built';

throws_ok { $urs->upsert({ artistid => 1 }, { conflict_target => ['nope'] }) }
  qr/conflict_target column 'nope' is not a column/,
  'a conflict_target column that does not exist throws';

throws_ok { $urs->upsert({ artistid => 1 }, { conflict_target => [] }) }
  qr/conflict_target is an empty list/, 'an empty conflict_target throws';

throws_ok { $urs->upsert({ artistid => 1 }, { conflict_target => 'nope' }) }
  qr/conflict_target 'nope' is not a column/,
  'a scalar conflict_target that is not a column throws, and points at key';

throws_ok { $urs->upsert({ artistid => 1 }, { conflict_target => { c => 1 } }) }
  qr/conflict_target must be an arrayref/, 'a nonsense conflict_target throws';

# Defaulting to the PK is only safe when the data actually supplies it.
# Otherwise the statement could never collide and would silently become a
# plain INSERT -- a feature doing nothing, with no error to show for it.
throws_ok { $urs->upsert({ name => 'x', rank => 1 }) }
  qr/does not supply the primary key of Artist \(missing: artistid\)/,
  'no target and no PK value in the data throws';

# ... and a source without a primary key has nothing to default to at all.
# Guessing among the unique constraints is deliberately not done.
throws_ok { $usc->resultset('NoPrimaryKey')->upsert({ foo => 1, bar => 2 }) }
  qr/has no primary key, so there is no conflict target to default to/,
  'a source without a PK throws instead of picking a unique constraint';

throws_ok { $urs->upsert({ artistid => 1, name => 'x' }, { update => ['nope'] }) }
  qr/update column 'nope' is not a column/, 'an unknown update column throws';

throws_ok { $urs->upsert({ artistid => 1, name => 'x' }, { update => ['rank'] }) }
  qr/update column 'rank' is not among the values being inserted/,
  'an update column with no attempted value to set it to throws';

throws_ok { $urs->upsert({ artistid => 1, name => 'x' }, { update => { nope => 1 } }) }
  qr/update column 'nope' is not a column/,
  'an unknown update column throws in the hashref form too';

throws_ok { $urs->upsert({ artistid => 1, name => 'x' }, { update => 'rank' }) }
  qr/update must be an arrayref of columns or a hashref/,
  'a nonsense update option throws';

throws_ok {
  $urs->upsert({ artistid => 1 }, { on_conflict => 'nothing', update => ['name'] })
} qr/'update' option has no meaning with on_conflict => 'nothing'/,
  "update combined with DO NOTHING throws instead of being ignored";

# Nothing left to set is not an empty UPDATE, it is a DO NOTHING the caller
# did not ask for -- and invalid SQL on every engine.
throws_ok { $urs->upsert({ artistid => 1 }) }
  qr/conflict branch would set no column at all/,
  'an update whose set would be empty throws and names the alternative';

throws_ok { $urs->upsert({ artistid => 1, name => 'x' }, { update => [] }) }
  qr/conflict branch would set no column at all/,
  'an explicitly empty update set throws';

# unknown columns are rejected by the same path create() uses
throws_ok { $urs->upsert({ artistid => 1, nosuchcol => 2 }) }
  qr/No such column/i, 'an unknown column in the data throws';

done_testing;
