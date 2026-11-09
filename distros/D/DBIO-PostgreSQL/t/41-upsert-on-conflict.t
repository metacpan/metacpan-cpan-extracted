use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';
use DBIO::Test::Storage ();
use DBIO::PostgreSQL::SQLMaker;

# ADR 0036 -- atomic upsert on PostgreSQL. THIS IS AN OFFLINE TEST: it pins the
# shape of the generated statement and the capability gate. The live
# round-trips (does the engine actually insert / update / write nothing) are in
# t/42-upsert-live.t.

# The mocked server version drives the version-gated supports_upsert
# capability. DBIO::Test::Storage overrides _server_info, so that is the method
# to mock -- and it has to happen after the class is loaded, otherwise loading
# it later silently reinstates the original.
my $mock_version = 16;
{
  no warnings 'redefine';
  *DBIO::Test::Storage::_server_info = sub {
    { dbms_version => $mock_version, normalized_dbms_version => $mock_version }
  };
}

# The capability is cached per storage instance, so every version case needs a
# storage of its own.
sub pg_schema {
  $mock_version = shift if @_;
  DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::PostgreSQL::Storage'
  );
}

my $sqlmaker = DBIO::PostgreSQL::SQLMaker->new(
  quote_char => '"',
  name_sep   => '.',
  bindtype   => 'columns'
);

# Statement shapes are compared as plain strings, not through
# is_same_sql_bind: the comparator normalises "ON CONFLICT (col)" to
# "ON CONFLICT col", and the parens are exactly the part PostgreSQL's grammar
# insists on.
sub insert_sql {
  my ($data, $options) = @_;
  my ($sql, @bind) = $sqlmaker->insert('artist', $data, $options);
  return ($sql, \@bind);
}

my %data = ( name => 'foo', rank => 3 );
my $values = 'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)';
my @values_bind = ( [ name => 'foo' ], [ rank => 3 ] );

# ---------------------------------------------------------------------------
# statement shape
# ---------------------------------------------------------------------------

{
  my ($sql, $bind) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank"},
    'column conflict target, DO UPDATE from the attempted values';
  is_deeply $bind, \@values_bind, '... no extra binds from the conflict clause';
}

