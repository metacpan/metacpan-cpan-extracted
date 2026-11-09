use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test ':DiffSQL';

# ADR 0036 -- the atomic upsert. Two halves are pinned here.
#
# The SQL half: DBIO::SQLite::SQLMaker renders the ON CONFLICT tail between the
# VALUES list and RETURNING, translating core's engine-neutral
# { -attempted => $col } into SQLite's excluded.<col>. A hashref target is
# upsert's key => $constraint, which core resolves to its columns before
# handing it down (core k104); SQLite renders those columns, since its
# grammar has no ON CONSTRAINT form. The shape it cannot express ('any' with
# DO UPDATE) has to throw rather than emit something plausible-looking.
#
# The capability half is the reason the version gate is 3.35 and not 3.24, and
# it is a correctness question, not a performance one: core names the written
# row with last_insert_id() plus a SELECT on the PRIMARY KEY and never re-finds
# by conflict target. An upsert taking the DO UPDATE branch inserts nothing, so
# last_insert_rowid() still reports the PREVIOUS insert -- without RETURNING
# core would hand back an unrelated row. supports_upsert is therefore tied to
# insert_returning, and the live section below writes an unrelated row in
# between precisely so that a regression there produces a wrong artistid.

my $schema  = DBIO::SQLite::Test->init_schema( no_populate => 1 );
my $storage = $schema->storage;
my $rs      = $schema->resultset('Artist');

my $server_info    = $storage->_server_info;
my $server_version = $server_info->{normalized_dbms_version};
my $has_returning  = ( $server_version >= '3.035' ) ? 1 : 0;

note "libsqlite $server_info->{dbms_version} (normalized $server_version)";

# ---------------------------------------------------------------- capability

is (
  $storage->_use_supports_upsert,
  $has_returning,
  'supports_upsert follows the linked libsqlite (3.35, the RETURNING gate -- '
. 'not 3.24, where the ON CONFLICT grammar arrived)',
);

is (
  $storage->_use_supports_upsert,
  $storage->_use_insert_returning,
  'supports_upsert and insert_returning are declared together',
);

{
  # The gate is on the *effective* capability, not on the libsqlite version a
  # second time: with RETURNING switched off, core falls back to
  # last_insert_id + a SELECT on the PK, which cannot name the row a DO UPDATE
  # wrote. Claiming upsert there would hand back a wrong row.
  $storage->_use_insert_returning(0);
  is (
    $storage->_determine_supports_supports_upsert,
    0,
    'supports_upsert is withdrawn when insert_returning is switched off',
  );

  $storage->_use_insert_returning(1);
  is (
    $storage->_determine_supports_supports_upsert,
    1,
    'supports_upsert is declared when insert_returning is in effect',
  );

  $storage->_use_insert_returning(undef);
}

# supports_upsert_where -- the conditional DO UPDATE branch (core k105). It is
# deliberately NOT tied to the RETURNING gate the way supports_upsert is: that
# gate exists to name the written row, and a condition that does not hold
# writes no row by design, which is why core refuses result => 'row_or_die'
# together with update_where up front. SQLite's DO UPDATE ... WHERE arrived
# with the ON CONFLICT grammar itself in 3.24, so no version is left to test
# either -- what remains is a plain fact about the SQL generator.
is (
  $storage->_use_supports_upsert_where,
  1,
  'supports_upsert_where is declared unconditionally -- the clause is coeval '
. 'with the ON CONFLICT grammar, so it has no gate of its own',
);

{
  $storage->_use_insert_returning(0);
  is (
    $storage->_determine_supports_supports_upsert_where,
    1,
    'and it does not follow insert_returning: the RETURNING gate is about '
  . 'naming the written row, which a suppressed write has no need of',
  );
  $storage->_use_insert_returning(undef);
}

# ------------------------------------------------------------------ SQL shape

