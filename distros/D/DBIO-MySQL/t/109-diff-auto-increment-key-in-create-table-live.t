use strict;
use warnings;
use Test::More;

# LIVE half of karr k107 (t/108 has the offline half and the reasoning):
# DBIO::MySQL::Deploy->upgrade of an EMPTY database to a schema with an
# AUTO_INCREMENT column that is not in the primary key.
#
# The server accepts such a column only as a key of the table at the moment the
# table is created. The upgrade wrote the key as a CREATE UNIQUE INDEX after the
# CREATE TABLE and was refused ("there can be only one auto column and it must
# be defined as a key"). The key is now part of the CREATE TABLE.
#
# What this file claims for a UNIQUE key:
#   * the upgrade of the empty database runs, with one statement for the table;
#   * the table has the columns and the key the schema names, and the column is
#     AUTO_INCREMENT: the server and the schema agree;
#   * it is the state install() gives, key by key;
#   * the next diff has nothing to say (no second, duplicate index).
#
# And, measured: both servers take a plain KEY inside the CREATE TABLE as the
# key of such a column as well. The upgrade of a schema with a plain index
# there cannot be run through Deploy at all: install_ddl writes a mysql_index
# after the CREATE TABLE, so the table the diff builds its target from is
# refused (reported on karr k107, not changed here); the CREATE TABLE the diff
# writes for it is covered offline (t/108).
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/105).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB = "dbio_k107_$$";

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
  plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
}
note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

my $version = 0;
sub schema_version {
  my ($kind) = @_;
  my $ns    = 'K107Live::V' . ++$version;
  my $class = "${ns}::Result::Item";
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
  $class->table('item');
  $class->add_columns(
    id   => { data_type => 'int' },
    seq  => { data_type => 'int', is_auto_increment => 1 },
    note => { data_type => 'int' },
  );
  $class->set_primary_key('id');
  $kind eq 'unique'
    ? $class->add_unique_constraint(k_item => ['seq'])
    : $class->mysql_index(k_item => { columns => ['seq'] });
  $ns->register_class(Item => $class);
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

# The table as the server has it: columns with their attributes and the keys.
sub server_state {
  my $columns = $raw->selectall_arrayref(
    'SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, EXTRA FROM information_schema.COLUMNS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'item' ORDER BY ORDINAL_POSITION", undef, $DB);
  my $keys = $raw->selectall_arrayref(
    'SELECT INDEX_NAME, NON_UNIQUE, SEQ_IN_INDEX, COLUMN_NAME FROM information_schema.STATISTICS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'item' ORDER BY INDEX_NAME, SEQ_IN_INDEX", undef, $DB);
  return { columns => $columns, keys => $keys };
}

for my $kind (qw(unique)) {
  subtest "$kind key over an AUTO_INCREMENT column outside the primary key" => sub {
    # the state install() gives
    drop_database();
    $raw->do("CREATE DATABASE `$DB`");
    my $schema = schema_version($kind);
    unless (ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'install runs') {
      diag "install failed: $@";
      $schema->storage->disconnect;
      return;
    }
    my $installed = server_state();
    $schema->storage->disconnect;

    # the state upgrade gives, from the empty database
    drop_database();
    $raw->do("CREATE DATABASE `$DB`");
    $schema = schema_version($kind);
    my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade };
    unless (ok !$@, 'upgrade of the empty database runs') {
      diag "upgrade failed: $@";
      $schema->storage->disconnect;
      return;
    }
    my @sql = map { $_->as_sql } @{ $diff->operations };
    is scalar(@sql), 1, '... with one statement: the key is in the CREATE TABLE, not after it'
      or diag explain \@sql;
    like $sql[0], qr/CREATE TABLE/, '... which is the CREATE TABLE';

    my $upgraded = server_state();
    is_deeply [ map { $_->[0] } @{ $upgraded->{columns} } ], [qw(id seq note)], '... the server has the columns';
    like $upgraded->{columns}[1][3], qr/auto_increment/i, '... `seq` is AUTO_INCREMENT';
    is_deeply [ grep { $_->[0] eq 'k_item' } @{ $upgraded->{keys} } ],
      [ [ k_item => ($kind eq 'unique' ? 0 : 1), 1, 'seq' ] ], '... and `k_item` is a key over it';
    is_deeply $upgraded, $installed, '... and it is the state install gives';

    $raw->do("INSERT INTO `$DB`.`item` (`id`, `note`) VALUES (?, ?)", undef, $_, $_) for 1 .. 2;
    is_deeply $raw->selectcol_arrayref("SELECT `seq` FROM `$DB`.`item` ORDER BY `id`"), [ 1, 2 ],
      '... and `seq` hands out its values';

    my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
    ok $again && !$again->has_changes, '... and the next diff has nothing left'
      or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
    $schema->storage->disconnect;
  };
}

subtest 'the server takes a plain KEY in the CREATE TABLE as the key of the column' => sub {
  drop_database();
  $raw->do("CREATE DATABASE `$DB`");
  ok eval {
    $raw->do("CREATE TABLE `$DB`.`item` (`id` int NOT NULL, `seq` int NOT NULL AUTO_INCREMENT, "
      . 'PRIMARY KEY (`id`), KEY `k_item` (`seq`) USING BTREE) ENGINE=InnoDB');
    1;
  }, 'CREATE TABLE with AUTO_INCREMENT and a plain KEY' or diag $@;
};

drop_database();
$raw->disconnect;
undef $raw;

done_testing;
