use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Diff::Schema;
use DBIO::PostgreSQL::Diff::Extension;
use DBIO::PostgreSQL::Diff::Type;
use DBIO::PostgreSQL::Diff::Function;
use DBIO::PostgreSQL::Diff::Table;
use DBIO::PostgreSQL::Diff::Column;
use DBIO::PostgreSQL::Diff::View;
use DBIO::PostgreSQL::Diff::Index;
use DBIO::PostgreSQL::Diff::Trigger;
use DBIO::PostgreSQL::Diff::Policy;

# karr k120 (1) -- an operation the diff has no statement for.
#
# WHY it exists: a function and a trigger are written as the text the catalog
# gives for them (pg_get_functiondef, pg_get_triggerdef), an index as
# pg_get_indexdef has it. Where the model had no such text the operation was
# built all the same and as_sql wrote something in its place:
#
#   -- CREATE OR REPLACE FUNCTION public.f() (definition unavailable)
#   -- CREATE TRIGGER trg ON public.t (definition unavailable)
#   CREATE INDEX idx ON public.t (?);
#
# The comment is not a statement that does nothing. Deploy splits the script
# at its semicolons and skips what starts with "--", and a comment has no
# semicolon: it is one piece with the statement behind it, and that goes too.
# A trigger whose definition changed was DROPped and not created again. "(?)"
# is no SQL at all. And with the columns of an index the model does not have
# the index: one that is unique and partial came back as a plain one.
#
# The family line (core ADR 0060 section 3) has two answers, correct or
# refused. What is held here, without a database (t/100-...-live.t holds the
# one way the catalog really hands out a model like that):
#
#  1. the diff refuses to build an operation it has no statement for, naming
#     the object and the reason, when the operations are built;
#  2. it refuses nothing it can write: a drop needs no definition, and a
#     definition the database lacks is no obstacle to writing the target's;
#  3. an operation built by hand dies in as_sql where it has no statement --
#     no definition, an action or a kind its class does not know, an ALTER
#     with nothing to alter -- and never answers with a comment, a
#     placeholder or nothing;
#  4. what the diff does write, Deploy runs: one statement an operation.

my %ON = (schema_name => 'public', table_name => 't');
my %T  = ('public.t' => { %ON, kind => 'r' });

sub refused_ok {
  my ($label, $code, @like) = @_;
  my @ops = eval { $code->() };
  my $error = $@;
  subtest $label => sub {
    is scalar(@ops), 0, 'no operation is built';
    like $error, qr/\Arefusing to diff: /, 'the diff is refused';
    like $error, $_, "the refusal matches $_" for @like;
    like $error, qr/No statement was generated\./, 'and says that nothing was generated';
  };
  return $error;
}

# Never a comment, never a placeholder, never nothing: the three shapes an
# as_sql answered with where it had no statement.
sub no_statement_ok {
  my ($label, $op, @like) = @_;
  my @sql = eval { $op->as_sql };
  my $error = $@;
  subtest $label => sub {
    is_deeply \@sql, [], 'as_sql returns nothing ...'
      or diag "it returned: [@{[ map { $_ // 'undef' } @sql ]}]";
    isnt $error, '', '... because it dies';
    like $error, qr/\Q@{[ ref $op ]}\E/, 'naming the class of the operation';
    like $error, $_, "the message matches $_" for @like;
  };
}

# --- 1. functions -----------------------------------------------------------

{
  my %f = (schema_name => 'public', function_name => 'f', identity_args => '');
  my $def = 'CREATE OR REPLACE FUNCTION public.f() RETURNS integer LANGUAGE sql AS $function$SELECT 1$function$';

  my $error = refused_ok 'a function to create that the target model has no definition for',
    sub { DBIO::PostgreSQL::Diff::Function->diff({}, { 'public.f()' => { %f, definition => undef } }) },
    qr/\Arefusing to diff: function public\.f\(\) is in the target and not in the database/,
    qr/no definition/, qr/pg_get_functiondef/;
  like $error, qr/diff again/, '... and what to do about it';

  refused_ok 'a function both sides have, without a definition in the target',
    sub { DBIO::PostgreSQL::Diff::Function->diff(
      { 'public.f()' => { %f, definition => $def } }, { 'public.f()' => {%f} }) },
    qr/\Arefusing to diff: function public\.f\(\) is in the database and in the target/,
    qr/no definition/;

  # What the diff can write it writes.
  my @ops = DBIO::PostgreSQL::Diff::Function->diff(
    { 'public.f()' => {%f}, 'public.old()' => { %f, function_name => 'old' } },
    { 'public.f()' => { %f, definition => $def } },
  );
  is_deeply [ map { $_->as_sql } @ops ], [ "$def;", 'DROP FUNCTION public.old();' ],
    'a definition the database side lacks is no obstacle: the target has the text, and a drop needs none';

  is_deeply [ DBIO::PostgreSQL::Diff::Function->diff({ 'public.f()' => {%f} }, { 'public.f()' => {%f} }) ], [],
    'a function neither side has a definition for is left alone';

  no_statement_ok "a hand-built $_ of a function without a definition",
    DBIO::PostgreSQL::Diff::Function->new(action => $_, function_key => 'public.f()', function_info => {%f}),
    qr/function public\.f\(\)/, qr/no definition/
    for qw(create replace);
}