my $sm = $storage->sql_maker;

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 2 }, {} ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)',
  [ [ name => 'x' ], [ rank => 2 ] ],
  'an insert without on_conflict is untouched',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 2 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"',
  [ [ name => 'x' ], [ rank => 2 ] ],
  'DO UPDATE renders -attempted as excluded.<col>',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { charfield => 'c', name => 'x', rank => 1 }, {
    on_conflict => {
      target => [ qw( charfield rank ) ],
      action => 'update',
      set    => { name => { -attempted => 'name' } },
    },
  } ) ),
  'INSERT INTO "artist" ("charfield", "name", "rank") VALUES (?, ?, ?)'
. ' ON CONFLICT ("charfield", "rank") DO UPDATE SET "name" = excluded."name"',
  [ [ charfield => 'c' ], [ name => 'x' ], [ rank => 1 ] ],
  'a multi-column conflict target is quoted and comma-joined',
);

{
  # key => $constraint. Core resolves the name once and sends both halves, so
  # the SQLMaker never has to resolve anything: it renders the columns. The
  # point of the test is that the two spellings of one target are one
  # statement -- compare them directly rather than against a literal, so the
  # claim cannot rot into "both happen to match the same stale expectation".
  my $on_conflict = sub {
    return {
      target => shift,
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
    };
  };

  my ($key_sql, @key_bind) = $sm->insert( 'artist', { name => 'x', rank => 2 }, {
    on_conflict => $on_conflict->({
      constraint => 'artist_name',
      columns    => [ 'name' ],
    }),
  } );

  my ($cols_sql, @cols_bind) = $sm->insert( 'artist', { name => 'x', rank => 2 }, {
    on_conflict => $on_conflict->([ 'name' ]),
  } );

  is_same_sql_bind (
    $key_sql, \@key_bind,
    'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
  . ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"',
    [ [ name => 'x' ], [ rank => 2 ] ],
    'a resolved constraint target renders as its column list',
  );

  is (
    $key_sql,
    $cols_sql,
    'key => $constraint and conflict_target => \@columns produce byte-identical '
  . 'SQL -- the constraint name reaches SQLite only as its resolved columns',
  );

  is_deeply (\@key_bind, \@cols_bind, '... with identical bind values');
}

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { charfield => 'c', name => 'x', rank => 1 }, {
    on_conflict => {
      target => {
        constraint => 'u_nullable',
        columns    => [ qw( charfield rank ) ],
      },
      action => 'update',
      set    => { name => { -attempted => 'name' } },
    },
  } ) ),
  'INSERT INTO "artist" ("charfield", "name", "rank") VALUES (?, ?, ?)'
. ' ON CONFLICT ("charfield", "rank") DO UPDATE SET "name" = excluded."name"',
  [ [ charfield => 'c' ], [ name => 'x' ], [ rank => 1 ] ],
  'a multi-column constraint keeps its resolved column order',
);

{
  # RETURNING is not a tail that can be appended after the fact -- SQLite wants
  # it *after* the conflict clause, so the two are assembled in grammar order.
  my $opts = {
    returning   => [ qw( artistid rank ) ],
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
    },
  };

  is_same_sql_bind (
    sql_bind( $sm->insert( 'artist', { name => 'x', rank => 2 }, $opts ) ),
    'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
  . ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
  . ' RETURNING "artistid", "rank"',
    [ [ name => 'x' ], [ rank => 2 ] ],
    'the conflict clause is emitted between VALUES and RETURNING',
  );

  is_deeply (
    $opts,
    { returning => [ qw( artistid rank ) ] },
    'on_conflict is consumed, returning is handed back -- '
  . 'DBIO::Storage::DBI::insert reads it again after the statement ran',
  );
}

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x' }, {
    on_conflict => { target => [ 'name' ], action => 'nothing' },
  } ) ),
  'INSERT INTO "artist" ("name") VALUES (?) ON CONFLICT ("name") DO NOTHING',
  [ [ name => 'x' ] ],
  'DO NOTHING with a conflict target',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x' }, {
    on_conflict => { target => 'any', action => 'nothing' },
  } ) ),
  'INSERT INTO "artist" ("name") VALUES (?) ON CONFLICT DO NOTHING',
  [ [ name => 'x' ] ],
  "conflict_target => 'any' with DO NOTHING is the targetless form, which "
