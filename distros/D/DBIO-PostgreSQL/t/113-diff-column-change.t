use strict;
use warnings;
use Test::More;
use DBIO::PostgreSQL::Diff::Column;
use DBIO::PostgreSQL::Diff;
use DBIO::Deploy::Base;
use DBIO::PostgreSQL::Deploy;
use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';

# karr k121, point U3: the type of a column changes between two enum or
# composite types.
#
# WHY it exists: the model the diff reads (the catalog row, as
# Introspect::Columns gives it) names a column's type in data_type
# ('role_old') and tells its kind in type_category ('e' enum, 'c'
# composite). The diff wrote USING only for a target whose data_type is the
# literal 'enum' -- a shape no introspected model has -- so ALTER COLUMN ...
# TYPE between two enums or two composites went to the server without it and
# died with 'column "v" cannot be cast automatically to type ...'. These
# tests build the operations from the introspected shape and read what the
# statements say; t/113-diff-column-change-live.t runs them on a server.
subtest 'diff-column-type-change' => sub {
  my $tables = { 'public.t' => { schema_name => 'public', table_name => 't' } };

  my sub col {
    my (%c) = @_;
    my %kind = (
      e => 'enum_type', c => 'composite_type',
    );
    my $category = $c{category} // 'b';
    return {
      column_name   => 'v',
      data_type     => $c{type},
      not_null      => $c{not_null} // 0,
      default_value => $c{default},
      type_category => $category,
      type_schema   => 'public',
      ( $kind{$category} ? ($kind{$category} => $c{type}) : () ),
    };
  }

  my sub types {
    return +{ map { ("public.$_->[0]" => {
      schema_name => 'public', type_name => $_->[0], type_kind => 'composite',
      attributes => [ map { +{ name => $_->[0], type => $_->[1], ordinal => $_->[2] } } @{ $_->[1] } ],
    }) } @_ };
  }

  my sub ops {
    my ($from, $to, @types) = @_;
    return DBIO::PostgreSQL::Diff::Column->diff(
      { 'public.t' => [ $from ] }, { 'public.t' => [ $to ] }, $tables, $tables, @types,
    );
  }

  my sub sql { join "\n", map { $_->as_sql } @_ }

  # enum -> another enum
  {
    my @ops = ops(col(type => 'e_old', category => 'e'), col(type => 'e_new', category => 'e'));
    is(scalar @ops, 1, 'enum to enum: one operation');
    is(sql(@ops), 'ALTER TABLE public.t ALTER COLUMN v TYPE e_new USING v::text::e_new;',
      'enum to enum: the value goes through text');
  }

  # enum -> another enum, with a default of the old type
  {
    my @ops = ops(
      col(type => 'e_old', category => 'e', default => "'a'::e_old"),
      col(type => 'e_new', category => 'e', default => "'a'::e_new"),
    );
    is(sql(@ops), join("\n",
      'ALTER TABLE public.t ALTER COLUMN v DROP DEFAULT;',
      'ALTER TABLE public.t ALTER COLUMN v TYPE e_new USING v::text::e_new;',
      "ALTER TABLE public.t ALTER COLUMN v SET DEFAULT 'a'::e_new;",
    ), 'enum to enum with a default: it goes before the type and comes back behind it');
  }

  # enum -> another enum, the default the same text in both (an integer-like
  # literal would be): it is dropped for the type, so it is set again
  {
    my @ops = ops(
      col(type => 'e_old', category => 'e', default => "'a'"),
      col(type => 'e_new', category => 'e', default => "'a'"),
    );
    my $sql = sql(@ops);
    like($sql, qr/DROP DEFAULT;\nALTER TABLE public\.t ALTER COLUMN v TYPE e_new USING .*\nALTER TABLE public\.t ALTER COLUMN v SET DEFAULT 'a';\z/,
      'a default of the same text is set again behind the type');
  }

  # enum -> text and back
  {
    is(sql(ops(col(type => 'e_old', category => 'e'), col(type => 'text'))),
      'ALTER TABLE public.t ALTER COLUMN v TYPE text;',
      'enum to text: the server converts on its own, no USING');
    is(sql(ops(col(type => 'text'), col(type => 'e_new', category => 'e'))),
      'ALTER TABLE public.t ALTER COLUMN v TYPE e_new USING v::text::e_new;',
      'text to enum: USING through text');
  }

  # the normalized shape (data_type enum + pg_enum_type) keeps working
  {
    my @ops = ops(
      { column_name => 'v', data_type => 'enum', pg_enum_type => 'a.x', not_null => 0 },
      { column_name => 'v', data_type => 'enum', pg_enum_type => 'a.y', not_null => 0 },
    );
    is(sql(@ops), 'ALTER TABLE public.t ALTER COLUMN v TYPE a.y USING v::text::a.y;',
      'the normalized enum shape is written as before');
  }

  # composite -> composite of the same attributes
  {
    my $attrs = [ [ x => 'integer', 1 ], [ y => 'text', 2 ] ];
    my @t = (types([ c_old => $attrs ], [ c_new => $attrs ]));
    my @ops = ops(col(type => 'c_old', category => 'c'), col(type => 'c_new', category => 'c'), $t[0], $t[0]);
    is(sql(@ops), 'ALTER TABLE public.t ALTER COLUMN v TYPE c_new USING v::text::c_new;',
      'composite to composite of the same attributes: USING through text');
  }

  # composite -> composite of other attributes: refused
  {
    my @t = (types(
      [ c_old   => [ [ x => 'integer', 1 ], [ y => 'text', 2 ] ] ],
      [ c_other => [ [ y => 'text', 1 ], [ x => 'integer', 2 ] ] ],
      [ c_few   => [ [ x => 'integer', 1 ] ] ],
    ));
    for my $to (qw( c_other c_few )) {
      my @ops = eval { ops(col(type => 'c_old', category => 'c'), col(type => $to, category => 'c'), $t[0], $t[0]) };
      my $error = $@;
      ok(!@ops, "composite to $to: no operations");
      like($error, qr/\Arefusing to diff: column public\.t\.v changes from composite type c_old to $to,/,
        "composite to $to: refused, naming both");
      like($error, qr/No statement was generated\./, "composite to $to: and says no statement was written");
    }
  }

  # composite -> text / text -> composite
  {
    is(sql(ops(col(type => 'c_old', category => 'c'), col(type => 'text'))),
      'ALTER TABLE public.t ALTER COLUMN v TYPE text;',
      'composite to text: no USING');
    is(sql(ops(col(type => 'text'), col(type => 'c_new', category => 'c'))),
      'ALTER TABLE public.t ALTER COLUMN v TYPE c_new USING v::text::c_new;',
      'text to composite: USING through text');
  }

  # the types of a model that has none are not asked: the statement is written
  {
    is(sql(ops(col(type => 'c_old', category => 'c'), col(type => 'c_new', category => 'c'))),
      'ALTER TABLE public.t ALTER COLUMN v TYPE c_new USING v::text::c_new;',
      'composite to composite, the model giving no types: written, the server is the judge');
  }

  # a plain type change stays as it was
  {
    is(sql(ops(col(type => 'varchar(50)'), col(type => 'text'))),
      'ALTER TABLE public.t ALTER COLUMN v TYPE text;', 'a plain type change has no USING');
    is(sql(ops(col(type => 'integer', default => '1'), col(type => 'bigint', default => '1'))),
      'ALTER TABLE public.t ALTER COLUMN v TYPE bigint;', 'and keeps its default');
  }
};

