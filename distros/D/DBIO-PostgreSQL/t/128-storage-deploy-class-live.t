use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use File::Temp ();
use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test: $storage->deploy($schema), called on the storage itself, installs
# the schema as $schema->deploy does (karr k104, core ADR 0064).
#
# WHY: not every caller comes through $schema->deploy. DBIO::Replicated hands
# deploy to the storage of its master, and anybody may call $storage->deploy.
# A storage that then goes its own way -- to a DDL file in the deploy
# directory for a schema without the DBIO::PostgreSQL component, to a deploy
# class it names itself for one with it -- puts something else into the
# database than $schema->deploy for the same schema: the tables of a stale
# .sql file.
#
# What this file claims, in a database of its own:
#   1. for a schema with the component and for one without,
#      $storage->deploy($schema) makes the table of the schema, column for
#      column as $schema->deploy makes it;
#   2. a DDL file in the deploy directory -- the one deployment_statements
#      reads from there -- is not executed in its place;
#   3. the storage of a schema without the component is the PostgreSQL
#      storage its shortcut declares (use DBIO 'Schema', -pg; core ADR 0067);
#   4. with a storage layer registered, the storage still names the driver's
#      deploy class (a layer defines none, core ADR 0066 section 4), the
#      install of $storage->deploy runs through it, and $schema->pg_deploy is
#      an object of it;
#   5. a DBIO::Replicated schema, whose $schema->deploy is handed by the
#      replicated storage to the storage of its master, gets its table the
#      same way, with the component and without, and no DDL file is executed;
#      with the component, $schema->pg_deploy is an object of the class the
#      driver storage names -- the replicated storage names none.
#
# NOT CLAIMED: what the install script holds -- t/102-ddl-install-script-live.t
# and its neighbours.
#
# The installs go into a database of this file's own (karr k81).

my $TABLE     = 'k104_widget';
my $FROM_FILE = 'k104_from_file';
my $FILE_DDL  = "CREATE TABLE $FROM_FILE (id integer);\n";

{
  package T128L::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('k104_widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
    note => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  # Does NOT load the PostgreSQL component: the shortcut declares the driver
  # and nothing else (a schema always has one, core ADR 0067).
  package T128L::Plain;
  use DBIO 'Schema', -pg;
}
T128L::Plain->register_class(Widget => 'T128L::Result::Widget');
{
  package T128L::Comp;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
T128L::Comp->register_class(Widget => 'T128L::Result::Widget');

# A storage layer. It names no deploy class: the driver storage is the one
# owner of dbio_deploy_class (core ADR 0066, section 4).
{
  package T128L::Layer;
  sub t128l_marker { 1 }
}
$INC{'T128L/Layer.pm'} = __FILE__;
{
  package T128L::CompLayered;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_storage_layer('T128L::Layer');
}
T128L::CompLayered->register_class(Widget => 'T128L::Result::Widget');

{
  # Does NOT load the PostgreSQL component: the shortcut declares the driver
  # the master and replicants run on.
  package T128L::ReplicatedPlain;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('Replicated');
}
T128L::ReplicatedPlain->register_class(Widget => 'T128L::Result::Widget');
{
  package T128L::ReplicatedComp;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'Replicated');
}
T128L::ReplicatedComp->register_class(Widget => 'T128L::Result::Widget');

my @db      = PrivatePgDatabase->create('t128');
my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
my $dbh     = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });

# The columns of a table as the catalog has them; none for a table that is
# not there.
sub columns {
  my ($table) = @_;
  return $dbh->selectall_arrayref(<<'EOS', undef, "public.$table");
SELECT a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod), a.attnotnull::int, a.attidentity
  FROM pg_catalog.pg_attribute a
 WHERE a.attrelid = pg_catalog.to_regclass(?) AND a.attnum > 0 AND NOT a.attisdropped
 ORDER BY a.attnum
EOS
}

# A deploy directory that holds the DDL file core looks for.
sub ddl_dir {
  my ($schema) = @_;
  my $dir  = File::Temp::tempdir(CLEANUP => 1) . '/';
  my $file = $schema->ddl_filename('PostgreSQL', '1.x', $dir);
  open my $fh, '>', $file or die "cannot write $file: $!";
  print {$fh} $FILE_DDL;
  close $fh;
  return $dir;
}

