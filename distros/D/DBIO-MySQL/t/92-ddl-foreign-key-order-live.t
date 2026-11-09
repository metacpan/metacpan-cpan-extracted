use strict;
use warnings;
use Test::More;

# LIVE half of karr k84: install() of a schema whose child source sorts before
# its parent, and of a cycle, on the real server.
#
# WHY IT MATTERS. install_ddl used to write tables in source-name order; MySQL
# refuses a foreign key to a table it has not seen ("Failed to open the
# referenced table", 1824). What this file claims, on MySQL and on MariaDB:
#   1. a child source sorting before its parent installs, and the foreign key
#      is there;
#   2. a cycle installs, both foreign keys are there, and each refuses a row
#      of no parent;
#   3. after either install the diff of the same schema has nothing to say.
#
# Gated like the other live tests; works in a database of its own (t/86).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use DiffTempDbProbe qw(temp_db_skip_reason);

my $DB = "dbio_k84_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END { if ($raw) { local ($@, $?); eval { drop_database() } } }

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}
if (my $why = temp_db_skip_reason($raw)) { plan skip_all => $why }
note sprintf 'server %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB;

my $n = 0;
sub schema_for {
  my (%src) = @_;
  my $ns = 'K84Live::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $m (sort keys %src) {
    my $class = "${ns}::Result::$m";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($src{$m}{table});
    $class->add_columns(id => { data_type => 'integer', is_auto_increment => 1 },
      map { $_->[0] => { data_type => 'integer', is_nullable => 1 } } @{ $src{$m}{fk} // [] });
    $class->set_primary_key('id');
    for my $fk (@{ $src{$m}{fk} // [] }) {
      $class->belongs_to("rel_$fk->[0]" => "${ns}::Result::$fk->[1]", { 'foreign.id' => "self.$fk->[0]" });
    }
    $ns->register_class($m => $class);
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}
sub fresh { drop_database(); $raw->do("CREATE DATABASE `$DB`"); $raw->do("USE `$DB`") }
sub server_fks {
  return { map { ("$_->[0].$_->[1]" => "$_->[2].$_->[3]") } @{ $raw->selectall_arrayref(
    'SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME '
  . 'FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL',
    undef, $DB) } };
}
sub is_refused {
  my ($sql, @bind) = @_;
  my $ok = eval { $raw->do($sql, undef, @bind); 1 };
  return !$ok && "$@" =~ /foreign key constraint fails/ ? 1 : 0;
}
sub installs {
  my ($schema, $name) = @_;
  ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, $name or diag "install failed: $@";
}
sub nothing_left {
  my ($schema, $name) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $diff && !$diff->has_changes, $name
    or diag $diff ? join("\n", map { $_->as_sql } @{ $diff->operations }) : "the diff failed: $@";
}

subtest 'a child source sorting before its parent' => sub {
  fresh();
  my $schema = schema_for(
    A_Child  => { table => 'child', fk => [[ parent_id => 'Z_Parent' ]] },
    Z_Parent => { table => 'parent' },
  );
  installs $schema, 'install takes the tables, parent first';
  is_deeply server_fks(), { 'child.parent_id' => 'parent.id' }, '... the server has the foreign key';
  ok is_refused('INSERT INTO `child` (`parent_id`) VALUES (999)'), '... and it refuses a child of no parent';
  nothing_left $schema, '... and the diff has nothing left';
  $schema->storage->disconnect;
};

subtest 'a self reference and a child before its parent together' => sub {
  fresh();
  my $schema = schema_for(
    A_Leaf => { table => 'leaf', fk => [[ tree_id => 'B_Tree' ]] },
    B_Tree => { table => 'tree', fk => [[ parent_id => 'B_Tree' ]] },
  );
  installs $schema, 'install takes it';
  is_deeply server_fks(), { 'leaf.tree_id' => 'tree.id', 'tree.parent_id' => 'tree.id' }, '... both foreign keys are there';
  nothing_left $schema, '... and the diff has nothing left';
  $schema->storage->disconnect;
};

subtest 'a cycle' => sub {
  fresh();
  my $schema = schema_for(
    A => { table => 'a', fk => [[ b_id => 'B' ]] },
    B => { table => 'b', fk => [[ a_id => 'A' ]] },
  );
  installs $schema, 'install takes the cycle';
  is_deeply server_fks(), { 'a.b_id' => 'b.id', 'b.a_id' => 'a.id' }, '... both foreign keys are there';
  ok is_refused('INSERT INTO `a` (`b_id`) VALUES (999)'), '... a refuses a row of no b';
  ok is_refused('INSERT INTO `b` (`a_id`) VALUES (999)'), '... b refuses a row of no a';
  nothing_left $schema, '... and the diff has nothing left';
  $schema->storage->disconnect;
};

drop_database();
$raw->disconnect;
undef $raw;

done_testing;