# karr dbio-postgresql-postgis k28: a layer supplies the USING expression of a
# column's type change through register_using_hook. These tests pin what the
# diff writes with a fake hook; t/113-diff-column-change-live.t runs it.
subtest 'diff-column-using-hook' => sub {
  my $C = 'DBIO::PostgreSQL::Diff::Column';
  my $tables = { 'public.t' => { schema_name => 'public', table_name => 't' } };

  my sub col {
    my ($type, $category) = @_;
    $category //= 'b';
    return {
      column_name => 'v', data_type => $type, not_null => 0,
      type_category => $category, type_schema => 'public',
      ( $category eq 'e' ? (enum_type => $type) : () ),
      ( $category eq 'c' ? (composite_type => $type) : () ),
    };
  }

  my sub sql {
    my ($from, $to) = @_;
    my @ops = $C->diff({ 'public.t' => [ $from ] }, { 'public.t' => [ $to ] }, $tables, $tables);
    return join "\n", map { $_->as_sql } @ops;
  }

  my $PLAIN = 'ALTER TABLE public.t ALTER COLUMN v TYPE integer;';
  my @asked;

  is(sql(col('text'), col('integer')), $PLAIN, 'no hook: no USING');

  $C->register_using_hook(h1 => sub {
    my ($ctx) = @_;
    push @asked, $ctx;
    return "$ctx->{column}::integer";
  });
  is(sql(col('text'), col('integer')),
    'ALTER TABLE public.t ALTER COLUMN v TYPE integer USING v::integer;',
    'a hook: its expression is the USING of the ALTER');
  is(scalar @asked, 1, 'asked once');
  my $ctx = $asked[0];
  is($ctx->{table_key}, 'public.t', 'ctx table_key');
  is($ctx->{column_name}, 'v', 'ctx column_name');
  is($ctx->{column}, 'v', 'ctx column');
  is($ctx->{old_type}, 'text', 'ctx old_type');
  is($ctx->{new_type}, 'integer', 'ctx new_type');
  is($ctx->{old_info}{data_type}, 'text', 'ctx old_info');
  is($ctx->{new_info}{data_type}, 'integer', 'ctx new_info');

  @asked = ();
  sql(col('integer'), col('integer'));
  is(scalar @asked, 0, 'not asked when the type stays');

  is(sql(col('text'), col('e_new', 'e')),
    'ALTER TABLE public.t ALTER COLUMN v TYPE e_new USING v::text::e_new;',
    'enum target: the enum path keeps its USING');
  sql(col('text'), col('c_new', 'c'));
  is(scalar @asked, 0, 'not asked for an enum or composite target');

  # first hit wins; undef and empty are passed over
  $C->unregister_using_hook('h1');
  $C->register_using_hook(none  => sub { undef });
  $C->register_using_hook(empty => sub { '' });
  $C->register_using_hook(a     => sub { 'first_expr' });
  $C->register_using_hook(b     => sub { 'second_expr' });
  is(sql(col('text'), col('integer')),
    'ALTER TABLE public.t ALTER COLUMN v TYPE integer USING first_expr;',
    'the first non-empty answer wins');
  $C->unregister_using_hook($_) for qw(none empty a b);
  is(sql(col('text'), col('integer')), $PLAIN, 'unregistered: the default is back');

  # a dying hook stops the diff
  $C->register_using_hook(boom => sub { die "boom\n" });
  ok(!eval { sql(col('text'), col('integer')); 1 }, 'a dying hook dies');
  is($@, "boom\n", 'with its own error');
  $C->unregister_using_hook('boom');

  # a non-string answer is refused
  $C->register_using_hook(ref => sub { [ 'x' ] });
  ok(!eval { sql(col('text'), col('integer')); 1 }, 'a reference is refused');
  like($@, qr/USING hook 'ref' .*returned a ARRAY reference, not a plain string/,
    'with a clear message');
  $C->unregister_using_hook('ref');

  is(sql(col('text'), col('integer')), $PLAIN, 'clean afterwards');
};