{
  my ($sql) = insert_sql(\%data, {
    on_conflict => {
      target => [qw( name rank )],
      action => 'update',
      set    => { charfield => { -attempted => 'charfield' } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name", "rank") DO UPDATE SET "charfield" = EXCLUDED."charfield"},
    'multi-column conflict target';
}

# key => $constraint arrives as both halves (ADR 0036 section 2, core k104).
# The columns are what gets rendered: a DBIO constraint name is client-side
# metadata from add_unique_constraint and need not exist in the database, while
# the resolved columns name the same index and always do.
{
  my ($sql) = insert_sql(\%data, {
    on_conflict => {
      target => { constraint => 'artist_name', columns => ['name'] },
      action => 'update',
      set    => { rank => { -attempted => 'rank' } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank"},
    'a resolved constraint target renders its columns, not ON CONSTRAINT';
}

{
  my ($sql) = insert_sql(\%data, {
    on_conflict => {
      target => { constraint => 'u_nullable', columns => [qw( charfield rank )] },
      action => 'nothing'
    }
  });

  is $sql, qq{$values ON CONFLICT ("charfield", "rank") DO NOTHING},
    '... including a multi-column constraint';
}

# A name with no columns cannot be resolved here -- a SQLMaker has no
# ResultSource -- so it is taken at face value as a server-side constraint.
# Core no longer sends this shape; it is the explicit ON CONSTRAINT opt-in.
{
  my ($sql) = insert_sql(\%data, {
    on_conflict => {
      target => { constraint => 'artist_name' },
      action => 'update',
      set    => { rank => { -attempted => 'rank' } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ON CONSTRAINT "artist_name" DO UPDATE SET "rank" = EXCLUDED."rank"},
    'a bare constraint name is the opt-in for a real server-side constraint';
}

{
  my ($sql) = insert_sql(\%data, {
    on_conflict => {
      target => { columns => ['name'] },
      action => 'nothing'
    }
  });

  is $sql, qq{$values ON CONFLICT ("name") DO NOTHING},
    'the columns half alone is a valid target too';
}

{
  my ($sql) = insert_sql(\%data, {
    on_conflict => { target => 'any', action => 'nothing' }
  });

  is $sql, qq{$values ON CONFLICT DO NOTHING},
    "target 'any' with DO NOTHING is the portable insert-unless-present";
}

{
  my ($sql) = insert_sql(\%data, {
    on_conflict => { target => ['name'], action => 'nothing' }
  });

  is $sql, qq{$values ON CONFLICT ("name") DO NOTHING},
    'DO NOTHING with an explicit target';
}

# The clause sits BEFORE the RETURNING tail -- the other way round is a syntax
# error, and RETURNING is what makes the written row nameable here (ADR 0036
# section 4), so the two have to work together.
{
  my ($sql, $bind) = insert_sql(\%data, {
    returning   => [qw( artistid name )],
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank" }
  . q{RETURNING "artistid", "name"},
    'conflict clause is emitted before RETURNING';
  is_deeply $bind, \@values_bind, '... and the bind list is unchanged';
}

{
  my ($sql) = insert_sql(\%data, {
    returning   => ['artistid'],
    on_conflict => { target => 'any', action => 'nothing' }
  });

  is $sql, qq{$values ON CONFLICT DO NOTHING RETURNING "artistid"},
    'DO NOTHING and RETURNING combine (zero rows back means nothing written)';
}

# ---------------------------------------------------------------------------
# the update set: -attempted, caller literals, plain values
# ---------------------------------------------------------------------------

{
  my ($sql) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { charfield => { -attempted => 'name' } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "charfield" = EXCLUDED."name"},
    '-attempted names its source column, which need not be the target column';
}

{
  my ($sql, $bind) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => \'"artist"."rank" + 1' }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = "artist"."rank" + 1},
    'caller literal passes through verbatim';
  is_deeply $bind, \@values_bind, '... and adds no bind';
}

{
  my ($sql, $bind) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => \[ '"artist"."rank" + ?', 5 ] }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = "artist"."rank" + ?},
    'literal with bind values';
  is_deeply $bind, [ @values_bind, 5 ],
    '... its binds follow the VALUES binds, in statement order';
}

{
  my ($sql, $bind) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { charfield => 'fixed', rank => undef }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "charfield" = ?, "rank" = ?},
    'plain values become placeholders, columns in stable order';
  is_deeply $bind, [ @values_bind, [ charfield => 'fixed' ], [ rank => undef ] ],
    '... bound as the column they are written to';
}

# ---------------------------------------------------------------------------
# the conditional conflict branch: DO UPDATE ... WHERE (ADR 0036 section 1,
# core k105). The structure's fourth key is present ONLY when the caller asked
# for a condition -- every statement above renders exactly as it did before
# the option existed, which is what makes an older driver safe on a newer core.
#
# k205: in an ON CONFLICT DO UPDATE branch the target table and the attempted
# pseudo-row (EXCLUDED) are both in scope, so a bare stored-side column is
# ambiguous -- PostgreSQL rejects it ("column reference is ambiguous"). insert()
# threads the target table into _upsert_condition_sql, which qualifies every
# bare (single-part) stored column with it; the EXCLUDED marker and any
# already-qualified column are left byte-for-byte unchanged.
# ---------------------------------------------------------------------------

{
  my ($sql, $bind) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { rank => { '<' => { -attempted => 'rank' } } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank" }
  . q{WHERE "artist"."rank" < EXCLUDED."rank"},
    'the last-write-wins guard: the stored column is qualified with the target '
  . 'table (bare is ambiguous in the ON CONFLICT DO UPDATE scope, k205), '
  . '-attempted is the value that was tried';
  is_deeply $bind, \@values_bind, '... and it binds nothing of its own';
}

# The condition goes after the SET list and before RETURNING, and its binds go
# in at exactly that position -- a bind list in the wrong order is the failure
# mode that survives every SQL-shape test.
{
  my ($sql, $bind) = insert_sql(\%data, {
    returning   => [qw( artistid name )],
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { charfield => 'fixed' },
      where  => { rank => { '<' => 0 } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "charfield" = ? }
  . q{WHERE "artist"."rank" < ? RETURNING "artistid", "name"},
    'the condition sits between the SET list and RETURNING';
  is_deeply $bind,
    [ @values_bind, [ charfield => 'fixed' ], [ rank => 0 ] ],
    '... and its binds follow the SET binds, in statement order';
}

# In the set list the marker is only ever a top-level value. In a condition it
# can sit anywhere, so the substitution has to reach every depth: nested
# -and/-or, and operand lists.
{
  my ($sql, $bind) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { -and => [
        { rank => { '<' => { -attempted => 'rank' } } },
        { -or => [
          { charfield => undef },
          { charfield => { '!=' => { -attempted => 'charfield' } } }
        ] }
      ] }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank" }
  . q{WHERE ( "artist"."rank" < EXCLUDED."rank" AND ( "artist"."charfield" IS NULL OR }
  . q{"artist"."charfield" != EXCLUDED."charfield" ) )},
    'every stored column is qualified with the target table at any depth (k205); '
  . '-attempted is substituted at any depth, not just at the top level';
  is_deeply $bind, \@values_bind, '... still no bind of its own';
}

{
  my ($sql, $bind) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { rank => { -in => [ 1, 2, { -attempted => 'rank' } ] } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank" }
  . q{WHERE "artist"."rank" IN ( ?, ?, EXCLUDED."rank" )},
    '... including inside an operand list';
  is_deeply $bind, [ @values_bind, [ rank => 1 ], [ rank => 2 ] ],
    '... with the plain operands still bound';
}

# The bare right-hand-side position: "equal to the value that was attempted".
# A scalar-ref literal in that slot would render '"charfield" EXCLUDED.…' --
# SQL::Abstract reads it as the operator itself -- so the marker has to supply
# the comparison.
{
  my ($sql) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { charfield => { -attempted => 'charfield' } }
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank" }
  . q{WHERE "artist"."charfield" = EXCLUDED."charfield"},
    'a marker as a bare column value is an equality against the attempted row '
  . '(the stored column stays qualified with the target table, k205)';
}

{
  my ($sql, $bind) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => \'excluded.rank > artist.rank'
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank" }
  . q{WHERE excluded.rank > artist.rank},
    'a literal condition passes through verbatim -- the escape hatch for what '
  . 'the abstract form cannot say';
  is_deeply $bind, \@values_bind, '... adding no bind';
}

{
  my ($sql, $bind) = insert_sql(\%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { charfield => 'fixed' },
      where  => \[ 'excluded.rank > artist.rank + ?', 5 ]
    }
  });

  is $sql,
    qq{$values ON CONFLICT ("name") DO UPDATE SET "charfield" = ? }
  . q{WHERE excluded.rank > artist.rank + ?},
    'a literal with bind values';
  is_deeply $bind, [ @values_bind, [ charfield => 'fixed' ], 5 ],
    '... its binds behind the SET binds';
}

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => {
      target => ['name'],
      action => 'nothing',
      where  => { rank => { '<' => 1 } }
    }
  });
} qr/where has no meaning with action 'nothing'/,
  'a condition on DO NOTHING throws instead of being dropped -- a dropped '
. 'condition is the one mistake that leaves no symptom';

# Same branch, key present but empty. Core sets it only when it has a
# condition, so this structure is broken however it got here -- and answering
# it with a valid DO NOTHING would say nothing about that.
throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => {
      target => ['name'],
      action => 'nothing',
      where  => undef
    }
  });
} qr/where has no meaning with action 'nothing'/,
  '... in any state of the key, undef included';

# The update branch, same reasoning: undef is not a condition, and rendering
# the clause without one is the unconditional overwrite.
throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => undef
    }
  });
} qr/rendered to an empty condition/,
  'an undef condition on DO UPDATE throws instead of becoming an '