# --- 1. triggers ------------------------------------------------------------

{
  my %trg = (%ON, trigger_name => 'trg');
  my $def = 'CREATE TRIGGER trg BEFORE UPDATE ON public.t FOR EACH ROW EXECUTE FUNCTION f()';

  refused_ok 'a trigger to create that the target model has no definition for',
    sub { DBIO::PostgreSQL::Diff::Trigger->diff({}, { 'public.t' => { trg => {%trg} } }) },
    qr/\Arefusing to diff: trigger trg on public\.t is in the target and not in the database/,
    qr/no definition/, qr/pg_get_triggerdef/;

  # This one was a DROP TRIGGER followed by the comment: the trigger was gone.
  refused_ok 'a trigger both sides have, without a definition in the target',
    sub { DBIO::PostgreSQL::Diff::Trigger->diff(
      { 'public.t' => { trg => { %trg, definition => $def } } }, { 'public.t' => { trg => {%trg} } }) },
    qr/\Arefusing to diff: trigger trg on public\.t is in the database and in the target/,
    qr/no definition/;

  # DROP VIEW takes the triggers of a view, so those of a view that is
  # dropped and created again are all created again.
  my $view = sub { { 'public.v' => { schema_name => 'public', table_name => 'v', kind => 'v',
    view_definition => $_[0], depends_on => [] } } };
  my %vtrg = (schema_name => 'public', table_name => 'v', trigger_name => 'trg');
  refused_ok 'a trigger of a view that is created again, without a definition in the target',
    sub { DBIO::PostgreSQL::Diff::Trigger->diff(
      { 'public.v' => { trg => { %vtrg, definition => 'x' } } }, { 'public.v' => { trg => {%vtrg} } },
      $view->('SELECT 1'), $view->('SELECT 2')) },
    qr/\Arefusing to diff: trigger trg on public\.v /, qr/no definition/;

  my @ops = DBIO::PostgreSQL::Diff::Trigger->diff(
    { 'public.t' => { trg => {%trg}, old => { %trg, trigger_name => 'old' } } },
    { 'public.t' => { trg => { %trg, definition => $def } } },
  );
  is_deeply [ map { $_->as_sql } @ops ],
    [ 'DROP TRIGGER trg ON public.t;', "$def;", 'DROP TRIGGER old ON public.t;' ],
    'a definition the database side lacks is no obstacle: the target has the text, and a drop needs none';

  no_statement_ok 'a hand-built create of a trigger without a definition',
    DBIO::PostgreSQL::Diff::Trigger->new(action => 'create', table_key => 'public.t', %trg, trigger_info => {}),
    qr/trigger trg on public\.t/, qr/no definition/;
}

# --- 1. indexes -------------------------------------------------------------

