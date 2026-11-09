use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use DBIO::Test;
use DBIO::DeploymentHandler::VersionStorage::Standard;
use DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult;

# Codeberg #12 -- the version-storage seam was entirely untested.
# The ResultSet subclass named by VersionResult->resultset_class did not exist
# in the dist, so the first ->resultset('__VERSION') died with "Can't locate
# .../VersionResultSet.pm". These tests cover that class and the surrounding
# versioning path, mock-only (DBIO::Test::Storage), never a real DB.

my $VERSION_SOURCE = 'DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult';
my $VERSION_RS     = 'DBIO::DeploymentHandler::VersionStorage::Standard::VersionResultSet';
my $VERSION_TABLE  = 'dbio_deploymenthandler_versions';

# ---------------------------------------------------------------------------
# 0. Fork-rename: PIN the version table name. The last
#    database-visible dbix_class-named identifier was renamed
#    dbix_class_deploymenthandler_versions -> dbio_deploymenthandler_versions.
#    Assert the literal directly so the name cannot silently drift back.
# ---------------------------------------------------------------------------

subtest 'version table name is pinned to the DBIO fork-rename' => sub {
  is $VERSION_TABLE, 'dbio_deploymenthandler_versions',
    'the pinned literal is the post-fork-rename name (no dbix_class_ prefix)';
  unlike $VERSION_TABLE, qr/dbix_class/,
    'no dbix_class-named identifier survives in the runtime table name';

  is $VERSION_SOURCE->table, $VERSION_TABLE,
    'VersionResult->table resolves to the renamed DBIO table literal';

  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_class(__VERSION => $VERSION_SOURCE);
  is $schema->resultset('__VERSION')->result_source->name, $VERSION_TABLE,
    'the registered __VERSION source names the renamed table';
};

# ---------------------------------------------------------------------------
# 1. Regression for Codeberg #12: registering __VERSION and asking for its
#    resultset must not die. Before the missing class was created, the
#    ->resultset call below dies inside the component_class getter (on the
#    non-existent VersionResultSet). This is the test that bites on the
#    pre-fix tree.
# ---------------------------------------------------------------------------

subtest 'Codeberg #12: resultset(__VERSION) lives and yields the ResultSet subclass' => sub {
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_class(__VERSION => $VERSION_SOURCE);

  my $rs;
  lives_ok { $rs = $schema->resultset('__VERSION') }
    'resultset(__VERSION) does not die (VersionResultSet is loadable)';

  isa_ok $rs, $VERSION_RS, 'the version resultset';
  isa_ok $rs, 'DBIO::ResultSet', 'the version resultset (base class)';

  can_ok $rs, 'version_storage_is_installed';
  can_ok $rs, 'database_version';
};

# ---------------------------------------------------------------------------
# 2. VersionResultSet behaviour, driven directly against mock storage.
# ---------------------------------------------------------------------------

subtest 'VersionResultSet::database_version returns the newest stored version' => sub {
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_class(__VERSION => $VERSION_SOURCE);
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('__VERSION');

  $storage->reset_captured;
  # The newest-version query is the only one that carries ORDER BY.
  $storage->mock(qr/ORDER BY/i, [ [ '3.1' ] ]);

  my $ver = $rs->database_version;
  is $ver, '3.1', 'database_version returns the mocked version scalar';

  my ($q) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  ok $q, 'a select was issued';
  like $q->{sql}, qr/\bversion\b/i,           'query selects version';
  like $q->{sql}, qr/\Q$VERSION_TABLE\E/,     'query targets the version table';
  like $q->{sql}, qr/ORDER BY\s+"?id"?\s+DESC/i, 'query orders by id DESC (newest first)';
  like $q->{sql}, qr/\bLIMIT\b/i,             'query is limited to a single row';
};

subtest 'VersionResultSet::version_storage_is_installed is true when the table is queryable' => sub {
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_class(__VERSION => $VERSION_SOURCE);
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('__VERSION');

  $storage->reset_captured;
  $storage->mock(qr/SELECT\s+COUNT/i, [ [ 5 ] ]);

  is $rs->version_storage_is_installed, 1,
    'version_storage_is_installed is 1 when the count query succeeds';

  my ($q) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  ok $q, 'a count select was issued';
  like $q->{sql}, qr/SELECT\s+COUNT/i,    'the probe is a COUNT query';
  like $q->{sql}, qr/\Q$VERSION_TABLE\E/, 'the probe targets the version table';
};

subtest 'VersionResultSet::version_storage_is_installed is false when the query throws' => sub {
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_class(__VERSION => $VERSION_SOURCE);
  my $rs     = $schema->resultset('__VERSION');

  # Simulate a missing version table: the underlying select throws, exactly as
  # a real DB would for "no such table". The eval-guard in the method must
  # swallow it and report the storage as not installed.
  no warnings 'redefine';
  local *DBIO::Test::Storage::select = sub { die "DBD::Mock: no such table\n" };

  is $rs->version_storage_is_installed, 0,
    'version_storage_is_installed is 0 when the probe query dies';
};

# ---------------------------------------------------------------------------
# 3. VersionStorage::Standard layer -- the object DeploymentHandler drives.
# ---------------------------------------------------------------------------

