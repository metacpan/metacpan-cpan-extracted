use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Index;

# Create index
my @ops = DBIO::PostgreSQL::Diff::Index->diff(
  {},
  {
    'public.users' => {
      idx_users_email => {
        index_name    => 'idx_users_email',
        access_method => 'btree',
        is_unique     => 1,
        definition    => 'CREATE UNIQUE INDEX idx_users_email ON public.users USING btree (email)',
        columns       => ['email'],
      },
    },
  },
);

is(scalar @ops, 1, 'one index to create');
is($ops[0]->action, 'create', 'action is create');
like($ops[0]->as_sql, qr/CREATE UNIQUE INDEX idx_users_email/, 'create index DDL');

# Drop index
@ops = DBIO::PostgreSQL::Diff::Index->diff(
  {
    'public.users' => {
      idx_old => {
        index_name    => 'idx_old',
        access_method => 'btree',
        columns       => ['old_col'],
      },
    },
  },
  {},
);

is(scalar @ops, 1, 'one index to drop');
is($ops[0]->action, 'drop', 'action is drop');
like($ops[0]->as_sql, qr/^DROP INDEX public\.idx_old;$/, 'drop index DDL, schema-qualified');

# karr k32: when the owning table is itself being dropped in the same pass
# (present in source tables, absent from target tables), DROP TABLE ... CASCADE
# already removes the table's indexes, so no standalone DROP INDEX must be
# emitted for them.
@ops = DBIO::PostgreSQL::Diff::Index->diff(
  {
    'public.leftover' => {
      leftover_pkey => {
        index_name => 'leftover_pkey',
        access_method => 'btree',
        is_unique  => 1,
        is_primary => 1,
        columns    => ['id'],
      },
    },
  },
  {},
  # source tables: the leftover table exists live
  { 'public.leftover' => { schema_name => 'public', table_name => 'leftover' } },
  # target tables: it is gone -> table is being dropped
  {},
);
is(scalar @ops, 0, 'no standalone DROP INDEX when owning table is dropped (CASCADE covers it)');

# karr k32 guard: do NOT over-suppress. If the table stays but one of its
# indexes is removed, the standalone DROP INDEX is still required.
@ops = DBIO::PostgreSQL::Diff::Index->diff(
  {
    'public.users' => {
      idx_users_email => {
        index_name => 'idx_users_email',
        access_method => 'btree',
        columns    => ['email'],
      },
    },
  },
  {},
  # source tables: users exists
  { 'public.users' => { schema_name => 'public', table_name => 'users' } },
  # target tables: users still exists -> only the index is being dropped
  { 'public.users' => { schema_name => 'public', table_name => 'users' } },
);
is(scalar @ops, 1, 'index drop still emitted when the table itself survives');
is($ops[0]->action, 'drop', 'surviving-table index drop is a drop op');
like($ops[0]->as_sql, qr/^DROP INDEX public\.idx_users_email;$/, 'surviving-table index still dropped standalone');