. 'unconditional overwrite';

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => { rank => { '<' => { -attempted => ['rank'] } } }
    }
  });
} qr/-attempted => \$column \} takes a plain column name/,
  '-attempted with something other than a column name throws';

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } },
      where  => \''
    }
  });
} qr/rendered to an empty condition/,
  'a condition that renders to nothing throws rather than silently becoming '
. 'an unconditional update';

# The marker is registered as an operator for the duration of the conflict
# clause only: -attempted means nothing in a SELECT, and an EXCLUDED reference
# in a statement that has no excluded row would be nonsense.
{
  my ($where_sql) = $sqlmaker->_recurse_where(
    { rank => { '<' => { -attempted => 'rank' } } }
  );

  unlike $where_sql, qr/EXCLUDED/,
    '-attempted does not leak into ordinary where clauses';
}

# ---------------------------------------------------------------------------
# what the option transport must look like afterwards
# ---------------------------------------------------------------------------

{
  my $options = {
    returning   => ['artistid'],
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -attempted => 'rank' } }
    }
  };
  $sqlmaker->insert('artist', \%data, $options);

  ok ! exists $options->{on_conflict},
    'on_conflict is consumed -- the generic SQLMaker path throws on leftovers';
  is_deeply $options->{returning}, ['artistid'],
    'returning is put back: DBIO::Storage::DBI reads it again after execution';
}