{
  my %idx = (%ON, index_name => 'idx');
  my $def = 'CREATE UNIQUE INDEX idx ON public.t USING btree (m) WHERE (m > 0)';

  # The model as the catalog really hands it out for an index that is gone
  # (t/100-...-live.t): no definition, but its columns and that it is unique.
  # Written from the columns it came back as a plain index.
  my $error = refused_ok 'an index to create that the target model has no definition for, columns or not',
    sub { DBIO::PostgreSQL::Diff::Index->diff({},
      { 'public.t' => { idx => { %idx, is_unique => 1, columns => ['m'], predicate => '(m > 0)' } } }, \%T, \%T) },
    qr/\Arefusing to diff: index idx on public\.t is in the target and not in the database/,
    qr/no definition/, qr/pg_get_indexdef/;
  like $error, qr/unique/, '... and why its columns are not enough to write it from';

  refused_ok 'an index to create with neither a definition nor columns',
    sub { DBIO::PostgreSQL::Diff::Index->diff({}, { 'public.t' => { idx => {%idx} } }, \%T, \%T) },
    qr/\Arefusing to diff: index idx on public\.t /, qr/no definition/;

  # This one was a DROP INDEX followed by the plain index.
  refused_ok 'an index both sides have, without a definition in the target',
    sub { DBIO::PostgreSQL::Diff::Index->diff(
      { 'public.t' => { idx => { %idx, definition => $def, columns => ['m'] } } },
      { 'public.t' => { idx => { %idx, columns => ['m'] } } }, \%T, \%T) },
    qr/\Arefusing to diff: index idx on public\.t is in the database and in the target/,
    qr/no definition/;

  my @ops = DBIO::PostgreSQL::Diff::Index->diff(
    { 'public.t' => { idx => { %idx, columns => ['m'] }, old => { %idx, index_name => 'old', columns => ['n'] } } },
    { 'public.t' => { idx => { %idx, definition => $def, columns => ['m'] } } }, \%T, \%T,
  );
  is_deeply [ map { $_->as_sql } @ops ], [ 'DROP INDEX public.idx;', "$def;", 'DROP INDEX public.old;' ],
    'a definition the database side lacks is no obstacle: the target has the text, and a drop needs none';

  # By hand an index is not written from its columns either: that it is
  # unique, its predicate, its access method, the order and the operator
  # class stand only in the definition (karr k143).
  my $by_hand = sub { DBIO::PostgreSQL::Diff::Index->new(
    action => 'create', table_key => 'public.t', %idx, index_info => { @_ }) };
  no_statement_ok 'a hand-built create with columns and no definition is refused, not the plain index on them',
    $by_hand->(columns => [qw( m n )], is_unique => 1), qr/index idx on public\.t/, qr/no definition/;
  no_statement_ok 'a hand-built create of an index with neither a definition nor columns',
    $by_hand->(), qr/index idx on public\.t/, qr/no definition/;
  no_statement_ok 'a hand-built create of an index whose only column has no name (an expression)',
    $by_hand->(columns => [undef]), qr/index idx on public\.t/, qr/no definition/;
}

# --- 1. views ---------------------------------------------------------------

{
  my %v = (schema_name => 'public', table_name => 'v');
  refused_ok 'a view to create that the target model has no definition for',
    sub { DBIO::PostgreSQL::Diff::View->diff({}, { 'public.v' => { %v, kind => 'v' } }) },
    qr/\Arefusing to diff: view public\.v is in the target and not in the database/,
    qr/no definition/, qr/pg_get_viewdef/;

  no_statement_ok 'a hand-built create of a view without a definition',
    DBIO::PostgreSQL::Diff::View->new(action => 'create', %v, table_info => { %v, kind => 'v' }),
    qr/view public\.v/, qr/no definition/;
  no_statement_ok 'a hand-built view operation on a relation that is no view',
    DBIO::PostgreSQL::Diff::View->new(action => 'drop', %v, table_info => { %v, kind => 'r' }),
    qr/public\.v/, qr/not a view/;
}

# --- 3. no statement, for any other reason ----------------------------------

no_statement_ok 'a hand-built create of a type of a kind the diff does not create',
  DBIO::PostgreSQL::Diff::Type->new(action => 'create', type_key => 'public.d',
    type_info => { schema_name => 'public', type_name => 'd', type_kind => 'domain' }),
  qr/type public\.d/, qr/domain/;

{
  my %col = (column_name => 'c', data_type => 'text', not_null => 0);
  no_statement_ok 'a hand-built alter of a column that changes nothing the diff writes',
    DBIO::PostgreSQL::Diff::Column->new(action => 'alter', table_key => 'public.t', %ON,
      column_name => 'c', old_info => {%col}, new_info => { %col, pg_enum_type => 'public.e' }),
    qr/column public\.t\.c/, qr/nothing/;
}