. 'SQLite does have',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x' }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => \'rank + 1' },
    },
  } ) ),
  'INSERT INTO "artist" ("name") VALUES (?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = rank + 1',
  [ [ name => 'x' ] ],
  'a literal update expression passes through verbatim',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x' }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => \[ 'rank + ?', 5 ] },
    },
  } ) ),
  'INSERT INTO "artist" ("name") VALUES (?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = rank + ?',
  [ [ name => 'x' ], 5 ],
  'a literal-with-bind update expression contributes its bind after the values',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x' }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => 9 },
    },
  } ) ),
  'INSERT INTO "artist" ("name") VALUES (?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = ?',
  [ [ name => 'x' ], [ rank => 9 ] ],
  'a plain scalar in the update set is bound',
);

# ----------------------------------------- the conditional DO UPDATE branch
#
# ADR 0036 / core k105. The structure grows a fourth key, `where`, present only
# when the caller passed update_where -- every test above renders exactly what
# it rendered before the option existed, which is the point of the key being
# optional. Two vocabularies live inside it: a bare column is the STORED row,
# { -attempted => $col } the value that was tried, and unlike in the update set
# the marker can sit at any depth.
#
# k205: in an ON CONFLICT DO UPDATE branch the target table and the attempted
# pseudo-row (excluded) are both in scope, so a bare stored-side column is
# ambiguous. insert() threads the target table into _upsert_condition_sql, which
# qualifies every bare (single-part) stored column with it; the excluded marker
# and any already-qualified column are left byte-for-byte unchanged.

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { rank => { '<' => { -attempted => 'rank' } } },
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
. ' WHERE "artist"."rank" < excluded."rank"',
  [ [ name => 'x' ], [ rank => 7 ] ],
  'the last-write-wins guard: the condition follows the SET list and compares '
. 'the stored row (qualified with the target table, k205) against the attempted one',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { charfield => { -attempted => 'charfield' } },
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
. ' WHERE "artist"."charfield" = excluded."charfield"',
  [ [ name => 'x' ], [ rank => 7 ] ],
  'the marker as the bare value of a column means equality -- the position the '
. 'operator registration turns into a comparison before the node is rendered',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => {
        -or => [
          { rank => { '<' => { -attempted => 'rank' } } },
          { -and => [
            { rank      => { '='  => { -attempted => 'rank' } } },
            { charfield => { '!=' => { -attempted => 'charfield' } } },
          ] },
        ],
      },
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
. ' WHERE ( "artist"."rank" < excluded."rank"'
. '      OR ( "artist"."rank" = excluded."rank" AND "artist"."charfield" != excluded."charfield" ) )',
  [ [ name => 'x' ], [ rank => 7 ] ],
  'the marker is substituted at any depth -- through -or, through -and, and '
. 'through the arrayrefs in between',
);

# The value positions the operator registration substitutes in. Core k133
# lifted the PostgreSQL way: the marker is registered as an SQL::Abstract
# operator for the duration of the call, which makes -literal correct in every
# position (make_unop_expander turns the bare right-hand side into a
# comparison first), and both halves of the statement now spell the pseudo-row
# identically -- excluded."rank" in the condition as in the SET list. Each
# position below is a claim the core helper's documentation makes, so each of
# them gets asked.

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { rank => { -in => [ { -attempted => 'rank' }, 3 ] } },
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
. ' WHERE "artist"."rank" IN ( excluded."rank", ? )',
  [ [ name => 'x' ], [ rank => 7 ], [ rank => 3 ] ],
  'the marker inside an -in list is a column reference and the plain value '