{
  my $options = { returning => ['artistid'] };
  my ($sql) = $sqlmaker->insert('artist', \%data, $options);

  is $sql, qq{$values RETURNING "artistid"},
    'an insert without on_conflict is passed straight through';
}

# ---------------------------------------------------------------------------
# what PostgreSQL cannot express
# ---------------------------------------------------------------------------

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => {
      target => 'any',
      action => 'update',
      set    => { rank => { -attempted => 'rank' } }
    }
  });
} qr/DO UPDATE requires the arbiter index to be named/,
  "target 'any' with DO UPDATE throws -- the grammar demands a target";

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => { target => 'name', action => 'nothing' }
  });
} qr/target must be an arrayref of columns/,
  'a bare column name is not a conflict target structure';

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => { target => [], action => 'nothing' }
  });
} qr/empty column list/, 'empty conflict target throws';

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => {
      target => { constraint => 'artist_name', column => ['name'] },
      action => 'nothing'
    }
  });
} qr/target hashref must be/,
  'an unknown key in the target hashref throws -- typos do not silently '
. 'degrade to ON CONSTRAINT';

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => { target => {}, action => 'nothing' }
  });
} qr/target hashref must be/, 'an empty target hashref throws';

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => {
      target => { constraint => 'artist_name', columns => [] },
      action => 'nothing'
    }
  });
} qr/empty column list/,
  'a resolved target with no columns throws rather than falling back to the '
. 'name -- an empty resolution is a broken structure, not an opt-in';

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => { target => ['name'], action => 'replace', set => {} }
  });
} qr/action must be 'update' or 'nothing'/, 'unknown action throws';

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => { target => ['name'], action => 'update', set => {} }
  });
} qr/needs a non-empty set of columns/, 'DO UPDATE with an empty set throws';

throws_ok {
  $sqlmaker->insert('artist', \%data, {
    on_conflict => {
      target => ['name'],
      action => 'update',
      set    => { rank => { -whatever => 'rank' } }
    }
  });
} qr/must be \{ -attempted => \$column \}/, 'unknown set marker throws';

# ---------------------------------------------------------------------------
# capability gate
# ---------------------------------------------------------------------------

is pg_schema(9.005)->storage->_use_supports_upsert, 1,
  'supports_upsert is declared on PostgreSQL 9.5 (ON CONFLICT lands there)';

is pg_schema(16)->storage->_use_supports_upsert, 1,
  'supports_upsert is declared on a current server';