# ---------------------------------------------------------------------------
# 1.-3. With the component and without it.
# ---------------------------------------------------------------------------

for my $case (
  [ 'T128L::Comp',  'with the component' ],
  [ 'T128L::Plain', 'without the component' ],
) {
  my ($class, $label) = @$case;

  my $schema = $class->connect(@db, @CONNECT);
  my $dir    = ddl_dir($schema);
  note "$label: the storage is a " . ref($schema->storage) . ' before deploy';

  ok eval { $schema->storage->deploy($schema, undef, {}, $dir); 1 },
    "\$storage->deploy, a schema $label: lives"
    or diag $@;
  isa_ok $schema->storage, 'DBIO::PostgreSQL::Storage', '... the storage it ran on';

  my $by_storage = columns($TABLE);
  is_deeply [ map { $_->[0] } @$by_storage ], [qw( id name note )],
    "... and the table of the schema is there, with its columns";
  is_deeply columns($FROM_FILE), [], '... the table of the DDL file is not';
  is scalar eval { $schema->deployment_statements(undef, undef, $dir) }, $FILE_DDL,
    '... though the DDL file is the one deployment_statements reads from that directory'
    or diag $@;

  $dbh->do("DROP TABLE $TABLE");
  is_deeply columns($TABLE), [], 'the table is dropped again';

  my $by_schema_deploy = $class->connect(@db, @CONNECT);
  ok eval { $by_schema_deploy->deploy(undef, $dir); 1 }, "\$schema->deploy, a schema $label: lives"
    or diag $@;
  is_deeply $by_storage, columns($TABLE),
    '... and makes the table column for column as $storage->deploy made it';
  is_deeply columns($FROM_FILE), [], '... the table of the DDL file is not there either';

  $dbh->do("DROP TABLE $TABLE");
  $_->storage->disconnect for $schema, $by_schema_deploy;
}

# ---------------------------------------------------------------------------
# 4. A storage layer does not name a deploy class: the driver owns it.
# ---------------------------------------------------------------------------

{
  my $schema = T128L::CompLayered->connect(@db, @CONNECT);
  my $dir    = ddl_dir($schema);

  ok $schema->storage->can('t128l_marker'), 'the layer is composed over the driver storage';
  is $schema->storage->dbio_deploy_class, 'DBIO::PostgreSQL::Deploy',
    '... and the storage names the deploy class of the driver';
  ok eval { $schema->storage->deploy($schema, undef, {}, $dir); 1 },
    '$storage->deploy under a layer: lives'
    or diag $@;
  is_deeply [ map { $_->[0] } @{ columns($TABLE) } ], [qw( id name note )],
    '... and the table of the schema is there';
  is_deeply columns($FROM_FILE), [], '... the table of the DDL file is not';
  is ref $schema->pg_deploy, 'DBIO::PostgreSQL::Deploy', '$schema->pg_deploy is an object of the driver\'s class';

  $dbh->do("DROP TABLE $TABLE");
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 5. DBIO::Replicated: deploy reaches the storage of the master.
# ---------------------------------------------------------------------------

for my $case (
  [ 'T128L::ReplicatedComp',  'with the component' ],
  [ 'T128L::ReplicatedPlain', 'without the component' ],
) {
  my ($class, $label) = @$case;

  my $schema = $class->connect(@db, @CONNECT);
  my $dir    = ddl_dir($schema);
  isa_ok $schema->storage, 'DBIO::Replicated::Storage', "a replicated schema $label: its storage";

  ok eval { $schema->deploy(undef, $dir); 1 }, '... $schema->deploy lives'
    or diag $@;
  isa_ok $schema->storage->master->storage, 'DBIO::PostgreSQL::Storage', '... the storage of its master';
  is_deeply [ map { $_->[0] } @{ columns($TABLE) } ], [qw( id name note )],
    '... and the table of the schema is there';
  is_deeply columns($FROM_FILE), [], '... the table of the DDL file is not';
  is ref $schema->pg_deploy, 'DBIO::PostgreSQL::Deploy',
    '... $schema->pg_deploy, of a storage that names no deploy class: an object of the class the driver storage names'
    if $schema->can('pg_deploy');

  $dbh->do("DROP TABLE $TABLE");
  $schema->storage->disconnect;
}

$dbh->disconnect;

done_testing;