. 'next to it still binds',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { rank => { -between => [ { -attempted => 'rank' }, 10 ] } },
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
. ' WHERE ( "artist"."rank" BETWEEN excluded."rank" AND ? )',
  [ [ name => 'x' ], [ rank => 7 ], [ rank => 10 ] ],
  'and one half of a -between pair, with the other half still a bind',
);

{
  # Rendering leaves the caller's condition alone. A condition is exactly the
  # kind of thing a caller keeps in a constant and passes to every upsert, so
  # a renderer that rewrote its input would corrupt the constant -- marker and
  # all -- for the next call.
  my $where = { rank => { '<' => { -attempted => 'rank' } } };

  $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => $where,
    },
  } );

  is_deeply (
    $where,
    { rank => { '<' => { -attempted => 'rank' } } },
    'the caller condition is not rewritten in place',
  );
}

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x' }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { charfield => \[ 'charfield || ?', 'z' ], rank => 9 },
      where  => { rank => { '<' => 4 } },
    },
  } ) ),
  'INSERT INTO "artist" ("name") VALUES (?)'
. ' ON CONFLICT ("name") DO UPDATE SET "charfield" = charfield || ?, "rank" = ?'
. ' WHERE "artist"."rank" < ?',
  [ [ name => 'x' ], 'z', [ rank => 9 ], [ rank => 4 ] ],
  'the condition binds are spliced in after the SET binds, in statement order',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => \'excluded."rank" > "artist"."rank"',
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
. ' WHERE excluded."rank" > "artist"."rank"',
  [ [ name => 'x' ], [ rank => 7 ] ],
  'a literal condition passes through verbatim -- the escape hatch for what '
. 'the abstract form cannot say',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => \[ 'excluded."rank" > "artist"."rank" + ?', [ rank => 2 ] ],
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
. ' WHERE excluded."rank" > "artist"."rank" + ?',
  [ [ name => 'x' ], [ rank => 7 ], [ rank => 2 ] ],
  'a literal-with-bind condition contributes its bind at its own position',
);

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { -and => [
        \'"artist"."name" IS NOT NULL',
        { rank => { '<' => { -attempted => 'rank' } } },
        \[ 'excluded."rank" > "artist"."rank" + ?', [ rank => 1 ] ],
      ] },
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
. ' WHERE ( "artist"."name" IS NOT NULL AND "artist"."rank" < excluded."rank"'
. '         AND excluded."rank" > "artist"."rank" + ? )',
  [ [ name => 'x' ], [ rank => 7 ], [ rank => 1 ] ],
  'a literal buried in the condition is left alone by the operator '
. 'substitution while the marker beside it is replaced, and its bind keeps '
. 'its own position',
);

{
  # A blessed value is a bind value, not a structure: SQL::Abstract treats any
  # blessed reference as a scalar, so the renderer does too. This one carries a
  # -attempted key on purpose -- a substitution that went by reftype instead
  # of ref would rewrite the caller's object into "excluded"."rank" and drop
  # the bind.
  package DBIO::SQLite::Test::AttemptedDecoy;
  use overload '""' => sub { 'decoy' }, fallback => 1;
  sub new { bless { -attempted => 'rank' }, shift }
}

{
  my $decoy = DBIO::SQLite::Test::AttemptedDecoy->new;

  my ($sql, @bind) = $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { charfield => { '<' => $decoy } },
    },
  } );

  like (
    $sql,
    qr/\QDO UPDATE SET "rank" = excluded."rank" WHERE "artist"."charfield" < ?\E$/,
    'the renderer does not descend into a blessed value -- it stays a bind, '
  . 'even carrying a -attempted key',
  );

  is (
    $bind[-1][1],
    $decoy,
    '... and reaches the bind list as itself, un-rewritten',
  );
}