is pg_schema(9.004)->storage->_use_supports_upsert, 0,
  'supports_upsert is refused below 9.5 -- the engine has no ON CONFLICT';

{
  # ADR 0036 section 4: the capability may only be declared when the row that
  # was written can be proven. Without RETURNING it cannot: the DO UPDATE
  # branch still burns a nextval() from the column default, so last_insert_id
  # would name a row that does not exist.
  my $schema = pg_schema(16);
  $schema->storage->_use_insert_returning(0);

  is $schema->storage->_use_supports_upsert, 0,
    'supports_upsert is refused when INSERT ... RETURNING is turned off';
}

throws_ok {
  pg_schema(9.004)->resultset('Artist')->upsert(
    { artistid => 1, name => 'foo' }
  );
} qr/does not declare the supports_upsert capability/,
  'upsert on a pre-9.5 server throws instead of degrading to a read-then-write';

# The conditional branch has a capability of its own because a driver that
# ignored the key would emit a VALID unconditional update -- the overwrite the
# condition exists to prevent, with no symptom at all (ADR 0036 section 3).
# Here it is declared, not derived from supports_upsert (core k134): the flag
# answers about the conditional branch itself, and PostgreSQL has had the
# WHERE since 9.5, together with the clause it hangs off. "supports_upsert
# off, supports_upsert_where on" is therefore a legal state -- core probes
# supports_upsert first and throws there, with that gate's message.

is pg_schema(16)->storage->_use_supports_upsert_where, 1,
  'supports_upsert_where is declared wherever the conflict clause is';

is pg_schema(9.004)->storage->_use_supports_upsert_where, 1,
  '... and declared below 9.5 too: the WHERE shipped with the clause';

{
  my $schema = pg_schema(16);
  $schema->storage->_use_insert_returning(0);

  is $schema->storage->_use_supports_upsert_where, 1,
    '... and not entailed by supports_upsert: the RETURNING demand belongs '
  . 'to the other gate, not to the conditional branch';
}

throws_ok {
  pg_schema(9.004)->resultset('Artist')->upsert(
    { artistid => 1, name => 'foo' },
    { update_where => { rank => { '<' => { -attempted => 'rank' } } } }
  );
} qr/does not declare the supports_upsert capability/,
  'update_where on a pre-9.5 server still throws at the supports_upsert '
  . 'gate, with its message';

{
  # The gate is separable from the rendering: a storage that says it does not
  # render conditions must make core refuse the call, not quietly write.
  my $schema = pg_schema(16);
  $schema->storage->_use_supports_upsert_where(0);

  throws_ok {
    $schema->resultset('Artist')->upsert(
      { artistid => 1, name => 'foo' },
      { update_where => { rank => { '<' => { -attempted => 'rank' } } } }
    );
  } qr/does not declare the supports_upsert_where/,
    'update_where without the capability throws rather than writing '
  . 'unconditionally';
}

# ---------------------------------------------------------------------------
# end to end through DBIO::ResultSet::upsert
# ---------------------------------------------------------------------------

{
  my $schema = pg_schema(16);
  my $rs     = $schema->resultset('Artist');
  $schema->storage->mock_persistent(qr/^INSERT INTO "artist"/, [ [42] ]);

  $schema->is_executed_sql_bind(
    sub {
      my $row = $rs->upsert({ name => 'foo', rank => 3 },
        { conflict_target => ['name'] });
      is $row->artistid, 42, 'the written row comes back through RETURNING';
      ok $row->in_storage, '... and is in storage';
    },
    [[
      'INSERT INTO "artist" ("name", "rank") VALUES (?, ?) '
    . 'ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank" '
    . 'RETURNING "artistid"',
      [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'foo' ],
      [ { dbic_colname => 'rank', sqlt_datatype => 'integer' } => 3 ]
    ]],
    'upsert() with a column target emits ON CONFLICT ... DO UPDATE ... RETURNING'
  );
}

