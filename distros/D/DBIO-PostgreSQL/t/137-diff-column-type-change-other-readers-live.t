use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k121, U6 (points 5 and 8): a column changes its type
# while a policy, a trigger (WHEN, UPDATE OF), a generated column or a view
# outside the declared schemas reads it.
#
# WHY it exists: t/137-diff-column-type-change-other-readers.t pins the
# refusal on a model written by hand; only a server says that the catalog
# gives the model these dependencies and that the way out the message names
# works. Before the fix the diff wrote ALTER COLUMN ... TYPE and the server
# refused it in mid-apply ("cannot alter type of a column used in a policy
# definition" and its siblings).
#
# For every case, in a private database (karr k81): the old objects are made
# by hand, then
#
#  1. the introspected model names the column the object reads;
#  2. the diff is refused, naming the column and the object, and the
#     database is untouched;
#  3. the statements the message gives run, and the upgrade then does;
#  4. the column has the target's type and a second diff finds nothing to do.

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my $n = 0;

sub target {
  my $result = 'T137L::Result::R' . ++$n;
  eval qq{
    package $result;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    1;
  } or die $@;
  $result->table('t');
  $result->add_columns(
    id => { data_type => 'bigint', is_nullable => 0 },
    v  => { data_type => 'bigint', is_nullable => 1 },
    w  => { data_type => 'integer', is_nullable => 1 },
  );
  $result->set_primary_key('id');

  my $class = 'T137L::Schema::S' . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->pg_schemas('public');
  $class->register_class(T => $result);
  return $class;
}

my $TRIGGER_FUNCTION = q{CREATE FUNCTION f() RETURNS trigger LANGUAGE plpgsql
  AS $$ BEGIN RETURN NEW; END $$};

my @CASES = (
  { tag => 'pol', label => 'policy',
    setup => [ 'ALTER TABLE t ENABLE ROW LEVEL SECURITY', 'CREATE POLICY p ON t USING (v > 0)' ],
    section => 'policies', object => 'p',
    named => qr/while policy p on public\.t depends on it/,
    way_out => qr/^  DROP POLICY p ON public\.t;$/m },
  { tag => 'twh', label => 'trigger WHEN',
    setup => [ $TRIGGER_FUNCTION,
      'CREATE TRIGGER tw BEFORE UPDATE ON t FOR EACH ROW WHEN (OLD.v IS DISTINCT FROM NEW.v) EXECUTE FUNCTION f()' ],
    section => 'triggers', object => 'tw',
    named => qr/while trigger tw on public\.t depends on it/,
    way_out => qr/^  DROP TRIGGER tw ON public\.t;$/m },
  { tag => 'tof', label => 'trigger UPDATE OF',
    setup => [ $TRIGGER_FUNCTION,
      'CREATE TRIGGER tu BEFORE UPDATE OF v ON t FOR EACH ROW EXECUTE FUNCTION f()' ],
    section => 'triggers', object => 'tu',
    named => qr/while trigger tu on public\.t depends on it/,
    way_out => qr/^  DROP TRIGGER tu ON public\.t;$/m },
  { tag => 'gen', label => 'generated column',
    setup => [ 'ALTER TABLE t ADD COLUMN g integer GENERATED ALWAYS AS (v * 2) STORED' ],
    named => qr/while generated column public\.t\.g depends on it/,
    way_out => qr/^  ALTER TABLE public\.t DROP COLUMN g;$/m },
  { tag => 'out', label => 'view outside the declared schemas',
    setup => [ 'CREATE SCHEMA other', 'CREATE VIEW other.vw AS SELECT v FROM public.t' ],
    named => qr/while view other\.vw \(outside the declared schemas\) depends on it/,
    way_out => qr/^  DROP VIEW other\.vw;$/m },
);

for my $case (@CASES) {
  my $label = $case->{label};
  my @db = PrivatePgDatabase->create("t137$case->{tag}");
  my $dbh = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });
  $dbh->do($_) for 'CREATE TABLE t (id bigint PRIMARY KEY, v integer, w integer)',
    @{ $case->{setup} };
  $dbh->do('INSERT INTO t (id, v, w) VALUES (1, 5, 6), (2, 7, 8)');

  # 1. the model
  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh, schema_filter => ['public'])->model;
  if ($case->{section}) {
    is_deeply $model->{ $case->{section} }{'public.t'}{ $case->{object} }{depends_on_columns},
      { 'public.t' => ['v'] }, "$label: the model names the column the object reads";
  } elsif ($case->{tag} eq 'gen') {
    my ($g) = grep { $_->{column_name} eq 'g' } @{ $model->{columns}{'public.t'} };
    is_deeply $g->{depends_on_columns}, ['v'], "$label: the model names the column it reads";
    my ($v) = grep { $_->{column_name} eq 'v' } @{ $model->{columns}{'public.t'} };
    is_deeply $v->{depends_on_columns}, [], "$label: and an ordinary column reads none";
  } else {
    is_deeply $model->{outside_readers}{'other.vw'}{depends_on_columns},
      { 'public.t' => ['v'] }, "$label: the model names the column the view reads";
    ok !exists $model->{tables}{'other.vw'}, "$label: and the view itself is not in the model";
  }
  $dbh->disconnect;

  # 2. the refusal
  my $schema = target()->connect(@db, @CONNECT);
  my $diff = eval { $schema->pg_deploy->diff };
  my $error = $@;
  is $diff, undef, "$label: the diff is refused";
  like $error, qr/\Arefusing to diff: column public\.t\.v changes its type from integer to bigint/,
    "$label: and names the column and both types";
  like $error, $case->{named}, "$label: and the object";
  like $error, $case->{way_out}, "$label: and the statement that takes it out of the way";
  unlike $error, qr/DBD::Pg|ERROR:/, "$label: and it is not the server's message";

  # 3. the way out runs, and the upgrade after it
  my @drop = $error =~ /^  ((?:DROP|ALTER) [^\n]+;)$/mg;
  ok @drop, "$label: the message has the statements";
  my $storage_dbh = $schema->storage->dbh;
  is scalar $storage_dbh->selectrow_array(q{SELECT format_type(atttypid, atttypmod)
      FROM pg_attribute WHERE attrelid = 't'::regclass AND attname = 'v'}),
    'integer', "$label: the column is as it was";
  ok eval { $storage_dbh->do($_) for @drop; 1 }, "$label: the statements run" or diag $@;

  my $again = eval { $schema->pg_deploy->diff };
  ok $again, "$label: the diff is built after it" or diag $@;
  SKIP: {
    skip "$label: no diff", 3 unless $again;
    ok eval { $schema->pg_deploy->apply($again, allow_destructive => 1); 1 }, "$label: the upgrade runs" or diag $@;
    is scalar $storage_dbh->selectrow_array(q{SELECT format_type(atttypid, atttypmod)
        FROM pg_attribute WHERE attrelid = 't'::regclass AND attname = 'v'}),
      'bigint', "$label: the column has the target's type";
    is_deeply $storage_dbh->selectcol_arrayref('SELECT v FROM t ORDER BY id'), [ 5, 7 ],
      "$label: and the rows hold what they held";
  }
  my $settled = eval { $schema->pg_deploy->diff };
  ok $settled && !$settled->has_changes, "$label: a second diff finds nothing to do"
    or diag $settled ? $settled->as_sql : $@;
  $schema->storage->disconnect;
}

done_testing;
