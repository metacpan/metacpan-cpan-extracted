use strict;
use warnings;

use Test::More;
use Scalar::Util ();

use DBIO::PostgreSQL::Diff;

# karr k120 (4) -- a column that changes its type under a declared view: the
# view is dropped, the column altered, the view created again.
#
# WHY it exists: PostgreSQL does not alter the type of a column a view reads
# (cannot alter type of a column used by a view or rule). The diff used to
# refuse that, with the DROP VIEW statements as the way out. The maintainer
# decided (2026-10-12): a view that comes from the declaration is dropped
# together with the views on it, the column altered, and the views created
# again in the order they depend on one another, in the one transaction
# Deploy::apply runs a diff in. A view that is only in the database is not the
# declaration's to recreate: it stays a refusal, naming it. A materialized
# view is not rebuilt either (decision 2026-10-16, which takes back that part
# of 2026-10-12): dropping it takes its data and its indexes, so a type change
# it reads -- directly, or through a view that would be rebuilt -- stays a
# refusal, naming table, column and the materialized view.
#
# What is held here, without a database (t/127-diff-view-rebuild-live.t holds
# it against a server):
#
#  1. a view of the target that reads the column: DROP VIEW, ALTER, CREATE VIEW,
#     and the definition written is the target's own, not the database's;
#  2. a view on a view: dropped from the top, created from the bottom, by the
#     dependency and not by the names;
#  3. a view only the database has, reading the column or standing on a view
#     that does: refused, by name, with no statement for anything;
#  4. a materialized view that reads the column, or stands on a view that is
#     rebuilt for it: refused, by name, with the DROP that is the way out;
#  5. a column no view reads, and a view that is unchanged and does not read it,
#     are left alone;
#  6. what DROP VIEW takes along that the model holds -- the triggers of a
#     view -- is created again.

sub relation {
  my ($kind, $name, %more) = @_;
  return ("public.$name" => { schema_name => 'public', table_name => $name, kind => $kind, %more });
}
sub table { relation(r => @_) }
sub view {
  my ($name, $kind, $definition, %reads) = @_;
  return relation($kind => $name, view_definition => $definition,
    depends_on => [ sort keys %reads ], depends_on_columns => {%reads});
}
sub col {
  my ($name, $type) = @_;
  return { column_name => $name, data_type => $type, not_null => 0, identity => '', generated => '' };
}
sub model {
  my ($views, %more) = @_;
  my ($type_a) = delete $more{a} // 'integer';
  return {
    tables  => { table('t'), %$views },
    columns => { 'public.t' => [ col(id => 'integer'), col(a => $type_a), col(b => 'integer'), col(c => 'text') ] },
    %more,
  };
}
sub diff_of {
  my ($source, $target) = @_;
  return DBIO::PostgreSQL::Diff->new(source => $source, target => $target);
}
sub statements { [ map { $_->as_sql } @{ diff_of(@_)->operations } ] }

sub refused {
  my ($label, $source, $target, @like) = @_;
  my $ops = eval { diff_of($source, $target)->operations };
  my $error = $@;
  subtest $label => sub {
    is $ops, undef, 'no operation is built';
    like $error, qr/\Arefusing to diff: /, 'the diff is refused';
    like $error, $_, "the refusal matches $_" for @like;
    like $error, qr/No statement was generated\./, 'and says that nothing was generated';
  };
  return $error;
}