# karr k121 (U6, points 5 and 8) -- a column whose type changes while a
# policy, a trigger, a generated column or a view outside the declared schemas
# reads it.
#
# WHY it exists: PostgreSQL does not alter the type of such a column (cannot
# alter type of a column used in a policy definition / in a trigger
# definition / by a generated column / by a view or rule). The model did not
# carry these dependencies, so the diff wrote the ALTER and the server refused
# it in mid-apply. The model now has them (depends_on_columns on policies,
# triggers and columns, the outside_readers section), and the diff is refused
# when it is built, naming the column and the object and the statements that
# take the object out of the way.
#
# What is held, without a database (t/137-...-live.t holds it against one):
#
#  1. each of the four readers refuses the type change, by name, with its
#     DROP statement as the way out and no statement generated;
#  2. a change that is none of type, and the type of a column nobody reads,
#     are made as before, with the readers there;
#  3. a reader of another column of the same table does not stop it;
#  4. a table that has the column from the one that changes: its reader counts.
subtest 'diff-column-type-change-other-readers' => sub {
  my sub col {
    my ($name, $type, %more) = @_;
    return { column_name => $name, data_type => $type, not_null => 0, identity => '',
      generated => '', depends_on_columns => [], %more };
  }
  my sub model {
    my (%more) = @_;
    my $type = delete $more{type} // 'integer';
    my $cols = delete $more{columns} // [ col(id => 'integer'), col(v => $type), col(w => 'integer') ];
    return {
      tables => { 'public.t' => { schema_name => 'public', table_name => 't', kind => 'r' } },
      columns => { 'public.t' => $cols },
      %more,
    };
  }
  my sub statements {
    my ($source, $target) = @_;
    return [ map { $_->as_sql } @{ DBIO::PostgreSQL::Diff->new(source => $source, target => $target)->operations } ];
  }

  my sub refused {
    my ($label, $source, $target, @like) = @_;
    my $ops = eval { DBIO::PostgreSQL::Diff->new(source => $source, target => $target)->operations };
    my $error = $@;
    subtest $label => sub {
      is $ops, undef, 'no operation is built';
      like $error, qr/\Arefusing to diff: column public\.t\.v changes its type from integer to bigint while /,
        'the diff is refused, naming the column and both types';
      like $error, $_, "and matches $_" for @like;
      like $error, qr/No statement was generated\./, 'and says that nothing was generated';
    };
  }

  my $target = model(type => 'bigint');

  # ---------------------------------------------------------------------------
  # 1. the four readers
  # ---------------------------------------------------------------------------
  refused('a policy', model(
    policies => { 'public.t' => { p => {
      schema_name => 'public', table_name => 't', policy_name => 'p',
      depends_on_columns => { 'public.t' => ['v'] },
    } } },
  ), $target,
    qr/while policy p on public\.t depends on it/,
    qr/^  DROP POLICY p ON public\.t;$/m,
  );

  refused('a trigger (WHEN or UPDATE OF)', model(
    triggers => { 'public.t' => { trg => {
      schema_name => 'public', table_name => 't', trigger_name => 'trg',
      depends_on_columns => { 'public.t' => ['v'] },
    } } },
  ), $target,
    qr/while trigger trg on public\.t depends on it/,
    qr/^  DROP TRIGGER trg ON public\.t;$/m,
  );

  refused('a generated column', model(
    columns => [ col(id => 'integer'), col(v => 'integer'),
      col(g => 'integer', generated => 's', default_value => '(v * 2)', depends_on_columns => ['v']) ],
  ), model(
    type => 'bigint',
    columns => [ col(id => 'integer'), col(v => 'bigint'),
      col(g => 'integer', generated => 's', default_value => '(v * 2)', depends_on_columns => ['v']) ],
  ),
    qr/while generated column public\.t\.g depends on it/,
    qr/^  ALTER TABLE public\.t DROP COLUMN g;$/m,
  );

  refused('a view outside the declared schemas', model(
    outside_readers => { 'other.vw' => {
      schema_name => 'other', table_name => 'vw', kind => 'v',
      depends_on_columns => { 'public.t' => ['v'] },
    } },
  ), $target,
    qr/while view other\.vw \(outside the declared schemas\) depends on it/,
    qr/^  DROP VIEW other\.vw;$/m,
  );

  {
    my %mixed = (tables => { 'public.T' => { schema_name => 'public', table_name => 'T', kind => 'r' } });
    my $source = model(%mixed,
      policies => { 'public.T' => { Pol => {
        schema_name => 'public', table_name => 'T', policy_name => 'Pol',
        depends_on_columns => { 'public.T' => ['v'] },
      } } },
    );
    $source->{columns} = { 'public.T' => delete $source->{columns}{'public.t'} };
    my $want = model(%mixed, type => 'bigint');
    $want->{columns} = { 'public.T' => delete $want->{columns}{'public.t'} };
    my $ops = eval { DBIO::PostgreSQL::Diff->new(source => $source, target => $want)->operations };
    is $ops, undef, 'a mixed-case table and policy: refused';
    like $@, qr/^  DROP POLICY "Pol" ON public\."T";$/m, 'and the way out is quoted';
  }

  # ---------------------------------------------------------------------------
  # 2. 3. the cases that stay as they were
  # ---------------------------------------------------------------------------
  my $readers = {
    policies => { 'public.t' => { p => { schema_name => 'public', table_name => 't',
      policy_name => 'p', depends_on_columns => { 'public.t' => ['w'] } } } },
    triggers => { 'public.t' => { trg => { schema_name => 'public', table_name => 't',
      trigger_name => 'trg', depends_on_columns => { 'public.t' => ['w'] } } } },
    outside_readers => { 'other.vw' => { schema_name => 'other', table_name => 'vw', kind => 'v',
      depends_on_columns => { 'public.t' => ['w'] } } },
  };

  is_deeply statements(model(%$readers), model(%$readers, type => 'bigint')),
    [ 'ALTER TABLE public.t ALTER COLUMN v TYPE bigint;' ],
    'a reader of another column of the table does not stop the type change';

  my $reads_v = {
    policies => { 'public.t' => { p => { schema_name => 'public', table_name => 't',
      policy_name => 'p', depends_on_columns => { 'public.t' => ['v'] } } } },
  };
  my $not_null = model(%$reads_v);
  $not_null->{columns}{'public.t'}[1]{not_null} = 1;
  is_deeply statements(model(%$reads_v), $not_null),
    [ 'ALTER TABLE public.t ALTER COLUMN v SET NOT NULL;' ],
    'a change that is none of type is made under a policy that reads the column';

  # ---------------------------------------------------------------------------
  # 4. a table that has the column from the one that changes
  # ---------------------------------------------------------------------------
  {
    my $tables = {
      'public.t'  => { schema_name => 'public', table_name => 't', kind => 'p' },
      'public.t1' => { schema_name => 'public', table_name => 't1', kind => 'r',
        partition_of => 'public.t' },
    };
    my $source = {
      tables  => $tables,
      columns => {
        'public.t'  => [ col(id => 'integer'), col(v => 'integer') ],
        'public.t1' => [ col(id => 'integer'), col(v => 'integer', is_local => 0) ],
      },
      policies => { 'public.t1' => { p => { schema_name => 'public', table_name => 't1',
        policy_name => 'p', depends_on_columns => { 'public.t1' => ['v'] } } } },
    };
    my $want = {
      tables  => $tables,
      columns => {
        'public.t'  => [ col(id => 'integer'), col(v => 'bigint') ],
        'public.t1' => [ col(id => 'integer'), col(v => 'bigint', is_local => 0) ],
      },
    };
    my $error = eval { DBIO::PostgreSQL::Diff->new(source => $source, target => $want)->operations; 1 }
      ? '' : $@;
    like $error, qr/column public\.t\.v changes its type .* while policy p on public\.t1 depends on it/s,
      'a policy on a partition that reads the column it has from the table counts';
  }
};

