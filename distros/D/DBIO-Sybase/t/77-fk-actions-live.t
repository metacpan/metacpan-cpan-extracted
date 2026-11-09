use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Sybase::Deploy;

# karr k91 on a live server: ASE has no referential actions (Msg 156), so a
# schema whose belongs_to declares on_delete => 'CASCADE' is refused by
# Deploy->install, ->diff and ->upgrade with an exception naming the
# relationship, the table and the value -- install before it sends anything
# (the database stays empty), diff and upgrade without leaving a _dbio_tmp_
# database on the server (sysdatabases). A control with NO ACTION diffs and
# upgrades, so the empty database and the missing temp database are not just
# what a broken connection would show either. t/76-ddl-fk-actions.t is the
# offline half.
#
# Runs in a throwaway database it creates and drops itself; needs a login
# allowed to CREATE DATABASE (sa on the docker/k8s ASE image).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

{
  package DBIO::Sybase::Test::K91::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('k91_parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');

  package DBIO::Sybase::Test::K91::Plain::Child;
  use base 'DBIO::Core';
  __PACKAGE__->table('k91_child');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    parent_id => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::Sybase::Test::K91::Plain;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Parent => 'DBIO::Sybase::Test::K91::Parent');
  __PACKAGE__->register_class(Child  => 'DBIO::Sybase::Test::K91::Plain::Child');

  package DBIO::Sybase::Test::K91::NoAction::Child;
  use base 'DBIO::Core';
  __PACKAGE__->table('k91_child');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    parent_id => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'DBIO::Sybase::Test::K91::Parent',
    { 'foreign.id' => 'self.parent_id' }, { on_delete => 'NO ACTION' });

  package DBIO::Sybase::Test::K91::NoAction;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Parent => 'DBIO::Sybase::Test::K91::Parent');
  __PACKAGE__->register_class(Child  => 'DBIO::Sybase::Test::K91::NoAction::Child');

  package DBIO::Sybase::Test::K91::Cascade::Child;
  use base 'DBIO::Core';
  __PACKAGE__->table('k91_child');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    parent_id => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'DBIO::Sybase::Test::K91::Parent',
    { 'foreign.id' => 'self.parent_id' }, { on_delete => 'CASCADE' });

  package DBIO::Sybase::Test::K91::Cascade;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Parent => 'DBIO::Sybase::Test::K91::Parent');
  __PACKAGE__->register_class(Child  => 'DBIO::Sybase::Test::K91::Cascade::Child');
}

my $db = "dbio_k91_fk_$$";
my $db_dsn = $dsn;
$db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
  or $db_dsn .= ($dsn =~ /:$/ ? '' : ';') . "database=$db";

my $admin = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$admin->do('USE master');
$admin->do("CREATE DATABASE $db");

# The temporary databases this process made: _dbio_tmp_<pid>_<time>.
sub tmp_databases {
  my $names = $admin->selectcol_arrayref(
    q{SELECT name FROM master..sysdatabases WHERE charindex('_dbio_tmp_} . $$ . q{_', name) = 1});
  return @$names;
}

sub user_tables {
  my $names = $admin->selectcol_arrayref("SELECT name FROM $db..sysobjects WHERE type = 'U'");
  return sort @$names;
}

my $ok = eval {
  my $cascade = DBIO::Sybase::Test::K91::Cascade->connect($db_dsn, $user, $pass);

  # install: refused before the first statement is sent
  my $deploy = DBIO::Sybase::Deploy->new(schema => $cascade);
  eval { $deploy->install; 1 };
  like "$@", qr/relationship 'parent'.*\bk91_child\b.*ON DELETE CASCADE.*Msg 156/s,
    'install: refused, naming relationship, table and value';
  is_deeply [ user_tables() ], [], '... before anything reached the server: no table';

  # a database to diff against
  my $plain = DBIO::Sybase::Test::K91::Plain->connect($db_dsn, $user, $pass);
  DBIO::Sybase::Deploy->new(schema => $plain)->install;
  $plain->storage->disconnect;

  my $before = join ',', user_tables();
  is $before, 'k91_child,k91_parent', 'the live database has both tables';

  my $d = DBIO::Sybase::Deploy->new(schema => $cascade);
  eval { $d->diff; 1 };
  like "$@", qr/relationship 'parent'.*ON DELETE CASCADE.*Msg 156/s, 'diff: refused';
  is_deeply [ tmp_databases() ], [], '... and no _dbio_tmp_ database is left behind';

  eval { $d->upgrade; 1 };
  like "$@", qr/relationship 'parent'.*ON DELETE CASCADE.*Msg 156/s, 'upgrade: refused';
  is_deeply [ tmp_databases() ], [], '... and no _dbio_tmp_ database is left behind';
  is join(',', user_tables()), $before, '... and the live database is untouched';
  my $fks = $admin->selectrow_array(
    "SELECT count(*) FROM $db..sysreferences");
  is $fks, 0, '... no foreign key was made';
  $cascade->storage->disconnect;

  # control: the same shape with NO ACTION goes through diff and upgrade
  my $na = DBIO::Sybase::Test::K91::NoAction->connect($db_dsn, $user, $pass);
  my $nd = DBIO::Sybase::Deploy->new(schema => $na);
  my $diff = eval { $nd->diff };
  ok $diff, 'control, on_delete NO ACTION: diff works' or diag $@;
  like $diff && $diff->as_sql, qr/ADD CONSTRAINT "?fk_k91_child_parent_id"?\s+FOREIGN KEY/,
    '... and adds the constraint, without an ON clause';
  unlike $diff && $diff->as_sql, qr/\bON\s+(?:DELETE|UPDATE)\b/i, '... of any kind';
  ok eval { $nd->upgrade; 1 }, '... upgrade works' or diag $@;
  is $admin->selectrow_array("SELECT count(*) FROM $db..sysreferences"), 1,
    '... and the foreign key is there';
  is_deeply [ tmp_databases() ], [], '... no _dbio_tmp_ database is left behind';
  $na->storage->disconnect;
  1;
};
my $err = $@;

eval { $admin->do('USE master') };
is AseDatabase::drop($admin, $db), '', "the database of this test, $db, is dropped";

die $err unless $ok;

done_testing;