# ---------------------------------------------------------------------------
# 1. A declared view that reads the column
# ---------------------------------------------------------------------------
{
  my %views_db  = view(v_a => v => ' SELECT id, a FROM public.t WHERE (b > 0);', 'public.t' => [qw( a b id )]);
  my %views_tgt = view(v_a => v => ' SELECT id, a FROM public.t WHERE (b > 0);', 'public.t' => [qw( a b id )]);
  my ($db, $target) = (model(\%views_db), model(\%views_tgt, a => 'bigint'));

  is_deeply statements($db, $target), [
    'DROP VIEW public.v_a;',
    'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
    'CREATE VIEW public.v_a AS SELECT id, a FROM public.t WHERE (b > 0);',
  ], 'a declared view over a column that changes its type: DROP VIEW, ALTER, CREATE VIEW';

  my @create = grep { $_->action eq 'create' && $_->can('table_info') } @{ diff_of($db, $target)->operations };
  is scalar @create, 1, 'one view is created';
  is Scalar::Util::refaddr($create[0]->table_info), Scalar::Util::refaddr($target->{tables}{'public.v_a'}),
    'and what it is created from is the target model\'s entry, not the database\'s';

  # The target's text is what is written, even where it is not the database's.
  my $other = model({ view(v_a => v => ' SELECT id, a FROM public.t WHERE (b > 0);', 'public.t' => [qw( a b id )]) }, a => 'bigint');
  $other->{tables}{'public.v_a'}{view_definition} = " SELECT id,\n    a\n   FROM public.t\n  WHERE (b > 0);";
  is_deeply statements($db, $other)->[2], "CREATE VIEW public.v_a AS SELECT id,\n    a\n   FROM public.t\n  WHERE (b > 0);",
    'the definition written is the target\'s';

  # A view the target has in the same definition and the column does not
  # touch it.
  my $untouched = model({ view(v_b => v => ' SELECT b FROM public.t;', 'public.t' => ['b']) });
  is_deeply statements($untouched, model({ view(v_b => v => ' SELECT b FROM public.t;', 'public.t' => ['b']) }, a => 'bigint')),
    [ 'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;' ],
    'a view that does not read the column is left alone';
  is_deeply statements(model(\%views_db), model(\%views_tgt, c => 'text')), [],
    'no change, no statement';

  # The column changes and the view's definition changes with it.
  my %both = view(v_a => v => ' SELECT id, a FROM public.t WHERE (b > 1);', 'public.t' => [qw( a b id )]);
  is_deeply statements($db, model(\%both, a => 'bigint')), [
    'DROP VIEW public.v_a;',
    'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
    'CREATE VIEW public.v_a AS SELECT id, a FROM public.t WHERE (b > 1);',
  ], 'a view whose definition changes as well is dropped once and created once';

  # The summary says the same in the same order.
  my @summary = split /\n/, diff_of($db, $target)->summary;
  like $summary[0], qr/-view: public\.v_a/, 'the summary: the view goes first';
  like $summary[-1], qr/\+view: public\.v_a/, 'and comes back last';
}

# ---------------------------------------------------------------------------
# 2. A view on a view: by the dependency, not the names
# ---------------------------------------------------------------------------
{
  my %views = (
    view(z_base => v => ' SELECT id, a FROM public.t;', 'public.t'    => [qw( a id )]),
    view(a_top  => v => ' SELECT a FROM public.z_base;', 'public.z_base' => ['a']),
  );
  is_deeply statements(model(\%views), model(\%views, a => 'bigint')), [
    'DROP VIEW public.a_top;',
    'DROP VIEW public.z_base;',
    'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
    'CREATE VIEW public.z_base AS SELECT id, a FROM public.t;',
    'CREATE VIEW public.a_top AS SELECT a FROM public.z_base;',
  ], 'two stacked views: dropped from the top, created from the bottom';

  # Only the top reads the column in the model of its own: the view below
  # it is not in the way and stays.
  my %top_only = (
    view(z_base => v => ' SELECT id FROM public.t;', 'public.t' => ['id']),
    view(a_top  => v => ' SELECT a FROM public.t;',  'public.t' => ['a']),
  );
  is_deeply statements(model(\%top_only), model(\%top_only, a => 'bigint')), [
    'DROP VIEW public.a_top;',
    'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
    'CREATE VIEW public.a_top AS SELECT a FROM public.t;',
  ], 'a view that does not read the column stays, with the one that does rebuilt';

  # A view on a rebuilt view that is not in the database model's columns: it
  # reads only the whole row of the one below -- dropped all the same,
  # PostgreSQL does not drop the one below while it stands on it.
  my %row_on = (
    view(z_base => v => ' SELECT id, a FROM public.t;', 'public.t' => [qw( a id )]),
    view(a_top  => v => ' SELECT z_base.*::public.z_base FROM public.z_base;', 'public.z_base' => []),
  );
  is_deeply statements(model(\%row_on), model(\%row_on, a => 'bigint')), [
    'DROP VIEW public.a_top;',
    'DROP VIEW public.z_base;',
    'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
    'CREATE VIEW public.z_base AS SELECT id, a FROM public.t;',
    'CREATE VIEW public.a_top AS SELECT z_base.*::public.z_base FROM public.z_base;',
  ], 'a view on a rebuilt view goes with it, however it reads it';
}

