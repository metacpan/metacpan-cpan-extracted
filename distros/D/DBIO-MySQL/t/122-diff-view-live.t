use strict;
use warnings;
use Test::More;

# LIVE half of karr k79 (t/121 has the offline half and the reasoning): the
# views of a schema are created, replaced and dropped as views, and the next
# diff has nothing left.
#
# WHY IT NEEDS A SERVER. The server does not keep a view as written: the
# definition in information_schema.views is rewritten (backticks, AS for every
# column, parentheses, its own spelling) and the name of the DATABASE is put in
# front of every table. The target of an upgrade is a temporary database, so
# the same view reads differently there and in the live one unless the
# introspection takes its own database name out. This file is the measurement
# that the comparison holds on this server, MySQL and MariaDB alike.
#
# What the file claims, in a database of its own:
#   1. install makes the views, and the diff right after has nothing to say;
#   2. an upgrade that changes a view, adds one over a new table, and adds a
#      column to the table the changed view reads: the changed view is dropped
#      first and created again last, the new view comes after the new table,
#      no TABLE statement is written for any view, and the views answer with
#      what their new definition selects;
#   3. the diff after it is empty, and a second upgrade does nothing;
#   4. an upgrade to a schema without views drops them with DROP VIEW (the
#      server refuses DROP TABLE on a view) and leaves the tables and their
#      rows alone.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB = "mysql_k79_$$";

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
# %sources: Moniker => { table, columns => [...], pk, view => 'SELECT ...' }
sub schema_version {
  my (%sources) = @_;
  my $ns = 'K79Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $moniker (sort keys %sources) {
    my $def   = $sources{$moniker};
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table_class('DBIO::ResultSource::View') if $def->{view};
    $class->table($def->{table});
    $class->result_source_instance->view_definition($def->{view}) if $def->{view};
    $class->add_columns(@{ $def->{columns} });
    $class->set_primary_key($def->{pk}) if $def->{pk};
    $ns->register_class($moniker => $class);
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

my @ITEM = (
  id   => { data_type => 'int', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 20 },
  n    => { data_type => 'int' },
);
my @ITEM_V2 = (@ITEM, extra => { data_type => 'int', is_nullable => 1 });
my @EXTRA = (id => { data_type => 'int' });

sub item  { my ($cols) = @_; return (Item => { table => 'item', columns => $cols // \@ITEM, pk => 'id' }) }
sub big   { my ($def) = @_; return (VBig => { table => 'v_big', columns => [ id => { data_type => 'int' }, name => { data_type => 'varchar', size => 20 } ], view => $def }) }

sub views_in_db {
  return $raw->selectcol_arrayref(
    'SELECT table_name FROM information_schema.tables WHERE table_schema = ? AND table_type = ? ORDER BY table_name',
    undef, $DB, 'VIEW');
}
sub tables_in_db {
  return $raw->selectcol_arrayref(
    'SELECT table_name FROM information_schema.tables WHERE table_schema = ? AND table_type = ? ORDER BY table_name',
    undef, $DB, 'BASE TABLE');
}
sub sql_of { return [ map { $_->as_sql } @{ $_[0]->operations } ] }

# 1. install
my $s1 = schema_version(item(), big('SELECT id, name FROM item WHERE n > 1'));
ok eval { DBIO::MySQL::Deploy->new(schema => $s1)->install; 1 }, 'version 1 installs' or diag $@;
is_deeply views_in_db(), ['v_big'], '... the view is a view' ;
is_deeply tables_in_db(), ['item'], '... and the only table is the table';

$raw->do("INSERT INTO `$DB`.`item` (`name`, `n`) VALUES ('a', 1), ('b', 2), ('c', 3)");

my $again = eval { DBIO::MySQL::Deploy->new(schema => $s1)->diff };
ok $again && !$again->has_changes, 'the diff right after install has nothing to say'
  or diag $again ? explain sql_of($again) : "the diff failed: $@";

# 2. change one view, add one over a new table, add a column
my $s2 = schema_version(
  item(\@ITEM_V2),
  big('SELECT id, name, n FROM item WHERE n > 1'),
  (Extra => { table => 'extra', columns => \@EXTRA, pk => 'id' }),
  (VExtra => { table => 'v_extra', columns => [ id => { data_type => 'int' } ], view => 'SELECT id FROM extra' }),
);
my $diff = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
ok $diff && !$@, 'the upgrade runs' or diag "upgrade failed: $@";
my $sql = $diff ? sql_of($diff) : [];
note "  $_" for @$sql;

is $sql->[0], 'DROP VIEW `v_big`;', 'the changed view is dropped first';
my ($create_extra) = grep { $sql->[$_] =~ /\ACREATE TABLE `extra`/ } 0 .. $#$sql;
my ($create_vextra) = grep { $sql->[$_] =~ /\ACREATE VIEW `v_extra`/ } 0 .. $#$sql;
my ($create_vbig)   = grep { $sql->[$_] =~ /\ACREATE VIEW `v_big`/ } 0 .. $#$sql;
my ($add_column)    = grep { $sql->[$_] =~ /\AALTER TABLE `item` ADD COLUMN `extra`/ } 0 .. $#$sql;
ok defined $create_extra && defined $create_vextra && $create_extra < $create_vextra,
  'the new view is created after the new table' or diag explain $sql;
ok defined $add_column && defined $create_vbig && $add_column < $create_vbig,
  'the changed view is created after the column change' or diag explain $sql;
is scalar(grep { /CREATE TABLE `v_|DROP TABLE|ALTER TABLE `v_/ } @$sql), 0,
  'no TABLE statement is written for a view' or diag explain $sql;
is_deeply views_in_db(), [ 'v_big', 'v_extra' ], 'both views exist as views';
is_deeply tables_in_db(), [ 'extra', 'item' ], '... and the tables as tables';
is_deeply $raw->selectall_arrayref("SELECT id, name, n FROM `$DB`.`v_big` ORDER BY id"),
  [ [ 2, 'b', 2 ], [ 3, 'c', 3 ] ], 'the changed view answers with its new definition';
is $diff->classify->{class}, 'changing', 'the upgrade counts as changing, the replaced view is not a removal'
  or diag explain $diff->classify;

my $after = eval { DBIO::MySQL::Deploy->new(schema => $s2)->diff };
ok $after && !$after->has_changes, 'the next diff has nothing left'
  or diag $after ? explain sql_of($after) : "the diff failed: $@";
my $second = eval { DBIO::MySQL::Deploy->new(schema => $s2)->upgrade };
ok !$@ && (!$second || !$second->has_changes), 'a second upgrade has nothing to do' or diag $@;

# 3. views gone
my $s3 = schema_version(item(\@ITEM_V2), (Extra => { table => 'extra', columns => \@EXTRA, pk => 'id' }));
my $gone = eval { DBIO::MySQL::Deploy->new(schema => $s3)->upgrade(allow_destructive => 1) };
ok $gone && !$@, 'the upgrade to a schema without views runs' or diag "upgrade failed: $@";
my $gone_sql = $gone ? sql_of($gone) : [];
note "  $_" for @$gone_sql;
is_deeply $gone_sql, [ 'DROP VIEW `v_extra`;', 'DROP VIEW `v_big`;' ],   # views free of each other: the reverse of the creation order (karr k110)
  'the views are dropped with DROP VIEW and nothing else happens';
is_deeply views_in_db(), [], '... no view is left';
is_deeply tables_in_db(), [ 'extra', 'item' ], '... and both tables are';
is $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.`item`"), 3, '... with their rows';
is $gone->classify->{class}, 'destructive', 'a removal is destructive';

my $last = eval { DBIO::MySQL::Deploy->new(schema => $s3)->diff };
ok $last && !$last->has_changes, 'the diff after it has nothing left'
  or diag $last ? explain sql_of($last) : "the diff failed: $@";

$_->storage->disconnect for $s1, $s2, $s3;
drop_database();
$raw->disconnect;
undef $raw;

done_testing;
