use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff;

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

sub col {
  my ($name, $type, %more) = @_;
  return { column_name => $name, data_type => $type, not_null => 0, identity => '',
    generated => '', depends_on_columns => [], %more };
}
sub model {
  my (%more) = @_;
  my $type = delete $more{type} // 'integer';
  my $cols = delete $more{columns} // [ col(id => 'integer'), col(v => $type), col(w => 'integer') ];
  return {
    tables => { 'public.t' => { schema_name => 'public', table_name => 't', kind => 'r' } },
    columns => { 'public.t' => $cols },
    %more,
  };
}
sub statements {
  my ($source, $target) = @_;
  return [ map { $_->as_sql } @{ DBIO::PostgreSQL::Diff->new(source => $source, target => $target)->operations } ];
}

sub refused {
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

done_testing;