# karr k150, case diff-default-removed of core's Diff list (ADR 0060).
#
# WHY it exists: the column diff compared through DBIO::Diff::Compare, whose
# desired-state rule skips a field the target leaves undef. Both models of this
# driver are read from a catalog, so an undef default_value in the target is a
# column that has none, not a column that prescribes nothing. A declaration
# that dropped a default left the database's default in place: the upgrade
# wrote no statement and the next diff was empty too, so the drift was silent.
subtest 'diff-default-dropped' => sub {
  my $tables = { 'public.t' => { schema_name => 'public', table_name => 't' } };

  my sub col {
    my (%c) = @_;
    return {
      column_name   => $c{name} // 'c',
      data_type     => 'character varying(10)',
      not_null      => 0,
      default_value => $c{default},
      ( defined $c{generated} ? (generated => $c{generated}) : () ),
    };
  }

  my sub sql {
    my ($from, $to) = @_;
    return join "\n", map { $_->as_sql } DBIO::PostgreSQL::Diff::Column->diff(
      { 'public.t' => [ $from ] }, { 'public.t' => [ $to ] }, $tables, $tables,
    );
  }

  is sql(col(default => q{'x'::character varying}), col()),
    'ALTER TABLE public.t ALTER COLUMN c DROP DEFAULT;',
    'a default the target does not have is dropped';

  is sql(col(default => q{'x'::character varying}), col(default => q{'x'::character varying})),
    '', 'the same default is no change';

  is sql(col(), col(default => q{'y'::character varying})),
    q{ALTER TABLE public.t ALTER COLUMN c SET DEFAULT 'y'::character varying;},
    'a default the database lacks is set';
};