{
  # Grammar order again, now with three tails to place: the conflict clause
  # after VALUES, the condition after the SET list, RETURNING last.
  my $opts = {
    returning   => [ qw( artistid rank ) ],
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { rank => { '<' => { -attempted => 'rank' } } },
    },
  };

  is_same_sql_bind (
    sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, $opts ) ),
    'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
  . ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
  . ' WHERE "artist"."rank" < excluded."rank"'
  . ' RETURNING "artistid", "rank"',
    [ [ name => 'x' ], [ rank => 7 ] ],
    'the condition lands between the SET list and RETURNING',
  );

  is_deeply (
    $opts,
    { returning => [ qw( artistid rank ) ] },
    '... and the options transport is unchanged by it -- on_conflict consumed, '
  . 'returning handed back',
  );
}

# ------------------------------------------------- shapes SQLite cannot express

throws_like (
  sub { $sm->insert( 'artist', { name => 'x', rank => 1 }, {
    on_conflict => {
      target => 'any',
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
    },
  } ) },
  qr/\Qconflict_target => 'any' cannot be combined with on_conflict => 'update'\E/,
  "'any' with DO UPDATE throws -- the grammar requires a target, and guessing "
. 'one would rewrite a row the caller never named',
);

# The resolved column list is the only half SQLite can use, so its absence has
# to be loud: a core that regressed to passing the bare name (which is what
# core k104 fixed) must not slide through into ON CONFLICT () -- a syntax error
# at best, a wrongly targeted write at worst.
for my $case (
  [ 'no columns at all'   => { constraint => 'artist_name' } ],
  [ 'an empty column list' => { constraint => 'artist_name', columns => [] } ],
) {
  my ($desc, $target) = @$case;

  throws_like (
    sub { $sm->insert( 'artist', { name => 'x', rank => 1 }, {
      on_conflict => {
        target => $target,
        action => 'update',
        set    => { rank => { -attempted => 'rank' } },
      },
    } ) },
    qr/\Qcarries no resolved columns\E.*\Qartist_name\E/s,
    "a constraint target with $desc throws -- a SQLMaker has no ResultSource "
  . 'to resolve the name against, so there is nothing to render',
  );
}

throws_like (
  sub { $sm->insert( 'artist', { name => 'x', rank => 1 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -something_else => 'rank' } },
    },
  } ) },
  qr/\Qthe only operator an ON CONFLICT update set understands is -attempted\E/,
  'an unknown operator in the update set throws instead of being rendered',
);

# A dropped condition is the one mistake with no symptom -- the statement stays
# valid and performs the unconditional overwrite update_where was written to
# prevent. Every route to one throws here rather than emitting the clause.

throws_like (
  sub { $sm->insert( 'artist', { name => 'x' }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'nothing',
      where  => { rank => { '<' => { -attempted => 'rank' } } },
    },
  } ) },
  qr/\QON CONFLICT DO NOTHING takes no condition\E/,
  "a condition on the DO NOTHING branch throws -- core refuses that combination "
. 'up front, so one arriving here means the condition would be dropped',
);

throws_like (
  sub { $sm->insert( 'artist', { name => 'x' }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'nothing',
      where  => undef,
    },
  } ) },
  qr/\QON CONFLICT DO NOTHING takes no condition\E/,
  '... and it answers the mere presence of the key, not its definedness -- an '
. 'undef where on that branch is a condition that went missing upstream',
);

throws_like (
  sub { $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => undef,
    },
  } ) },
  qr/\Qcondition rendered to nothing\E/,
  'an undef condition throws as well -- core sets the key only when it has a '
. 'condition, so an undef one is a lost condition, and emitting the clause '
. 'without it is the unconditional overwrite',
);

throws_like (
  sub { $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { -and => [] },
    },
  } ) },
  qr/\Qcondition rendered to nothing\E/,
  'a condition that renders to an empty string throws -- core rejects the '
. 'empty forms it can see ({} and []) but deliberately does not walk the '
. 'condition, so this one arrives',
);