{
  my $schema = pg_schema(16);
  my $rs     = $schema->resultset('Artist');

  $schema->is_executed_sql_bind(
    sub {
      my $row = $rs->upsert(
        { name => 'foo', rank => 3 },
        { conflict_target => 'any', on_conflict => 'nothing',
          result => 'row_or_undef' }
      );
      is $row, undef, 'DO NOTHING that wrote nothing returns undef';
    },
    [[
      'INSERT INTO "artist" ("name", "rank") VALUES (?, ?) '
    . 'ON CONFLICT DO NOTHING RETURNING "artistid"',
      [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'foo' ],
      [ { dbic_colname => 'rank', sqlt_datatype => 'integer' } => 3 ]
    ]],
    "conflict_target => 'any' plus on_conflict => 'nothing' emits ON CONFLICT DO NOTHING"
  );
}

{
  my $schema = pg_schema(16);
  my $rs     = $schema->resultset('Artist');

  $schema->is_executed_sql_bind(
    sub {
      $rs->upsert(
        { name => 'foo', rank => 3 },
        { key => 'artist_name', update => { rank => \'"artist"."rank" + 1' },
          result => 'void' }
      );
    },
    [[
      'INSERT INTO "artist" ("name", "rank") VALUES (?, ?) '
    . 'ON CONFLICT ("name") '
    . 'DO UPDATE SET "rank" = "artist"."rank" + 1',
      [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'foo' ],
      [ { dbic_colname => 'rank', sqlt_datatype => 'integer' } => 3 ]
    ]],
    "key => \$constraint emits the constraint's columns; result => 'void' "
  . 'spends no RETURNING'
  );
}

# The case that decides the whole question: 'primary' is what
# unique_constraint_names calls the primary key, and it is a name no
# PostgreSQL database has. ON CONSTRAINT "primary" would fail on every server;
# the resolved PK columns are what the engine can actually arbitrate on.
{
  my $schema = pg_schema(16);
  my $rs     = $schema->resultset('Artist');

  $schema->is_executed_sql_bind(
    sub {
      $rs->upsert(
        { artistid => 7, name => 'foo' },
        { key => 'primary', result => 'void' }
      );
    },
    [[
      'INSERT INTO "artist" ("artistid", "name") VALUES (?, ?) '
    . 'ON CONFLICT ("artistid") DO UPDATE SET "name" = EXCLUDED."name"',
      [ { dbic_colname => 'artistid', sqlt_datatype => 'integer' } => 7 ],
      [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'foo' ]
    ]],
    "key => 'primary' emits the primary key columns -- no database has a "
  . 'constraint called "primary"'
  );
}

# Same for a constraint whose DBIO-side name is pure client metadata: it names
# no index in the database, and the statement still targets the right one.
{
  my $schema = pg_schema(16);
  my $rs     = $schema->resultset('Artist');

  $schema->is_executed_sql_bind(
    sub {
      $rs->upsert(
        { charfield => 'c', rank => 3, name => 'foo' },
        { key => 'u_nullable', update => ['name'], result => 'void' }
      );
    },
    [[
      'INSERT INTO "artist" ("charfield", "name", "rank") VALUES (?, ?, ?) '
    . 'ON CONFLICT ("charfield", "rank") DO UPDATE SET "name" = EXCLUDED."name"',
      [ { dbic_colname => 'charfield', sqlt_datatype => 'char', sqlt_size => 10 } => 'c' ],
      [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'foo' ],
      [ { dbic_colname => 'rank', sqlt_datatype => 'integer' } => 3 ]
    ]],
    'a multi-column key => $constraint arbitrates on its columns'
  );
}

{
  my $schema = pg_schema(16);
  my $rs     = $schema->resultset('Artist');

  my $count;
  $schema->is_executed_sql_bind(
    sub {
      $count = $rs->upsert({ artistid => 7, name => 'foo' }, { result => 'count' });
    },
    [[
      'INSERT INTO "artist" ("artistid", "name") VALUES (?, ?) '
    . 'ON CONFLICT ("artistid") DO UPDATE SET "name" = EXCLUDED."name"',
      [ { dbic_colname => 'artistid', sqlt_datatype => 'integer' } => 7 ],
      [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'foo' ]
    ]],
    "the primary key is the default conflict target; result => 'count' skips RETURNING"
  );
  is $count, 1, 'count is the affected-row count of the statement';
}