# karr k152 -- the guard of the deploy (core k399) asks the column operation
# whether a change of type may alter a stored value.
#
# WHY it exists: apply runs a diff that drops something or changes a type in a
# way that can round, cut or re-read values only when it is released with
# allow_destructive. The operations answer through `lossy`; a type change the
# operation does not know to keep every value is lossy -- the guard errs
# towards asking. integer to bigint, a longer varchar, a numeric that keeps
# every digit are what a deploy runs without the release.
#
# Without a server. t/196-deploy-guard-live.t has apply against one.
subtest 'diff-column-lossy' => sub {
  my $tables = { 'public.t' => { schema_name => 'public', table_name => 't' } };

  my sub col {
    my ($type, %more) = @_;
    return { column_name => 'v', data_type => $type, not_null => 0, %more };
  }

  # The operations of a column that goes from one declaration to the other.
  my sub ops {
    my ($from, $to) = @_;
    return DBIO::PostgreSQL::Diff::Column->diff(
      { 'public.t' => [ $from ] }, { 'public.t' => [ $to ] }, $tables, $tables);
  }

  my sub lossy {
    my ($from, $to) = @_;
    my @ops = ops($from, $to);
    die "expected one operation, got " . @ops unless @ops == 1;
    return $ops[0]->lossy ? 1 : 0;
  }

  # --- 1. the table: every pair says what it keeps -------------------------------

  my @cases = (
    # [ from, to, lossy, why ]
    [ 'smallint', 'integer', 0, 'smallint to integer' ],
    [ 'smallint', 'bigint',  0, 'smallint to bigint' ],
    [ 'integer',  'bigint',  0, 'integer to bigint' ],
    [ 'bigint',   'integer', 1, 'bigint to integer cuts' ],
    [ 'integer',  'smallint', 1, 'integer to smallint cuts' ],
    [ 'character varying(10)', 'character varying(20)', 0, 'varchar(10) to varchar(20)' ],
    [ 'character varying(10)', 'character varying(10)', undef, 'the same type is no change' ],
    [ 'character varying(20)', 'character varying(10)', 1, 'varchar(20) to varchar(10) cuts' ],
    [ 'character varying(10)', 'character varying', 0, 'varchar(10) to varchar without limit' ],
    [ 'character varying', 'character varying(10)', 1, 'varchar without limit to varchar(10) cuts' ],
    [ 'character varying(10)', 'text', 0, 'varchar(n) to text' ],
    [ 'text', 'character varying(10)', 1, 'text to varchar(n) cuts' ],
    [ 'text', 'character varying', 0, 'text to varchar without limit (the same strings)' ],
    [ 'numeric(10,2)', 'numeric(12,2)', 0, 'numeric(10,2) to numeric(12,2) grows' ],
    [ 'numeric(10,2)', 'numeric(12,4)', 0, 'numeric(10,2) to numeric(12,4): more scale, as many digits before the point' ],
    [ 'numeric(10,2)', 'numeric(10,4)', 1, 'numeric(10,2) to numeric(10,4): fewer digits before the point' ],
    [ 'numeric(10,2)', 'numeric(10,1)', 1, 'numeric(10,2) to numeric(10,1) rounds' ],
    [ 'numeric(10,2)', 'numeric(8,2)', 1, 'numeric(10,2) to numeric(8,2) can overflow' ],
    [ 'numeric(10,2)', 'numeric', 0, 'numeric(10,2) to numeric without limit' ],
    [ 'numeric', 'numeric(10,2)', 1, 'numeric without limit to numeric(10,2)' ],
    [ 'numeric(10,0)', 'numeric(11,0)', 0, 'numeric(10) to numeric(11)' ],
    [ 'timestamp(3) with time zone', 'timestamp(6) with time zone', 0, 'timestamptz(3) to (6)' ],
    [ 'timestamp(6) with time zone', 'timestamp(3) with time zone', 1, 'timestamptz(6) to (3) rounds' ],
    [ 'timestamp without time zone', 'timestamp with time zone', 1, 'timestamp to timestamptz reads the session time zone' ],
    [ 'real', 'double precision', 1, 'real to double precision is not in the list' ],
    [ 'integer', 'text', 1, 'integer to text' ],
    [ 'text', 'integer', 1, 'text to integer' ],
    [ 'character(5)', 'character(10)', 1, 'char(n) pads: left out' ],
    [ 'integer', 'numeric(12,0)', 1, 'integer to numeric is not in the list' ],
  );

  for my $case (@cases) {
    my ($from, $to, $want, $why) = @$case;
    if (!defined $want) {
      is scalar(() = ops(col($from), col($to))), 0, "$why: no operation";
      next;
    }
    is lossy(col($from), col($to)), $want, ($want ? 'lossy' : 'lossless') . ": $why";
  }

  # the size given as a key of its own, as a model built by hand has it
  is lossy(col('varchar', size => 10), col('varchar', size => 20)), 0, 'a size key: varchar 10 to 20 is lossless';
  is lossy(col('varchar', size => 20), col('varchar', size => 10)), 1, '... and 20 to 10 is lossy';
  is lossy(col('numeric', size => [10, 2]), col('numeric', size => [12, 2])), 0, '... numeric [10,2] to [12,2] is lossless';

  # --- 2. what else a column operation says --------------------------------------

  {
    my @ops = ops(col('integer'), col('integer', not_null => 1));
    is scalar(@ops), 1, 'NOT NULL set: one operation';
    ok !$ops[0]->lossy, '... not lossy (the server refuses it over NULLs, which _check_before_apply names)';

    @ops = ops(col('text'), col('text', default_value => q{'x'::text}));
    ok !$ops[0]->lossy, 'a default set is not lossy';

    my ($drop) = DBIO::PostgreSQL::Diff::Column->new(action => 'drop', column_name => 'v', table_key => 'public.t');
    ok !$drop->lossy, 'a column drop answers through its action (a drop), not through lossy';
    my ($add) = DBIO::PostgreSQL::Diff::Column->new(action => 'add', column_name => 'v', table_key => 'public.t',
      new_info => col('text'));
    ok !$add->lossy, 'an added column is not lossy';
  }

  # enum and composite changes are lossy, with or without USING
  {
    my $enum = sub { col($_[0], type_category => 'e', type_schema => 'public', enum_type => $_[0]) };
    is lossy($enum->('e_old'), $enum->('e_new')), 1, 'enum to enum is lossy';
    is lossy(col('text'), $enum->('e_new')), 1, 'text to enum is lossy';
    is lossy($enum->('e_old'), col('text')), 1, 'enum to text is lossy';
  }

  # a USING makes any change lossy, and is decided once
  {
    my $calls = 0;
    DBIO::PostgreSQL::Diff::Column->register_using_hook(k152 => sub {
      $calls++;
      return 'v::bigint' if $_[0]{new_type} eq 'bigint';
      return undef;
    });
    my @ops = ops(col('integer'), col('bigint'));
    is $ops[0]->lossy, 1, 'integer to bigint with a USING of a hook is lossy';
    like $ops[0]->as_sql, qr/TYPE bigint USING v::bigint;/, '... the statement carries the same USING';
    my $once = $calls;
    $ops[0]->lossy; $ops[0]->as_sql; $ops[0]->as_sql;
    is $calls, $once, '... the hook was asked once, when the operation was built';
    DBIO::PostgreSQL::Diff::Column->unregister_using_hook('k152');
    is lossy(col('integer'), col('bigint')), 0, 'without the hook integer to bigint is lossless again';
  }

  # --- 3. the guard reads it -----------------------------------------------------

  {
    my $model = sub {
      my ($type) = @_;
      return {
        tables  => { 'public.t' => { schema_name => 'public', table_name => 't', kind => 'r' } },
        columns => { 'public.t' => [ col($type) ] },
      };
    };
    my $widen = DBIO::PostgreSQL::Diff->new(source => $model->('integer'), target => $model->('bigint'));
    is scalar(() = $widen->destructive_operations), 0, 'integer to bigint: the guard has nothing to ask for';
    my $narrow = DBIO::PostgreSQL::Diff->new(source => $model->('bigint'), target => $model->('integer'));
    my @risky = $narrow->destructive_operations;
    is scalar(@risky), 1, 'bigint to integer: the guard asks';
    like $risky[0]->summary, qr/column: public\.t\.v \(integer\)/, '... and names the column';
  }

  # --- 4. the deploy is the base's -----------------------------------------------

  for my $method (qw( apply upgrade )) {
    is(DBIO::PostgreSQL::Deploy->can($method), DBIO::Deploy::Base->can($method),
      "Deploy inherits $method from DBIO::Deploy::Base: the same code, not a copy");
  }
  ok(DBIO::PostgreSQL::Deploy->can('_check_before_apply') != DBIO::Deploy::Base->can('_check_before_apply'),
    'the driver takes part through _check_before_apply');
};

done_testing;