throws_like (
  sub { $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { rank => { '<' => { -attempted => [ 'rank' ] } } },
    },
  } ) },
  qr/\Q{ -attempted => \E\$column\Q } takes a plain column name\E/,
  'a malformed -attempted is caught at depth -- by the core operator '
  . 'registration, the single door every marker in the condition comes '
  . 'through, not only at the top level',
);

# The old walk threw for this shape -- after a structural substitution the
# two keys had no defined reading. In the operator way the reading is
# SQL::Abstract's own: a hashref beside a column with several operator keys is
# an AND, and -attempted is just one of them. Nothing has to win silently.
is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 7 }, {
    on_conflict => {
      target => [ 'name' ],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { rank => { -attempted => 'rank', '<' => 3 } },
    },
  } ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)'
. ' ON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"'
. ' WHERE ( "artist"."rank" = excluded."rank" AND "artist"."rank" < ? )',
  [ [ name => 'x' ], [ rank => 7 ], [ rank => 3 ] ],
  '-attempted sharing a hashref with an operator is the normal multi-op AND, '
. 'not a throw',
);

# ------------------------------------------------------------- live round-trips

SKIP: {
  skip
    "libsqlite $server_info->{dbms_version} has no RETURNING, so this driver "
  . 'does not declare supports_upsert (needs 3.35)', 15
      unless $has_returning;

  my @sql;
  $storage->debugcb( sub { push @sql, $_[1] } );
  $storage->debug(1);

  my $first = $rs->upsert(
    { name => 'Aphex Twin', rank => 5 },
    { conflict_target => [ 'name' ] },
  );

  ok (defined $first, 'the insert branch names the row it wrote');
  is ($first->rank, 5, 'the inserted row carries the supplied value');
  like (
    $sql[-1],
    qr/\QON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"\E/,
    'the statement that ran is a single INSERT ... ON CONFLICT',
  );

  my $id = $first->artistid;

  # The decoy exists to make the wrong answer visible: after it,
  # last_insert_rowid() reports the decoy, so an upsert that took the DO UPDATE
  # branch and resolved its identity through last_insert_id would return the
  # decoy's row instead of Aphex Twin's. That is exactly the failure the 3.35
  # gate rules out, so it has to be a test and not a comment.
  my $decoy = $rs->create({ name => 'Decoy' });
  isnt ($decoy->artistid, $id, 'the decoy is a different row');

  my $second = $rs->upsert(
    { name => 'Aphex Twin', rank => 7 },
    { conflict_target => [ 'name' ] },
  );

  is (
    $second->artistid,
    $id,
    'the update branch returns the row that was written, not whatever '
  . 'last_insert_rowid() happens to report',
  );
  is ($rs->find($id)->rank, 7, 'the conflicting row was updated in place');
  is ($rs->count, 2, 'the update branch inserted nothing');

  my $skipped = $rs->upsert(
    { name => 'Aphex Twin', rank => 99 },
    { conflict_target => [ 'name' ], on_conflict => 'nothing', result => 'row_or_undef' },
  );

  ok (! defined $skipped, 'DO NOTHING on an existing row returns undef');
  is ($rs->find($id)->rank, 7, 'DO NOTHING left the existing row alone');

  my $fresh = $rs->upsert(
    { name => 'Fresh' },
    { conflict_target => [ 'name' ], on_conflict => 'nothing' },
  );
  ok (defined $fresh, 'DO NOTHING that did insert hands the new row back');

  # 'any' is portable only in this combination -- see the SQL-shape section for
  # the DO UPDATE half, which throws.
  my $any = $rs->upsert(
    { name => 'Fresh' },
    { conflict_target => 'any', on_conflict => 'nothing', result => 'count' },
  );
  # Numeric comparison on purpose: core k104 made result => 'count' a plain
  # number, but DBI's own "no rows affected" is the zero-but-true string '0E0'
  # and the point here is the affected-row count, not its spelling.
  cmp_ok (
    $any, '==', 0,
    "conflict_target => 'any' with DO NOTHING works on SQLite and reports "
  . 'nothing affected',
  );

  # key => $constraint is the find idiom, reused as the ADR promises. It has to
  # land on the same row conflict_target => [qw( name )] landed on above -- the
  # name never reaches SQLite, only the columns core resolved it to.
  my $by_key = $rs->upsert(
    { name => 'Aphex Twin', rank => 11 },
    { key => 'artist_name' },
  );

  like (
    $sql[-1],
    qr/\QON CONFLICT ("name") DO UPDATE SET "rank" = excluded."rank"\E/,
    'the constraint name reached SQLite as its resolved column list',
  );
  is (
    $by_key->artistid,
    $id,
    "key => 'artist_name' conflicts on the same row as the column list does",
  );
  is ($rs->find($id)->rank, 11, 'and updated it in place');

  # The default conflict target is the primary key when the data supplies it.
  $rs->upsert({ artistid => $id, name => 'Aphex Twin', rank => 3 });
  is ($rs->find($id)->rank, 3, 'the primary key is the default conflict target');

  $storage->debug(0);
  $storage->debugcb(undef);
}