# The whole point, end to end: $rs->upsert(..., { update_where => ... }).
{
  my $schema = pg_schema(16);
  my $rs     = $schema->resultset('Artist');
  $schema->storage->mock_persistent(qr/^INSERT INTO "artist"/, [ [42] ]);

  $schema->is_executed_sql_bind(
    sub {
      $rs->upsert(
        { name => 'foo', rank => 3 },
        {
          conflict_target => ['name'],
          update_where    => { rank => { '<' => { -attempted => 'rank' } } }
        }
      );
    },
    [[
      'INSERT INTO "artist" ("name", "rank") VALUES (?, ?) '
    . 'ON CONFLICT ("name") DO UPDATE SET "rank" = EXCLUDED."rank" '
    . 'WHERE "artist"."rank" < EXCLUDED."rank" '
    . 'RETURNING "artistid"',
      [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'foo' ],
      [ { dbic_colname => 'rank', sqlt_datatype => 'integer' } => 3 ]
    ]],
    'upsert() with update_where emits the conditional DO UPDATE'
  );
}

# ---------------------------------------------------------------------------
# the bind of a plain value is the maker's to shape (karr k122)
#
# A plain value in the update set is bound the way the maker binds every other
# value: [ $column => $value ] under bindtype 'columns' (the sync driver), the
# bare value under 'normal'. The future_io and the ev transport build their
# maker without a bindtype, which is 'normal'. The claim: no bind of the
# statement is in another shape than its neighbours -- a bind written as
# [ charfield => 'fixed' ] among bare values reaches the driver as an array,
# and it writes that into the column.
# ---------------------------------------------------------------------------

{
  my %makers = (
    columns => $sqlmaker,
    normal  => DBIO::PostgreSQL::SQLMaker->new(
      quote_char => '"', name_sep => '.', bindtype => 'normal'
    ),
    # what DBIO::PostgreSQL::Storage::Async::_sql_maker_args hands over
    'no bindtype' => DBIO::PostgreSQL::SQLMaker->new(
      quote_char => '"', name_sep => '.', limit_dialect => 'LimitOffset'
    ),
  );

  for my $kind ('columns', 'normal', 'no bindtype') {
    my $maker = $makers{$kind};
    my $bound = sub {
      my ($col, $val) = @_;
      return $kind eq 'columns' ? [ $col => $val ] : $val;
    };
    my @values = ( $bound->(name => 'foo'), $bound->(rank => 3) );

    my ($sql, @bind) = $maker->insert('artist', \%data, {
      on_conflict => {
        target => ['name'], action => 'update',
        set    => { charfield => 'fixed', rank => undef },
      }
    });
    is_deeply \@bind,
      [ @values, $bound->(charfield => 'fixed'), $bound->(rank => undef) ],
      "$kind: the binds of a plain-value update set are in the maker's shape";

    ($sql, @bind) = $maker->insert('artist', \%data, {
      on_conflict => {
        target => ['name'], action => 'update',
        set    => { charfield => 'fixed' },
        where  => { rank => { '<' => 5 } },
      }
    });
    is_deeply \@bind,
      [ @values, $bound->(charfield => 'fixed'), $bound->(rank => 5) ],
      "$kind: ... with update_where, the SET bind before the condition's";

    ($sql, @bind) = $maker->insert('artist', \%data, {
      on_conflict => {
        target => ['name'], action => 'update',
        set    => {
          charfield => \[ '? || ?', 'a', 'b' ],
          rank      => { -attempted => 'rank' },
        },
      }
    });
    is_deeply \@bind, [ @values, 'a', 'b' ],
      "$kind: a literal's binds stay the caller's, -attempted adds none";
  }
}

done_testing;