# ---------------------------------------------------------------------------
# 3. A view only the database has stays a refusal, by name
# ---------------------------------------------------------------------------
{
  my %db = (
    view(v_a    => v => ' SELECT id, a FROM public.t;', 'public.t'   => [qw( a id )]),
    view(v_only => v => ' SELECT a FROM public.t;',     'public.t'   => ['a']),
    view(v_on_a => v => ' SELECT a FROM public.v_a;',   'public.v_a' => ['a']),
  );
  my %tgt = %db;
  delete $tgt{'public.v_only'};

  my $error = refused 'a view only the database has, that reads the column',
    model(\%db), model(\%tgt, a => 'bigint'),
    qr/\Arefusing to diff: column public\.t\.a changes its type from integer to bigint while view public\.v_only, which only the database has, depends on it$/m,
    qr/^  DROP VIEW public\.v_only;$/m,
    qr/diff again/;
  unlike $error, qr/DROP VIEW public\.v_a;/, '... and the view the declaration has is not among what to drop';
  unlike $error, qr/DROP VIEW public\.v_on_a;/, '... nor the one on it';

  # A dependent only the database has: v_a is declared, v_on_a is not.
  my %tgt2 = %db;
  delete $tgt2{'public.v_on_a'};
  $error = refused 'a view only the database has, that stands on a declared view that is rebuilt',
    model(\%db), model(\%tgt2, a => 'bigint'),
    qr/while view public\.v_on_a, which only the database has, depends on it$/m,
    qr/^  DROP VIEW public\.v_on_a;$/m;
  unlike $error, qr/public\.v_only|DROP VIEW public\.v_a;/, '... and names nothing the declaration holds';

  # The same type change with nobody in the way is no refusal.
  my %all_declared = %db;
  ok eval { diff_of(model(\%all_declared), model(\%all_declared, a => 'bigint'))->operations; 1 },
    'every view declared: no refusal' or diag $@;
}