# ------------------------------ live round-trips of the conditional branch
#
# The guard is the whole reason the option exists, so it is tested by making it
# actually suppress a write rather than by inspecting SQL a second time.

SKIP: {
  skip
    "libsqlite $server_info->{dbms_version} has no RETURNING, so this driver "
  . 'does not declare supports_upsert (needs 3.35)', 13
      unless $has_returning;

  my @sql;
  $storage->debugcb( sub { push @sql, $_[1] } );
  $storage->debug(1);

  # rank stands in for the version column of the classic last-write-wins guard:
  # "insert, or update only if the incoming row is newer".
  my $guard = { rank => { '<' => { -attempted => 'rank' } } };

  my $created = $rs->upsert(
    { name => 'Versioned', rank => 5 },
    { conflict_target => [ 'name' ], update_where => $guard },
  );

  ok (defined $created, 'the insert branch is not affected by the condition');
  is ($created->rank, 5, 'and carries the supplied version');

  my $id = $created->artistid;

  like (
    $sql[-1],
    qr/\QDO UPDATE SET "rank" = excluded."rank" WHERE "artist"."rank" < excluded."rank"\E/,
    'the statement that ran carries the condition after the SET list -- the '
  . 'pseudo-row spelled identically in both halves',
  );

  my $newer = $rs->upsert(
    { name => 'Versioned', rank => 9 },
    { conflict_target => [ 'name' ], update_where => $guard },
  );

  is (
    ( defined $newer ? $newer->artistid : undef ),
    $id,
    'a newer write satisfies the condition and updates the stored row',
  );
  is ($rs->find($id)->rank, 9, '... in place');

  my $older = $rs->upsert(
    { name => 'Versioned', rank => 2 },
    { conflict_target => [ 'name' ], update_where => $guard,
      result => 'row_or_undef' },
  );

  ok (
    ! defined $older,
    'an older write is suppressed -- with result => row_or_undef that is undef, '
  . 'and row_or_die never gets here because core refuses it with a condition',
  );
  is ($rs->find($id)->rank, 9, 'and the newer stored value survived');
  is (
    $rs->search({ name => 'Versioned' })->count,
    1,
    'the suppressed upsert inserted nothing either',
  );

  cmp_ok (
    $rs->upsert(
      { name => 'Versioned', rank => 2 },
      { conflict_target => [ 'name' ], update_where => $guard,
        result => 'count' },
    ),
    '==', 0,
    "result => 'count' reports a suppressed write as 0",
  );

  # The two vocabularies are only provably different when the rows differ.
  # 9 is stored, 2 is attempted: "artist"."rank" > excluded."rank" is 9 > 2 and
  # writes, while the same condition read as attempted-vs-attempted would be
  # 2 > 2 and write nothing. So this is what pins the stored-side column (which
  # k205 qualifies with the target table) to the STORED row.
  my $downgrade = $rs->upsert(
    { name => 'Versioned', rank => 2 },
    { conflict_target => [ 'name' ],
      update_where    => { rank => { '>' => { -attempted => 'rank' } } } },
  );

  is (
    ( defined $downgrade ? $downgrade->artistid : undef ),
    $id,
    'the reversed condition holds, so the write goes through',
  );
  is (
    $rs->find($id)->rank,
    2,
    '... which it only can if the stored-side column is the stored row',
  );

  # The literal escape hatch, doing the same job in engine SQL: 8 attempted
  # against 2 stored.
  my $literal = $rs->upsert(
    { name => 'Versioned', rank => 8 },
    { conflict_target => [ 'name' ],
      update_where    => \'excluded."rank" > "artist"."rank"' },
  );

  is (
    ( defined $literal ? $literal->rank : undef ),
    8,
    'a literal condition round-trips against the engine',
  );

  {
    # Only the condition is gated: an upsert without one is unaffected by the
    # capability, which is what makes "older driver, newer core" safe rather
    # than merely loud.
    $storage->_use_supports_upsert_where(0);

    my $plain = $rs->upsert(
      { name => 'Versioned', rank => 4 },
      { conflict_target => [ 'name' ] },
    );

    is (
      ( defined $plain ? $plain->rank : undef ),
      4,
      'withdrawing supports_upsert_where leaves the unconditional upsert alone',
    );

    $storage->_use_supports_upsert_where(undef);
  }

  $storage->debug(0);
  $storage->debugcb(undef);
}

