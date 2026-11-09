use strict;
use warnings;
use Test::More;

# LIVE half of karr k112 (t/137 has the offline half and the reasoning):
# DBIO::MySQL::Deploy->install of a schema with an AUTO_INCREMENT column that is
# not in the primary key, whose key is a mysql_index (a unique constraint was
# never affected, t/109).
#
# install_ddl wrote that index as a CREATE INDEX after the CREATE TABLE and the
# server refused the CREATE TABLE (1075). What this file claims, for a UNIQUE
# and for a plain index:
#   * install runs, and the table has the key over the AUTO_INCREMENT column;
#   * the column hands out its values;
#   * the next diff has nothing to say (the key is named and typed as the model
#     says);
#   * an upgrade of the empty database builds the same table.
#
# Needs DBIO_TEST_MYSQL_DSN, _USER and _PASS; works in a database of its own,
# created and dropped here (see t/105).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB  = "dbio_k112_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END { if ($raw) { local ($@, $?); eval { drop_database() } } }

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
}
note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

my $version = 0;
sub schema_version {
  my ($kind) = @_;
  my $ns    = 'K112Live::V' . ++$version;
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
  $class->mysql_index(k_item => { columns => ['seq'], ($kind eq 'unique' ? (unique => 1) : ()) });
  $class->mysql_index(i_note => { columns => ['note'] });
  $ns->register_class(Item => $class);
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

sub server_state {
  my $columns = $raw->selectall_arrayref(
    'SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, EXTRA FROM information_schema.COLUMNS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'item' ORDER BY ORDINAL_POSITION", undef, $DB);
  my $keys = $raw->selectall_arrayref(
    'SELECT INDEX_NAME, NON_UNIQUE, SEQ_IN_INDEX, COLUMN_NAME FROM information_schema.STATISTICS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'item' ORDER BY INDEX_NAME, SEQ_IN_INDEX", undef, $DB);
  return { columns => $columns, keys => $keys };
}

for my $kind (qw(unique plain)) {
  subtest "$kind mysql_index over an AUTO_INCREMENT column outside the primary key" => sub {
    drop_database();
    $raw->do("CREATE DATABASE `$DB`");
    my $schema = schema_version($kind);
    unless (ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'install runs') {
      diag "install failed: $@";
      $schema->storage->disconnect;
      return;
    }
    my $installed = server_state();
    like $installed->{columns}[1][3], qr/auto_increment/i, '... `seq` is AUTO_INCREMENT';
    is_deeply [ grep { $_->[0] eq 'k_item' } @{ $installed->{keys} } ],
      [ [ k_item => ($kind eq 'unique' ? 0 : 1), 1, 'seq' ] ], '... and `k_item` is a key over it';
    is scalar(grep { $_->[0] eq 'i_note' } @{ $installed->{keys} }), 1, '... the other index exists';

    $raw->do("INSERT INTO `$DB`.`item` (`id`, `note`) VALUES (?, ?)", undef, $_, $_) for 1 .. 2;
    is_deeply $raw->selectcol_arrayref("SELECT `seq` FROM `$DB`.`item` ORDER BY `id`"), [ 1, 2 ],
      '... and `seq` hands out its values';

    my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
    ok $again && !$again->has_changes, '... and the next diff has nothing left'
      or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
    $schema->storage->disconnect;

    drop_database();
    $raw->do("CREATE DATABASE `$DB`");
    $schema = schema_version($kind);
    ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade; 1 }, 'upgrade of the empty database runs'
      or diag $@;
    is_deeply server_state(), $installed, '... and builds the table install builds';
    $schema->storage->disconnect;
  };
}

drop_database();
$raw->disconnect;
undef $raw;

done_testing;
