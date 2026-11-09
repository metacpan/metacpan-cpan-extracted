use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k120 (4): a column changes its type under two stacked
# views of the declaration.
#
# WHY it exists: t/127-diff-view-rebuild.t pins the statements, with models
# built by hand. Only a server says that
#
#   DROP VIEW (top), DROP VIEW (bottom), ALTER COLUMN TYPE, CREATE VIEW
#   (bottom), CREATE VIEW (top)
#
# is a sequence it takes -- PostgreSQL refuses the ALTER while a view reads the
# column (cannot alter type of a column used by a view or rule) -- that it
# takes it in the one transaction Deploy::apply runs a diff in, that the
# views come back as the declaration has them, and that nothing is left to do
# afterwards. And that a view that is only in the database is still refused,
# by name, with the database as it was.
#
# The names of the views are the other way round than their dependency: by
# name a_top comes before the z_base it reads. The database is one of this
# file's own (karr k81); run it with
#
#   eval "$(<cihq-ocp>/umgebungen/dbio/dbio-db env postgresql)"
#   ../dbio/maint/live-preflight && ../dbio/maint/capped-test prove -l t/127-diff-view-rebuild-live.t

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });

sub item_class {
  my ($class, $type) = @_;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('item');
    __PACKAGE__->add_columns(
      id => { data_type => 'integer', is_nullable => 0 },
      a  => { data_type => '$type',   is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key('id');
    1;
  } or die $@;
  return $class;
}

sub view_class {
  my ($class, $name, $definition, @columns) = @_;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('$name');
    1;
  } or die $@;
  $class->add_columns(map { $_ => { data_type => 'integer', is_nullable => 1 } } @columns);
  $class->result_source_instance->view_definition($definition);
  return $class;
}

sub schema_class {
  my ($class, %results) = @_;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->register_class($_ => $results{$_}) for sort keys %results;
  return $class;
}

# deploy_depends_on is what install_ddl orders the views by; the diff takes
# the order from the catalog (pg_depend) of both databases.
my $BASE = view_class('T127::Result::Base', z_base => 'SELECT id, a FROM item', qw( id a ));
my $TOP  = view_class('T127::Result::Top', a_top => 'SELECT id FROM z_base WHERE a > 0', 'id');
$TOP->result_source_instance->deploy_depends_on(['T127::Result::Base']);

schema_class('T127::Narrow', Item => item_class('T127::Result::ItemInt', 'int4'),
  V1Base => $BASE, V2Top => $TOP);
schema_class('T127::Wide', Item => item_class('T127::Result::ItemBig', 'bigint'),
  V1Base => $BASE, V2Top => $TOP);

sub column_type {
  my ($dbh) = @_;
  return ($dbh->selectrow_array(q{
    SELECT pg_catalog.format_type(a.atttypid, a.atttypmod)
    FROM pg_catalog.pg_attribute a
    WHERE a.attrelid = 'public.item'::pg_catalog.regclass AND a.attname = 'a'}))[0];
}
sub relkind {
  my ($dbh, $name) = @_;
  return ($dbh->selectrow_array(q{
    SELECT c.relkind FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = ?}, undef, $name))[0];
}
sub statements {
  my ($diff) = @_;
  return [ map { split /\n/, $_->as_sql } @{ $diff->operations } ];
}

my @db = PrivatePgDatabase->create('t127');

my $narrow = T127::Narrow->connect(@db, @CONNECT);
$narrow->pg_deploy->install;
my $dbh = $narrow->storage->dbh;
$dbh->do('SET client_min_messages = warning');
$dbh->do('INSERT INTO item (id, a) VALUES (1, -5), (2, 5), (3, 50)');

is(column_type($dbh), 'integer', 'precondition: the column is integer');
is_deeply([ map { relkind($dbh, $_) } qw( z_base a_top ) ], [ 'v', 'v' ], 'precondition: two views');

# The server does refuse it, the diff is not guarding against nothing.
{
  $dbh->begin_work;
  my $ok = eval { $dbh->do('ALTER TABLE item ALTER COLUMN a TYPE bigint'); 1 };
  my $error = $@;
  $dbh->rollback;
  ok(!$ok && $error =~ /cannot alter type of a column used by a view or rule/,
    'precondition: PostgreSQL refuses the type change under a view') or diag($ok ? 'it ran' : $error);
}

my $wide = T127::Wide->connect(@db, @CONNECT);
my $deploy = $wide->pg_deploy;

# A view only the database has: refused, by name, nothing changed.
{
  $dbh->do('CREATE VIEW public.only_here AS SELECT a FROM item');
  my $error;
  my $diff = eval { $deploy->diff } or $error = $@;
  my $ops = $diff && eval { $diff->operations };
  $error //= $@;
  ok(!$ops, 'the diff is refused while a view only the database has reads the column');
  like($error, qr/\Arefusing to diff: column public\.item\.a changes its type from integer to bigint while view public\.only_here, which only the database has, depends on it$/m,
    'and names the view');
  like($error, qr/^  DROP VIEW public\.only_here;$/m, 'with the statement that is the way out');
  is(column_type($dbh), 'integer', 'the column is as it was');
  $dbh->do('DROP VIEW public.only_here');
}

# The views of the declaration are dropped and created again, and all of it
# is one transaction: the same statements with a failing one behind them leave
# the database as it was.
my $diff = $deploy->diff;
ok($diff->has_changes, 'the diff finds the type change');
my $statements = statements($diff);
note join "\n", @$statements;
is_deeply([ grep { /^(?:DROP|ALTER|CREATE)/ } @$statements ], [
  'DROP VIEW public.a_top;',
  'DROP VIEW public.z_base;',
  'ALTER TABLE public.item ALTER COLUMN a TYPE bigint;',
  grep { /^CREATE VIEW/ } @$statements,
], 'DROP VIEW from the top, ALTER, then the views created again') or diag $diff->as_sql;
my @create = grep { /^CREATE VIEW/ } @$statements;
like($create[0], qr/\ACREATE VIEW public\.z_base /, 'the view below is created first');
like($create[1], qr/\ACREATE VIEW public\.a_top /,  'and the one on it after it');

{
  my $ran = eval {
    $deploy->_execute_ddl($deploy->_dbh, $diff->as_sql . "\nSELECT 1/0;");
    1;
  };
  ok(!$ran, 'a statement behind the rebuild fails ...');
  is(column_type($dbh), 'integer', '... and the column is still integer');
  is_deeply([ map { relkind($dbh, $_) } qw( z_base a_top ) ], [ 'v', 'v' ],
    '... and both views are still there: one transaction');
  is_deeply($dbh->selectcol_arrayref('SELECT id FROM a_top ORDER BY id'), [ 2, 3 ],
    '... and read as before');
}

ok(eval { $deploy->apply($diff); 1 }, 'apply runs through') or diag "$@\n" . $diff->as_sql;
is(column_type($dbh), 'bigint', 'the column has the type of the declaration');
is_deeply([ map { relkind($dbh, $_) } qw( z_base a_top ) ], [ 'v', 'v' ], 'both views are views again');
is_deeply($dbh->selectcol_arrayref('SELECT id FROM a_top ORDER BY id'), [ 2, 3 ],
  'the view on the view reads the table, as its definition says');
is($dbh->selectrow_array('SELECT count(*) FROM item'), 3, 'the rows are there');

my $again = $deploy->diff;
ok(!$again->has_changes, 'a second diff finds nothing left to do') or diag $again->as_sql;

$_->storage->disconnect for $wide, $narrow;

done_testing;