# ---------------------------------------------------------------------------
# 4. A materialized view is refused, not built anew
# ---------------------------------------------------------------------------
{
  my %views = (
    view(mv_a => m => ' SELECT a FROM public.t;', 'public.t' => ['a']),
  );
  my $idx = sub {
    return { 'public.mv_a' => { mv_a_idx => {
      schema_name => 'public', table_name => 'mv_a', index_name => 'mv_a_idx',
      definition  => 'CREATE INDEX mv_a_idx ON public.mv_a USING btree (a)',
    } } };
  };
  my ($db, $target) = (model(\%views, indexes => $idx->()), model(\%views, a => 'bigint', indexes => $idx->()));

  my $error = refused 'a materialized view the target has, that reads the column',
    $db, $target,
    qr/\Arefusing to diff: column public\.t\.a changes its type from integer to bigint and is read by materialized view public\.mv_a$/m,
    qr/cannot alter type of a column used by a view or rule/,
    qr/^  DROP MATERIALIZED VIEW public\.mv_a;$/m,
    qr/diff again/;
  like $error, qr/data/, '... and says what dropping it takes';

  # On a view that would be rebuilt for the type.
  my %stack = (
    view(v_a  => v => ' SELECT a FROM public.t;',    'public.t' => ['a']),
    view(mv_b => m => ' SELECT a FROM public.v_a;',  'public.v_a' => ['a']),
  );
  $error = refused 'a materialized view on a view that would be rebuilt for the type',
    model(\%stack), model(\%stack, a => 'bigint'),
    qr/\Arefusing to diff: column public\.t\.a changes its type from integer to bigint and is read by materialized view public\.mv_b \(through view public\.v_a\)$/m,
    qr/^  DROP MATERIALIZED VIEW public\.mv_b;$/m;
  unlike $error, qr/^  DROP VIEW public\.v_a;$/m,
    '... and the view the diff rebuilds itself is not among what to drop';

  # With the materialized view gone from the database, the diff goes through:
  # the view is rebuilt and the materialized view created from the target.
  my $without = model({ view(v_a => v => ' SELECT a FROM public.t;', 'public.t' => ['a']) });
  is_deeply statements($without, model(\%stack, a => 'bigint')), [
    'DROP VIEW public.v_a;',
    'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
    'CREATE VIEW public.v_a AS SELECT a FROM public.t;',
    'CREATE MATERIALIZED VIEW public.mv_b AS SELECT a FROM public.v_a;',
  ], 'the way out: once it is dropped, the view is rebuilt and the materialized view created';

  # A materialized view only the database has: refused, by name.
  refused 'a materialized view only the database has, that reads the column',
    model(\%views), model({}, a => 'bigint'),
    qr/while materialized view public\.mv_a, which only the database has, depends on it$/m,
    qr/^  DROP MATERIALIZED VIEW public\.mv_a;$/m;

  # A materialized view on the table that does not read the column is no
  # obstacle.
  my %other = view(mv_c => m => ' SELECT b FROM public.t;', 'public.t' => ['b']);
  is_deeply statements(model(\%other), model(\%other, a => 'bigint')),
    [ 'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;' ],
    'a materialized view that reads another column is left alone';
}

# ---------------------------------------------------------------------------
# 5. What is not the type of a column stays what it was
# ---------------------------------------------------------------------------
{
  my %views = view(v_a => v => ' SELECT id, a FROM public.t;', 'public.t' => [qw( a id )]);
  my $db = model(\%views);
  my $notnull = model(\%views);
  $notnull->{columns}{'public.t'}[1]{not_null} = 1;
  is_deeply statements($db, $notnull), [ 'ALTER TABLE public.t ALTER COLUMN a SET NOT NULL;' ],
    'NOT NULL under a view is altered in place, the view untouched';

  my %row = view(v_row => v => ' SELECT t.*::public.t AS t FROM public.t;', 'public.t' => []);
  is_deeply statements(model(\%row), model(\%row, a => 'bigint')),
    [ 'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;' ],
    'a view that reads the table as a whole row is no obstacle and is not rebuilt';
}

# ---------------------------------------------------------------------------
# 6. What DROP VIEW takes with it
# ---------------------------------------------------------------------------
{
  my %views = view(v_a => v => ' SELECT id, a FROM public.t;', 'public.t' => [qw( a id )]);
  my %trigger = ('public.v_a' => { stays => {
    schema_name => 'public', table_name => 'v_a', trigger_name => 'stays',
    definition  => 'CREATE TRIGGER stays INSTEAD OF INSERT ON public.v_a FOR EACH ROW EXECUTE FUNCTION f()',
  } });
  is_deeply statements(model(\%views, triggers => {%trigger}), model(\%views, a => 'bigint', triggers => {%trigger})), [
    'DROP VIEW public.v_a;',
    'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
    'CREATE VIEW public.v_a AS SELECT id, a FROM public.t;',
    'CREATE TRIGGER stays INSTEAD OF INSERT ON public.v_a FOR EACH ROW EXECUTE FUNCTION f();',
  ], 'the trigger of a rebuilt view is created again, once, and not dropped on its own';
}

done_testing;
