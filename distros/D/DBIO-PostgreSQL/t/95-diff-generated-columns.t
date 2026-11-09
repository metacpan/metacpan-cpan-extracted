use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Introspect;

# karr k100 -- a generated column is written as a generated column.
#
# WHY it exists: for a generated column the catalog keeps the expression where
# it keeps a default (pg_attrdef, read with pg_get_expr) and marks the column
# in attgenerated: 's' stored, 'v' virtual (PostgreSQL 18). The diff wrote the
# expression as a DEFAULT and the mark as a bare key word,
#
#   g integer DEFAULT (id * 2) GENERATED ALWAYS AS STORED
#
# which is no statement PostgreSQL accepts; a virtual column lost the mark
# altogether and became an ordinary column with a default that no table can
# have (a default cannot name another column). ADD COLUMN did not look at
# attgenerated at all. A change of the expression became ALTER COLUMN ... SET
# DEFAULT, which the server refuses for a generated column.
#
# What is held here (t/96 runs the statements against a server):
#
#  1. CREATE TABLE and ADD COLUMN write GENERATED ALWAYS AS (expr) STORED or
#     VIRTUAL, the expression in parentheses of the diff's own, and no DEFAULT;
#  2. a change to how an existing column is generated is refused, naming the
#     table, the column and what changes.

sub column {
  my ($name, %more) = @_;
  return { column_name => $name, data_type => 'integer', not_null => 0, %more };
}

my %TABLE = ( 'public.t' => { schema_name => 'public', table_name => 't', kind => 'r' } );

sub model { return { tables => { %TABLE }, columns => { 'public.t' => [@_] } } }

sub sql_of {
  my ($source, $target) = @_;
  return DBIO::PostgreSQL::Diff->new(source => $source, target => $target)->as_sql;
}

# pg_get_expr gives "(id * 2)" for an operator expression and "lower(name)"
# for a function call: the parentheses of GENERATED ALWAYS AS (...) are not
# part of what the catalog hands back.
my @GENERATED = (
  column('s',  generated => 's', default_value => '(id * 2)'),
  column('v',  generated => 'v', default_value => '(id * 3)'),
  column('sn', generated => 's', default_value => '(id + 1)', not_null => 1),
  column('fn', generated => 's', default_value => 'lower(name)', data_type => 'text'),
);

# ---------------------------------------------------------------------------
# 1. Written as what it is
# ---------------------------------------------------------------------------
is(
  sql_of({ tables => {}, columns => {} }, model(column('id', not_null => 1), @GENERATED)),
  'CREATE TABLE public.t ('
    . 'id integer NOT NULL, '
    . 's integer GENERATED ALWAYS AS ((id * 2)) STORED, '
    . 'v integer GENERATED ALWAYS AS ((id * 3)) VIRTUAL, '
    . 'sn integer NOT NULL GENERATED ALWAYS AS ((id + 1)) STORED, '
    . 'fn text GENERATED ALWAYS AS (lower(name)) STORED);',
  'CREATE TABLE writes a stored and a virtual generated column, the expression in parentheses');

is(
  sql_of(model(column('id', not_null => 1)), model(column('id', not_null => 1), @GENERATED)),
  join("\n",
    'ALTER TABLE public.t ADD COLUMN fn text GENERATED ALWAYS AS (lower(name)) STORED;',
    'ALTER TABLE public.t ADD COLUMN s integer GENERATED ALWAYS AS ((id * 2)) STORED;',
    'ALTER TABLE public.t ADD COLUMN sn integer NOT NULL GENERATED ALWAYS AS ((id + 1)) STORED;',
    'ALTER TABLE public.t ADD COLUMN v integer GENERATED ALWAYS AS ((id * 3)) VIRTUAL;',
  ),
  'ADD COLUMN writes them the same way');

unlike(
  sql_of({ tables => {}, columns => {} }, model(@GENERATED))
    . sql_of(model(column('id')), model(column('id'), @GENERATED)),
  qr/DEFAULT/, 'the expression of a generated column is never written as a DEFAULT');

# An ordinary default and an identity column are untouched by all this.
is(
  sql_of({ tables => {}, columns => {} }, model(
    column('id', identity => 'a', generated => '', not_null => 1),
    column('n',  default_value => '0', generated => ''),
  )),
  'CREATE TABLE public.t (id integer NOT NULL GENERATED ALWAYS AS IDENTITY, n integer DEFAULT 0);',
  'a column with a default and an identity column are written as before');

is(DBIO::PostgreSQL::Introspect->generated_kind('s'), 'STORED',  'attgenerated s is STORED');
is(DBIO::PostgreSQL::Introspect->generated_kind('v'), 'VIRTUAL', 'attgenerated v is VIRTUAL');
is(DBIO::PostgreSQL::Introspect->generated_kind($_), undef, 'no mark, no kind')
  for '', undef;
throws_ok { DBIO::PostgreSQL::Introspect->generated_kind('x') }
  qr/attgenerated 'x'/, 'a mark this version does not know is not passed over';

# ---------------------------------------------------------------------------
# 2. A change to an existing column
# ---------------------------------------------------------------------------
my %plain   = ( generated => '' );
my %stored  = ( generated => 's', default_value => '(id * 2)' );
my %virtual = ( generated => 'v', default_value => '(id * 2)' );

for my $case (
  [ 'an ordinary column that becomes a generated one', { %plain },  { %stored },
    qr/is an ordinary column in the database and a generated column in the target/ ],
  [ 'a generated column that becomes an ordinary one', { %stored }, { %plain, default_value => '0' },
    qr/is a generated column in the database and an ordinary column in the target/ ],
  [ 'a stored column that becomes a virtual one',      { %stored }, { %virtual },
    qr/is a stored generated column in the database and a virtual one in the target/ ],
  [ 'another expression',                              { %stored }, { %stored, default_value => '(id * 5)' },
    qr/is generated from \(id \* 2\) in the database and from \(id \* 5\) in the target/ ],
) {
  my ($label, $from, $to, $reason) = @$case;
  my $diff = DBIO::PostgreSQL::Diff->new(
    source => model(column('id'), column('g', %$from)),
    target => model(column('id'), column('g', %$to)),
  );
  throws_ok { $diff->operations } qr/\Arefusing to diff: column public\.t\.g /,
    "$label is refused, naming table and column";
  like($@, $reason, '... and what changes');
}

# What does not touch the generation is no reason to refuse.
{
  my $diff = DBIO::PostgreSQL::Diff->new(
    source => model(column('id'), column('g', %stored)),
    target => model(column('id'), column('g', %stored, not_null => 1)),
  );
  is($diff->as_sql, 'ALTER TABLE public.t ALTER COLUMN g SET NOT NULL;',
    'a generated column that only becomes NOT NULL is altered as any column');
}

done_testing;