# ------------------------------- what happens below the gate (or on any engine
# ------------------------------- that has not declared the capability)

{
  $storage->_use_supports_upsert(0);

  throws_like (
    sub { $rs->upsert(
      { name => 'Never Written', rank => 1 },
      { conflict_target => [ 'name' ] },
    ) },
    qr/\Qdoes not declare the supports_upsert capability\E/,
    'with the capability withdrawn -- which is what libsqlite < 3.35 looks '
  . 'like -- upsert throws instead of degrading to a racy read-then-write',
  );

  is (
    $rs->search({ name => 'Never Written' })->count,
    0,
    'and it wrote nothing on the way out',
  );

  $storage->_use_supports_upsert(undef);
}

{
  # The same, one level down: the driver upserts but does not render the
  # condition. supports_upsert is forced on so the test says the same thing on
  # a libsqlite below the RETURNING gate -- it never reaches the engine.
  $storage->_use_supports_upsert(1);
  $storage->_use_supports_upsert_where(0);

  throws_like (
    sub { $rs->upsert(
      { name => 'Unconditional', rank => 1 },
      { conflict_target => [ 'name' ],
        update_where    => { rank => { '<' => { -attempted => 'rank' } } } },
    ) },
    qr/\Qdoes not declare the supports_upsert_where\E/,
    'with the conditional capability withdrawn -- which is what a core newer '
  . 'than its driver looks like -- upsert throws rather than let the WHERE be '
  . 'dropped into an unconditional overwrite',
  );

  is (
    $rs->search({ name => 'Unconditional' })->count,
    0,
    'and it wrote nothing on the way out',
  );

  $storage->_use_supports_upsert_where(undef);
  $storage->_use_supports_upsert(undef);
}

done_testing;

# Test::Exception is not a dependency of this dist; two lines of eval do the job.
sub throws_like {
  my ($code, $re, $desc) = @_;
  my $ok = eval { $code->(); 1 };
  my $err = $@;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return fail("$desc (did not throw)") if $ok;
  return like($err, $re, $desc);
}

# $sm->insert returns ($sql, @bind); is_same_sql_bind wants ($sql, \@bind).
sub sql_bind {
  my ($sql, @bind) = @_;
  return ($sql, \@bind);
}
