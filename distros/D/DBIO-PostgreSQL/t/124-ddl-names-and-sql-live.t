use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k120, point 9 (maintainer's decision 2026-10-16): what the
# install script takes as a name and what as SQL, asked of a server.
#
# WHY it exists: t/124-ddl-names-and-sql-refusals.t pins the text of the
# script. Whether the server reads it as meant only the server says:
#
#  * a pg_settings key is a name, quoted by the server's rule: DateStyle is
#    written "DateStyle", and the server has to take that through the DO block
#    (format(... %s ..., '"DateStyle"')) as the parameter DateStyle -- which a
#    NEW session of the database then has;
#  * a dotted key is a dotted name, each part for itself;
#  * an index's using, with and operator class are SQL, written as given:
#    BTree (folded by the server), a storage parameter, an operator class
#    with a sort order -- the index the server builds is the one declared, and
#    the diff of what was installed finds nothing to do.
#
# Everything happens in a database of this file's own (karr k81). ALTER
# DATABASE ... SET is run against that and nothing else.

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my %ATTR = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);

my $superuser;
{
  my $h = LiveServer->control_dbh(attrs => {%ATTR});
  note 'server ' . $h->selectrow_array('SHOW server_version');
  ($superuser) = $h->selectrow_array(
    'SELECT rolsuper FROM pg_catalog.pg_roles WHERE rolname = current_user');
  $h->disconnect;
}

my $n = 0;
sub schema_class {
  my (%o) = @_;
  my $pkg = 'T124L' . ++$n;
  eval "package ${pkg}::Schema; use base q(DBIO::Schema); "
     . "package ${pkg}::Schema::Result::Item; use base q(DBIO::Core); 1"
    or die $@;
  my $schema = "${pkg}::Schema";
  my $result = "${pkg}::Schema::Result::Item";
  $schema->load_components('PostgreSQL');
  $result->load_components('PostgreSQL::Result');
  $result->table('item');
  $result->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'text' },
  );
  $result->set_primary_key('id');
  $result->pg_index(@{ $o{pg_index} }) if $o{pg_index};
  $schema->pg_settings($o{settings}) if $o{settings};
  $schema->register_class(Item => $result);
  return $schema;
}

# Installs $class into a database of its own. Returns the connect info of
# that database, or nothing when the install died.
sub installed {
  my ($label, $class, $tag) = @_;
  my @db = PrivatePgDatabase->create($tag);
  my $schema = $class->connect(@db, @CONNECT);
  my $ok = ok(eval { $schema->pg_deploy->install; 1 }, "$label: install runs through")
    or diag "$@\n" . $schema->pg_install_ddl;
  $schema->storage->disconnect;
  return $ok ? @db : ();
}

sub nothing_left {
  my ($label, $class, @db) = @_;
  my $schema = $class->connect(@db, @CONNECT);
  my $diff = eval { $schema->pg_deploy->diff };
  ok($diff, "$label: the diff of what was installed is built") or diag $@;
  ok($diff && !$diff->has_changes, "$label: and finds nothing to do")
    or diag($diff ? $diff->as_sql : '');
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 1. pg_settings keys are names
# ---------------------------------------------------------------------------
{
  my %settings = (DateStyle => 'ISO, DMY', statement_timeout => '4321s');
  my %own = ('dbio_t124.Greeting' => 'hello');
  my $schema = schema_class(settings => { %settings, ($superuser ? %own : ()) });
  like($schema->pg_install_ddl, qr/'"DateStyle"'/,
    'precondition: the script carries the key as a quoted name');

  SKIP: {
    my @db = installed('settings with a mixed-case key', $schema, 't124set')
      or skip 'the install failed', 4;
    my $dbh = LiveServer->control_dbh(login => \@db, attrs => {%ATTR});
    is($dbh->selectrow_array('SHOW DateStyle'), 'ISO, DMY',
      'a new session has DateStyle, written "DateStyle" in the script');
    is($dbh->selectrow_array('SHOW statement_timeout'), '4321s',
      '... and the key that was a name already');
    SKIP: {
      skip 'setting a parameter of the application\'s own on a database takes a superuser', 1
        unless $superuser;
      is($dbh->selectrow_array(q{SELECT current_setting('dbio_t124.Greeting')}), 'hello',
        '... and a dotted key with a mixed-case part, each part quoted for itself');
    }
    $dbh->disconnect;
    nothing_left('settings with a mixed-case key', $schema, @db);
  }
}

# ---------------------------------------------------------------------------
# 2. index using, with and operator classes are SQL, written as given
# ---------------------------------------------------------------------------
{
  my $schema = schema_class(pg_index => [
    item_name_pattern => {
      using     => 'BTree',
      columns   => ['name'],
      opclasses => { name => 'text_pattern_ops DESC NULLS LAST' },
      with      => { fillfactor => 70 },
    },
  ]);
  like($schema->pg_install_ddl,
    qr/USING BTree \(name text_pattern_ops DESC NULLS LAST\) WITH \(fillfactor = 70\)/,
    'precondition: the script carries using, the operator class and with as given');

  SKIP: {
    my @db = installed('an index with using, with and an operator class as SQL', $schema, 't124idx')
      or skip 'the install failed', 3;
    my $dbh = LiveServer->control_dbh(login => \@db, attrs => {%ATTR});
    is($dbh->selectrow_array(q{SELECT indexdef FROM pg_catalog.pg_indexes WHERE indexname = 'item_name_pattern'}),
      q{CREATE INDEX item_name_pattern ON public.item USING btree (name text_pattern_ops DESC NULLS LAST) WITH (fillfactor='70')},
      'the server builds the index as declared');
    $dbh->disconnect;
    nothing_left('an index with using, with and an operator class as SQL', $schema, @db);
  }
}

done_testing;
