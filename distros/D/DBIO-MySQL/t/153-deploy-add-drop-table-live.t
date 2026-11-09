use strict;
use warnings;
use Test::More;

# LIVE half of karr k114: DBIO::MySQL::Deploy with add_drop_table => 1 installs
# a schema over a database that already holds it -- tables with rows, a foreign
# key between them, a view over a table and a view over that view -- and the
# result is the schema as new.
#
# WHY IT MATTERS. t/152 pins the statements. Whether the server takes the
# DROP VIEW before the DROP TABLE, whether a table that a foreign key points at
# can go with its child still standing (the checks are off for the drops), and
# whether the install DDL then runs through again (CREATE VIEW has no OR
# REPLACE), only a server says. A deploy that did not drop the views died on
# the first CREATE VIEW of the second run; one that dropped the tables only left
# the views reading nothing. The claim: the second deploy runs, the rows are
# gone, the views read the new tables, and the connection's foreign key checks
# are on again.
#
# Works in a database of its own (mysql_k114_<pid>), created and dropped here.
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS;
# runs through whichever DBD the DSN names.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my ($dbd, $rest) = $dsn =~ /\Adbi:(\w+):(.*)\z/;
plan skip_all => 'DBIO_TEST_MYSQL_DSN names neither dbi:mysql: nor dbi:MariaDB:'
  unless defined $dbd && $dbd =~ /\A(?:mysql|MariaDB)\z/;

my $DB = "mysql_k114_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_database() };
  }
}
unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}
note sprintf 'server %s, DBD::%s, database %s',
  scalar $raw->selectrow_array('SELECT VERSION()'), $dbd, $DB;

(my $rest2 = $rest) =~ s/(?:^|;)\s*(?:database|dbname)=[^;]*//g;
$rest2 =~ s/\A;//;
my $db_dsn = "dbi:$dbd:database=$DB" . (length $rest2 ? ";$rest2" : '');

{
  package DropDeploy::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DropDeploy::Schema::Result::Parent;
  use DBIO;
  __PACKAGE__->table('order');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 20 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(children => 'DropDeploy::Schema::Result::Child', 'parent_id');
}
{
  package DropDeploy::Schema::Result::Child;
  use DBIO;
  __PACKAGE__->table('child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'DropDeploy::Schema::Result::Parent', 'parent_id');
}
# a_top reads z_base reads child: the name order is the wrong way round
{
  package DropDeploy::Schema::Result::ATop;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('a_top');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM z_base');
}
{
  package DropDeploy::Schema::Result::ZBase;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('z_base');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM `child`');
}
DropDeploy::Schema->register_class($_ => "DropDeploy::Schema::Result::$_")
  for qw(Parent Child ATop ZBase);

my $schema = DropDeploy::Schema->connect($db_dsn, $user, $pass);
my $dbh = sub { $schema->storage->dbh };
my @warn;
local $SIG{__WARN__} = sub { push @warn, @_ };

ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the first install runs' or diag $@;
$raw->do("INSERT INTO `$DB`.`order` (name) VALUES ('old')");
$raw->do("INSERT INTO `$DB`.`child` (parent_id) VALUES (1)");
is scalar($raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`a_top`")), 1, 'the views read the row';

ok !eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 },
  'a second install without add_drop_table still fails, as ever';

ok eval { DBIO::MySQL::Deploy->new(schema => $schema, add_drop_table => 1)->install; 1 },
  'a second install with add_drop_table runs through over the populated database' or diag $@;

for my $t (qw(order child a_top z_base)) {
  my ($n) = $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`$t`");
  is $n, 0, "`$t` is new: the old row is gone";
}
my %kind = map { @$_ } @{ $raw->selectall_arrayref(
  'SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = ?', undef, $DB) };
is_deeply \%kind,
  { order => 'BASE TABLE', child => 'BASE TABLE', a_top => 'VIEW', z_base => 'VIEW' },
  'the database holds the schema and nothing else';
my ($fk) = $dbh->()->selectrow_array('SELECT @@FOREIGN_KEY_CHECKS');
is $fk, 1, 'the foreign key checks of the connection are on again';

# a failing drop leaves the checks on as well
{
  local $SIG{__WARN__} = sub { };
  my $d = DBIO::MySQL::Deploy->new(schema => $schema, add_drop_table => 1);
  no warnings 'redefine';
  local *DBIO::MySQL::Deploy::_ddl_class = sub { 'DropDeploy::Broken' };
  { package DropDeploy::Broken; sub drop_ddl { 'DROP TABLE nonexistent_table_k114_x.y z;' } sub install_ddl { '' } }
  ok !eval { $d->install; 1 }, 'a drop the server refuses fails the install';
  my ($fk2) = $dbh->()->selectrow_array('SELECT @@FOREIGN_KEY_CHECKS');
  is $fk2, 1, 'and the foreign key checks are on again';
}

$schema->storage->disconnect;
done_testing;