subtest 'VersionStorage::Standard delegates to the version resultset' => sub {
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_class(__VERSION => $VERSION_SOURCE);
  my $storage = $schema->storage;

  my $vs = DBIO::DeploymentHandler::VersionStorage::Standard->new({ schema => $schema });

  isa_ok $vs->version_rs, $VERSION_RS, 'version_rs';
  is $vs->version_source, '__VERSION', 'version_source default';

  # add_database_version -> INSERT of version/ddl/upgrade_sql
  $storage->reset_captured;
  $vs->add_database_version({
    version     => '2.0',
    ddl         => 'CREATE TABLE foo (id INT)',
    upgrade_sql => 'ALTER TABLE foo ADD bar INT',
  });
  my ($ins) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  ok $ins, 'add_database_version issues an insert';
  like $ins->{sql}, qr/INSERT INTO\s+"?\Q$VERSION_TABLE\E"?/i, 'insert targets the version table';
  my @binds = map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $ins->{bind} || [] };
  is_deeply
    [ sort @binds ],
    [ sort ('2.0', 'CREATE TABLE foo (id INT)', 'ALTER TABLE foo ADD bar INT') ],
    'insert binds version, ddl and upgrade_sql';

  # delete_database_version -> DELETE ... WHERE version = ?
  $storage->reset_captured;
  $vs->delete_database_version({ version => '2.0' });
  my ($del) = grep { $_->{op} eq 'delete' } $storage->captured_queries;
  ok $del, 'delete_database_version issues a delete';
  like $del->{sql}, qr/DELETE FROM\s+"?\Q$VERSION_TABLE\E"?/i, 'delete targets the version table';
  like $del->{sql}, qr/WHERE\s+"?version"?\s*=/i, 'delete is scoped by version';

  # database_version delegates through to the resultset query
  $storage->reset_captured;
  $storage->mock(qr/ORDER BY/i, [ [ '2.0' ] ]);
  is $vs->database_version, '2.0', 'database_version returns the newest version';

  # version_storage_is_installed delegates too
  $storage->reset_captured;
  $storage->mock(qr/SELECT\s+COUNT/i, [ [ 1 ] ]);
  is $vs->version_storage_is_installed, 1, 'version_storage_is_installed true when queryable';

  {
    no warnings 'redefine';
    local *DBIO::Test::Storage::select = sub { die "DBD::Mock: no such table\n" };
    is $vs->version_storage_is_installed, 0, 'version_storage_is_installed false when probe dies';
  }
};

# ---------------------------------------------------------------------------
# 4. Component connection-time version check (the seam that would have caught
#    Codeberg #12 in the field). A dedicated mock-storage subclass models the
#    two axes the check turns on: whether the version table exists, and what
#    version it holds. Never a real DB.
# ---------------------------------------------------------------------------

{
  package VersioningCheckTest::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';

  # Control knobs, localised per test below.
  our $INSTALLED  = 1;   # does the version table exist?
  our $DB_VERSION;       # what version does it hold?

  sub new {
    my $self = shift->next::method(@_);
    # Snapshot the knobs at construction time -- connection() builds the
    # storage fresh, so the state is fixed for this connect.
    $self->{_vtest_installed} = $INSTALLED;
    if ($self->{_vtest_installed}) {
      $self->mock_persistent(qr/SELECT\s+COUNT/i, [ [ 1 ] ]);
      $self->mock_persistent(qr/ORDER BY/i,       [ [ $DB_VERSION ] ]);
    }
    $self;
  }

  # An absent version table makes every read of it fail. During the
  # connection check the only query issued is the version probe, so failing
  # unconditionally here faithfully models "table not installed".
  sub select {
    my $self = shift;
    die "VersioningCheckTest: version storage table not installed\n"
      unless $self->{_vtest_installed};
    return $self->next::method(@_);
  }
}

{
  package VersioningCheckTest::Schema;
  use base 'DBIO::Schema';
  our $VERSION = '2.0';
  __PACKAGE__->load_components('+DBIO::DeploymentHandler::VersionStorage::Standard::Component');
  __PACKAGE__->storage_type('VersioningCheckTest::Storage');
}

subtest 'Component connection-time check: unversioned DB carps' => sub {
  local $VersioningCheckTest::Storage::INSTALLED = 0;
  warning_like { VersioningCheckTest::Schema->connect('mock', '') }
    qr/currently unversioned/i,
    'connecting to an unversioned DB warns to run upgrade';
};

subtest 'Component connection-time check: out-of-sync DB carps' => sub {
  local $VersioningCheckTest::Storage::INSTALLED  = 1;
  local $VersioningCheckTest::Storage::DB_VERSION = '1.0';
  warning_like { VersioningCheckTest::Schema->connect('mock', '') }
    qr/out of sync/i,
    'DB version behind schema version warns about the mismatch';
};

subtest 'Component connection-time check: in-sync DB is quiet' => sub {
  local $VersioningCheckTest::Storage::INSTALLED  = 1;
  local $VersioningCheckTest::Storage::DB_VERSION = '2.0';
  warnings_are { VersioningCheckTest::Schema->connect('mock', '') }
    [],
    'matching versions produce no warning';
};

subtest 'Component connection-time check: ignore_version suppresses the check' => sub {
  local $VersioningCheckTest::Storage::INSTALLED = 0;
  warnings_are { VersioningCheckTest::Schema->connect('mock', '', '', { ignore_version => 1 }) }
    [],
    'ignore_version connect attr silences the version check';
};

subtest 'Component connection-time check: DBIO_NO_VERSION_CHECK suppresses the check' => sub {
  local $VersioningCheckTest::Storage::INSTALLED = 0;
  local $ENV{DBIO_NO_VERSION_CHECK} = 1;
  warnings_are { VersioningCheckTest::Schema->connect('mock', '') }
    [],
    'DBIO_NO_VERSION_CHECK env var silences the version check';
};

done_testing;

# vim: ts=2 sw=2 expandtab