# An action its class does not know: every as_sql ran off the end of its
# if/elsif and handed back an empty statement.
{
  my %op = (
    Schema    => [ 'schema s',             schema_name => 's' ],
    Extension => [ 'extension e',          extension_name => 'e' ],
    Type      => [ 'type public.y',        type_key => 'public.y', type_info => {} ],
    Function  => [ 'function public.f()',  function_key => 'public.f()', function_info => {} ],
    Table     => [ 'table public.t',       %ON, table_info => {} ],
    Column    => [ 'column public.t.c',    table_key => 'public.t', %ON, column_name => 'c' ],
    View      => [ 'view public.t',        %ON, table_info => { kind => 'v' } ],
    Index     => [ 'index i on public.t',  table_key => 'public.t', %ON, index_name => 'i', index_info => {} ],
    Trigger   => [ 'trigger g on public.t', table_key => 'public.t', %ON, trigger_name => 'g', trigger_info => {} ],
    Policy    => [ 'policy p on public.t', table_key => 'public.t', %ON, policy_name => 'p', policy_info => {} ],
  );
  for my $name (sort keys %op) {
    my ($object, @args) = @{ $op{$name} };
    no_statement_ok "$name: an action the class does not know",
      "DBIO::PostgreSQL::Diff::$name"->new(action => 'rename', @args),
      qr/'rename'/, qr/\Q$object\E/;
  }
}

# --- the whole diff ---------------------------------------------------------

# Deploy->diff builds the operations (DBIO::PostgreSQL::Deploy/diff), so this
# is where a deploy stops: before as_sql, before apply.
{
  my %tables = (tables => {%T}, columns => { 'public.t' => [ { column_name => 'id', data_type => 'integer' } ] });
  my $diff = DBIO::PostgreSQL::Diff->new(
    source => { %tables, triggers => { 'public.t' => { trg => { %ON, definition => 'OLD' } } } },
    target => { %tables, triggers => { 'public.t' => { trg => {%ON} } } },
  );
  throws_ok { $diff->operations } qr/\Arefusing to diff: trigger trg on public\.t /,
    'DBIO::PostgreSQL::Diff dies when it builds its operations';
}

# --- 4. what the diff writes is what Deploy runs ----------------------------

{
  package T100::Dbh;
  sub do { push @{ $_[0]{done} }, $_[1]; 1 }
  package T100::Storage;
  sub dbh { $_[0]{dbh} }
  package T100::Schema;
  sub storage { $_[0]{storage} }
}

{
  my $fn  = 'CREATE OR REPLACE FUNCTION public.f() RETURNS trigger LANGUAGE plpgsql AS $function$BEGIN RETURN NEW; END;$function$';
  my $trg = 'CREATE TRIGGER trg BEFORE UPDATE ON public.t FOR EACH ROW EXECUTE FUNCTION f()';
  my $idx = 'CREATE INDEX idx ON public.t USING btree (id)';
  my %column = (columns => { 'public.t' => [ { column_name => 'id', data_type => 'integer' } ] });

  my $diff = DBIO::PostgreSQL::Diff->new(
    source => {
      schemas => { public => {} }, tables => {%T}, %column,
      functions => { 'public.gone()' => { schema_name => 'public', function_name => 'gone', identity_args => '' } },
      triggers  => { 'public.t' => { trg => { %ON, definition => 'OLD' }, gone => { %ON } } },
      indexes   => { 'public.t' => { gone => { %ON, index_name => 'gone' } } },
    },
    target => {
      schemas => { public => {} }, tables => {%T}, %column,
      functions => { 'public.f()' => { schema_name => 'public', function_name => 'f', identity_args => '', definition => $fn } },
      triggers  => { 'public.t' => { trg => { %ON, definition => $trg } } },
      indexes   => { 'public.t' => { idx => { %ON, index_name => 'idx', definition => $idx } } },
    },
  );

  my @written = map { $_->as_sql } @{ $diff->operations };
  is scalar(@written), 7, 'a function, an index and a trigger to create, the old ones to drop';
  is_deeply [ grep { !defined || !/\S/ || /\A\s*--/ || /\(\?\)/ } @written ], [],
    'no operation answers with nothing, a comment or a placeholder';

  my $dbh = bless { done => [] }, 'T100::Dbh';
  my $deploy = DBIO::PostgreSQL::Deploy->new(
    schema => bless({ storage => bless({ dbh => $dbh }, 'T100::Storage') }, 'T100::Schema'),
  );
  {
    # the notice that a storage without transactional DDL runs unbracketed
    local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /non-transactional DDL/ };
    # the old function, trigger and index are dropped: released
    $deploy->apply($diff, allow_destructive => 1);
  }
  is_deeply $dbh->{done}, [ map { s/;\z//r } @written ],
    'Deploy runs every statement the diff wrote, one an operation';
}

done_testing;