# karr k121 (U2, point 1): an index behind a constraint is dropped with the
# constraint. The server refuses DROP INDEX for it, and the model says which
# index that is (constraint_name, constraint_type); these are the claims
# without a server, t/112-diff-index-constraint-live.t has it measured.
{
  my $tables = { 'public.users' => { schema_name => 'public', table_name => 'users' } };
  my $idx = sub {
    my ($name, %more) = @_;
    return ($name => {
      index_name => $name, access_method => 'btree', is_unique => 1,
      definition => "CREATE UNIQUE INDEX $name ON public.users USING btree (email)",
      columns => ['email'], include_columns => [], storage_params => {},
      constraint_name => undef, constraint_type => undef, referenced_by => [],
      %more,
    });
  };
  my %unique = (constraint_name => 'users_email_key', constraint_type => 'u');

  my @drop = DBIO::PostgreSQL::Diff::Index->diff(
    { 'public.users' => { $idx->('users_email_key', %unique) } }, {}, $tables, $tables);
  is_deeply([ map { $_->as_sql } @drop ], ['ALTER TABLE public.users DROP CONSTRAINT users_email_key;'],
    'the index of a UNIQUE constraint is dropped as the constraint');
  like($drop[0]->summary, qr/^  -constraint: users_email_key \(on public\.users\)$/, '... and the summary says so');

  @drop = DBIO::PostgreSQL::Diff::Index->diff(
    { 'public.users' => { $idx->('users_email_uidx') } }, {}, $tables, $tables);
  is_deeply([ map { $_->as_sql } @drop ], ['DROP INDEX public.users_email_uidx;'],
    'a unique index without a constraint is dropped as an index');

  @drop = DBIO::PostgreSQL::Diff::Index->diff(
    { 'public.users' => { $idx->('users_pkey', is_primary => 1) } }, {}, $tables, $tables);
  is_deeply([ map { $_->as_sql } @drop ], ['ALTER TABLE public.users DROP CONSTRAINT users_pkey;'],
    'a primary key index without the constraint keys of the model is the primary key constraint\'s');

  # The constraint of the database goes, the target has the name as an index.
  my @ops = DBIO::PostgreSQL::Diff::Index->diff(
    { 'public.users' => { $idx->('users_email_key', %unique) } },
    { 'public.users' => { $idx->('users_email_key',
        definition => 'CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email, name)',
        columns => [ 'email', 'name' ]) } },
    $tables, $tables);
  is_deeply([ map { $_->as_sql } @ops ],
    [ 'ALTER TABLE public.users DROP CONSTRAINT users_email_key;',
      'CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email, name);' ],
    'a changed index behind a constraint the target has as an index: constraint dropped, index created');

  # The target has the constraint with another definition (karr k139): the
  # diff drops it and adds the one of the target. It used to refuse, because
  # the diff created no constraint (karr k101).
  @ops = DBIO::PostgreSQL::Diff::Index->diff(
    { 'public.users' => { $idx->('users_email_key', %unique) } },
    { 'public.users' => { $idx->('users_email_key', %unique,
        definition => 'CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email, name)',
        columns => [ 'email', 'name' ]) } },
    $tables, $tables);
  is_deeply([ map { $_->as_sql } @ops ],
    [ 'ALTER TABLE public.users DROP CONSTRAINT users_email_key;',
      'ALTER TABLE public.users ADD CONSTRAINT users_email_key UNIQUE (email, name);' ],
    'a changed constraint: DROP CONSTRAINT, then ADD CONSTRAINT of the target\'s columns');
  ok($ops[0]->replaced, '... the drop is the first half of the change, it stays ahead of the add');

  # What is still refused: a change the diff cannot write the constraint for
  my $refused = eval {
    DBIO::PostgreSQL::Diff::Index->diff(
      { 'public.users' => { $idx->('users_email_key', %unique) } },
      { 'public.users' => { $idx->('users_email_key', constraint_name => 'users_email_key', constraint_type => 'x',
          definition => 'CREATE INDEX users_email_key ON public.users USING gist (email)') } },
      $tables, $tables);
    1;
  } ? undef : $@;
  like($refused, qr/\Arefusing to diff: index users_email_key on public\.users is the index of the EXCLUDE constraint users_email_key/,
    'a changed constraint the diff cannot write is refused, naming index and constraint');
  like($refused, qr/^  +ALTER TABLE public\.users ADD CONSTRAINT users_email_key EXCLUDE \(\.\.\.\);$/m,
    '... with the clause it cannot write');
  like($refused, qr/No statement\s+was generated/, '... and says nothing was written');

  # An expression has no column to name: the clause is left open.
  $refused = eval {
    DBIO::PostgreSQL::Diff::Index->diff(
      { 'public.users' => { $idx->('users_x_excl', constraint_name => 'users_x_excl', constraint_type => 'x') } },
      { 'public.users' => { $idx->('users_x_excl', constraint_name => 'users_x_excl', constraint_type => 'x',
          definition => 'CREATE INDEX users_x_excl ON public.users USING btree (a, b)') } },
      $tables, $tables);
    1;
  } ? undef : $@;
  like($refused, qr/ADD CONSTRAINT users_x_excl EXCLUDE \(\.\.\.\);$/m,
    'an EXCLUDE constraint: the clause of its elements is left to the reader');

  # A foreign key of another table points at it: refused, for the drop and for the change.
  my @by = ({ schema_name => 'public', table_name => 'orders', constraint_name => 'orders_user_fkey' });
  $refused = eval {
    DBIO::PostgreSQL::Diff::Index->diff(
      { 'public.users' => { $idx->('users_email_key', %unique, referenced_by => \@by) } }, {}, $tables, $tables);
    1;
  } ? undef : $@;
  like($refused, qr/\Arefusing to diff: index users_email_key on public\.users is the index of the UNIQUE constraint/,
    'a constraint a foreign key points at is refused');
  like($refused, qr/^  +ALTER TABLE public\.orders DROP CONSTRAINT orders_user_fkey;$/m, '... naming the foreign key to drop first');

  # The table goes too: its indexes go with it, constraint or not.
  @drop = DBIO::PostgreSQL::Diff::Index->diff(
    { 'public.users' => { $idx->('users_email_key', %unique, referenced_by => \@by) } }, {}, $tables, {});
  is(scalar @drop, 0, 'no statement for the constraint of a table that is dropped');
}

done_testing;
