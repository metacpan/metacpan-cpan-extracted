use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    eval { require DBI; 1 }
      or plan skip_all => 'DBI not installed';
}

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
    unless $dsn;

BEGIN {
  eval { require Moo; 1 }
    or plan skip_all => 'Moo not installed';
}

use DBI;
use lib '../dbio/lib', 'lib';
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Introspect;

# -----------------------------------------------------------------------
# Schema: Cake-style enum, no PgSchema declaration
# -----------------------------------------------------------------------
{
  package LiveEnum::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

{
  package LiveEnum::Schema::Result::Task;
  use DBIO::Moo;
  use DBIO::Cake;

  table 'dbio_test_enum_task';

  col id     => serial;
  col status => enum(qw(pending running completed failed));
  col name   => varchar(100);

  primary_key 'id';

  has display => (is => 'lazy');
  sub _build_display { $_[0]->name . ' [' . $_[0]->status . ']' }
}

LiveEnum::Schema->register_class(Task => 'LiveEnum::Schema::Result::Task');

# -----------------------------------------------------------------------
# Deploy via raw DDL
# -----------------------------------------------------------------------

my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });

# Cleanup from any previous failed run
$dbh->do('DROP TABLE IF EXISTS dbio_test_enum_task CASCADE');
$dbh->do('DROP TYPE IF EXISTS dbio_test_enum_task_status_enum CASCADE');
$dbh->disconnect;

my $ddl = DBIO::PostgreSQL::DDL->install_ddl('LiveEnum::Schema');

# Verify DDL structure before deploying
like($ddl, qr/CREATE TYPE\s+dbio_test_enum_task_status_enum\s+AS ENUM/s,
  'DDL contains CREATE TYPE for enum');
like($ddl, qr/status\s+dbio_test_enum_task_status_enum\s+NOT NULL/s,
  'DDL uses generated enum type name in column');

# Deploy
$dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
for my $stmt (split /;\s*\n/, $ddl) {
  $stmt =~ s/^\s+|\s+$//g;
  next unless $stmt;
  $dbh->do($stmt);
}
$dbh->disconnect;

# -----------------------------------------------------------------------
# CRUD via DBIO with the Moo-Cake result class
# -----------------------------------------------------------------------

my $schema = LiveEnum::Schema->connect($dsn, $user, $pass);
my $rs = $schema->resultset('Task');

subtest 'create with enum value' => sub {
  my $task = $rs->create({ name => 'Build', status => 'pending' });
  ok($task->id, 'auto-increment populated');
  is($task->status, 'pending', 'enum value stored');
  is($task->name, 'Build', 'varchar stored');
};

subtest 'invalid enum value rejected by PostgreSQL' => sub {
  throws_ok {
    $rs->create({ name => 'Bad', status => 'invalid_status' });
  } qr/invalid input value|check constraint|enum/i,
    'PostgreSQL rejects unknown enum value';
};

subtest 'fetch and lazy Moo attr' => sub {
  my $task = $rs->create({ name => 'Deploy', status => 'running' });
  my $fetched = $rs->find($task->id);
  is($fetched->status, 'running', 'enum value survives roundtrip');
  is($fetched->display, 'Deploy [running]', 'lazy Moo attr works on fetched row');
};

subtest 'update enum column' => sub {
  my $task = $rs->create({ name => 'Test', status => 'pending' });
  $task->update({ status => 'completed' });
  my $reloaded = $rs->find($task->id);
  is($reloaded->status, 'completed', 'enum update persisted');
};

subtest 'search by enum value' => sub {
  my @running = $rs->search({ status => 'running' })->all;
  ok(scalar @running >= 1, 'search by enum value works');
  is($running[0]->status, 'running', 'correct enum value returned');
};

# -----------------------------------------------------------------------
# Introspect: verify PostgreSQL sees our enum type correctly
# -----------------------------------------------------------------------

subtest 'introspect enum type from pg_catalog' => sub {
  my $model = DBIO::PostgreSQL::Introspect->new(
    dbh           => $schema->storage->dbh,
    schema_filter => ['public'],
  )->model;

  # Check the type was registered
  my $types = $model->{types};
  my $enum_key = 'public.dbio_test_enum_task_status_enum';
  ok(exists $types->{$enum_key}, "enum type $enum_key found in introspection");

  if ($types->{$enum_key}) {
    is($types->{$enum_key}{type_kind}, 'enum', 'type_kind is enum');
    is_deeply(
      $types->{$enum_key}{values},
      [qw(pending running completed failed)],
      'enum values match in correct order'
    );
  }

  # Check the column references the enum type
  my $tables = $model->{tables};
  my $task_table = $tables->{'public.dbio_test_enum_task'};
  ok($task_table, 'task table found in introspection');

  if ($task_table && $task_table->{columns}) {
    my ($status_col) = grep { $_->{column_name} eq 'status' }
      @{ $task_table->{columns} };
    ok($status_col, 'status column found');
    is($status_col->{type_category}, 'e', 'type_category is e (enum)');
  }
};

# -----------------------------------------------------------------------
# Diff: add an enum value, verify ALTER TYPE ... ADD VALUE is generated
# -----------------------------------------------------------------------

subtest 'diff detects new enum value' => sub {
  # Define a V2 schema with an extra enum value 'cancelled'
  {
    package LiveEnumV2::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL');
  }

  {
    package LiveEnumV2::Schema::Result::Task;
    use DBIO::Moo;
    use DBIO::Cake;

    table 'dbio_test_enum_task';

    col id     => serial;
    col status => enum(qw(pending running completed failed cancelled));
    col name   => varchar(100);

    primary_key 'id';
  }

  LiveEnumV2::Schema->register_class(Task => 'LiveEnumV2::Schema::Result::Task');

  my $schema_v2 = LiveEnumV2::Schema->connect($dsn, $user, $pass);

  my $deploy = DBIO::PostgreSQL::Deploy->new(schema => $schema_v2);

  my $diff = $deploy->diff;
  ok($diff, 'diff object returned');
  ok($diff->has_changes, 'diff detects changes');

  my $diff_sql = $diff->as_sql;
  like($diff_sql, qr/ALTER TYPE.*ADD VALUE\s+'cancelled'/si,
    'diff generates ALTER TYPE ... ADD VALUE for new enum value');

  my $summary = $diff->summary;
  like($summary, qr/cancelled/i,
    'diff summary mentions the new value');

  # Apply the diff
  $deploy->apply($diff);

  # Verify the new value works
  my $task = $schema_v2->resultset('Task')->create({
    name => 'Cancelled Job', status => 'cancelled',
  });
  is($task->status, 'cancelled', 'new enum value usable after diff apply');
};

# -----------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------

$dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1 });
$dbh->do('DROP TABLE IF EXISTS dbio_test_enum_task CASCADE');
$dbh->do('DROP TYPE IF EXISTS dbio_test_enum_task_status_enum CASCADE');
$dbh->disconnect;

# Defensive END: if any earlier die prevents the inline cleanup, still drop
# the artefacts so they do not pollute later tests' Deploy->diff snapshots.
END {
    return unless $dsn;
    my $h = eval { DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0 }) };
    return unless $h;
    eval {
        $h->do('DROP TABLE IF EXISTS dbio_test_enum_task CASCADE');
        $h->do('DROP TYPE IF EXISTS dbio_test_enum_task_status_enum CASCADE');
    };
    $h->disconnect;
}

done_testing;
