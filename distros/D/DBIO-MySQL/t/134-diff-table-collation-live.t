use strict;
use warnings;
use utf8;
use Test::More;

# LIVE half of karr k109 (t/126 has the offline half and the decision): a table
# that exists with another character set or collation than the schema gives it
# is converted by DBIO::MySQL::Deploy->upgrade where the data provably survives,
# and refused -- loudly, changing nothing -- where it does not.
#
# Before, a Result class with mysql_collate against such a table produced a
# MODIFY COLUMN per text column that wrote no collation: the table kept its
# collation and every later diff reported the same columns again.
#
# What this file claims, on whichever server DBIO_TEST_MYSQL_DSN names:
#   * within one character set (utf8mb4_bin -> utf8mb4_unicode_ci) the upgrade
#     is one CONVERT TO, the rows read back identical -- umlauts, CJK, emoji, the
#     bytes of a BLOB and a VARBINARY included -- and the next diff is empty;
#   * latin1 -> utf8mb4 converts with the same result (umlauts kept);
#   * a latin1 table with a TEXT column is refused (the server would promote the
#     type), and so is utf8mb4 -> latin1 (the emoji would be lost): a
#     DBIO::Exception naming table and both collations, the table, its collation
#     and its rows exactly as they were;
#   * a unique key whose values collide under the new collation is refused by the
#     server; the upgrade dies and the table is as it was.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/118).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB = "mysql_k109_$$";

my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0, mysql_enable_utf8mb4 => 1 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
sub fresh_database { drop_database(); $raw->do("CREATE DATABASE `$DB`") }
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_database() };
  }
}

unless (eval { fresh_database(); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
}
note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

my $version = 0;
sub schema_version {
  my (%o) = @_;
  my $ns = 'K109Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my $class = "${ns}::Result::Note";
  eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
  $class->table('note');
  $class->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 100 },
    body  => { data_type => ($o{body} // 'longtext'), is_nullable => 1 },
    raw   => { data_type => 'blob', is_nullable => 1 },
    code  => { data_type => 'varbinary', size => 16, is_nullable => 1 },
  );
  $class->set_primary_key('id');
  $class->add_unique_constraint([qw(title)]) if $o{unique};
  $class->mysql_charset($o{charset}) if $o{charset};
  $class->mysql_collate($o{collate}) if $o{collate};
  $ns->register_class(Note => $class);
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

# What the table holds, as perl sees it: characters for the text columns, hex for
# the binary ones.
sub rows {
  return $raw->selectall_arrayref(
    "SELECT id, title, body, HEX(`raw`), HEX(`code`) FROM `$DB`.`note` ORDER BY id");
}
sub table_collation {
  return scalar $raw->selectrow_array(
    'SELECT TABLE_COLLATION FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?', undef, $DB, 'note');
}
sub column_collations {
  return $raw->selectall_arrayref(
    'SELECT COLUMN_NAME, COLLATION_NAME FROM information_schema.COLUMNS '
  . 'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLLATION_NAME IS NOT NULL ORDER BY COLUMN_NAME',
    undef, $DB, 'note');
}
sub column_types {
  return join ',', map { "$_->[0]:$_->[1]" } @{ $raw->selectall_arrayref(
    'SELECT COLUMN_NAME, DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? ORDER BY COLUMN_NAME',
    undef, $DB, 'note') };
}

sub next_diff_empty {
  my ($schema, $name) = @_;
  my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $again && !$again->has_changes, $name
    or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
}

my @ROWS = (
  [ 1, 'Müller',       '日本語 ñ ü ß straße', 'C3A4FF00', 'C3A4' ],
  [ 2, 'tête-à-tête',  'ÆØÅ',                  '00',       '01020304' ],
);
my @INSERT = ('INSERT INTO `note` (id, title, body, `raw`, `code`) VALUES (?, ?, ?, UNHEX(?), UNHEX(?))');
sub fill {
  my ($rows) = @_;
  $raw->do("USE `$DB`");
  $raw->do($INSERT[0], undef, @$_) for @$rows;
}

# --- same character set --------------------------------------------------------
{
  fresh_database();
  my $old = schema_version(collate => 'utf8mb4_bin');
  DBIO::MySQL::Deploy->new(schema => $old)->install;
  $old->storage->disconnect;
  fill([ @ROWS, [ 3, 'emoji', '😀 und mehr', 'FF', '' ] ]);
  my @before = @{ rows() };
  is table_collation(), 'utf8mb4_bin', 'the table starts as utf8mb4_bin';

  my $new = schema_version(collate => 'utf8mb4_unicode_ci');
  my $diff = DBIO::MySQL::Deploy->new(schema => $new)->diff;
  is_deeply [ map { $_->as_sql } @{ $diff->operations } ],
    [ 'ALTER TABLE `note` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' ],
    'the diff is one CONVERT TO';

  ok eval { DBIO::MySQL::Deploy->new(schema => $new)->upgrade; 1 }, 'the upgrade runs' or diag $@;
  is table_collation(), 'utf8mb4_unicode_ci', 'the table has the collation of the schema';
  is_deeply column_collations(), [ map { [ $_, 'utf8mb4_unicode_ci' ] } qw(body title) ], '... and so do its text columns';
  is_deeply rows(), \@before, 'every row reads back identical: text, emoji, BLOB and VARBINARY bytes';
  next_diff_empty($new, 'the next diff has nothing left');
  $new->storage->disconnect;
}

# --- latin1 -> utf8mb4 ------------------------------------------------------------
{
  fresh_database();
  my $old = schema_version(charset => 'latin1', collate => 'latin1_swedish_ci');
  DBIO::MySQL::Deploy->new(schema => $old)->install;
  $old->storage->disconnect;
  fill([ [ 1, 'Müller', 'straße é à Æ', 'C3A4FF00', 'C3A4' ], [ 2, 'tête-à-tête', 'ÆØÅ', '00', '01020304' ] ]);
  my @before = @{ rows() };
  is table_collation(), 'latin1_swedish_ci', 'the table starts as latin1';
  my $types = column_types();

  my $new = schema_version();
  ok eval { DBIO::MySQL::Deploy->new(schema => $new)->upgrade; 1 }, 'the upgrade to utf8mb4 runs' or diag $@;
  is table_collation(), 'utf8mb4_unicode_ci', 'the table is utf8mb4_unicode_ci';
  is_deeply rows(), \@before, 'the umlauts and the binary columns are as they were';
  is column_types(), $types, 'no column changed its type';
  next_diff_empty($new, 'the next diff has nothing left');
  $new->storage->disconnect;
}

# --- refusals --------------------------------------------------------------------
sub refused {
  my (%o) = @_;
  fresh_database();
  my $old = schema_version(%{ $o{from} });
  DBIO::MySQL::Deploy->new(schema => $old)->install;
  $old->storage->disconnect;
  fill($o{rows});
  $raw->do($o{prep}) if $o{prep};
  my @before = @{ rows() };
  my ($collation, $types, $cols) = (table_collation(), column_types(), column_collations());

  my $new = schema_version(%{ $o{to} });
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $new)->upgrade };
  my $err = "$@";
  ok !$diff, "$o{name}: the upgrade dies";
  like $err, $o{error}, '... ' . $o{why};
  is table_collation(), $collation, '... the table has the collation it had';
  is column_types(), $types, '... its columns the types they had';
  is_deeply column_collations(), $cols, '... and the collations they had';
  is_deeply rows(), \@before, '... and the rows are as they were';
  $new->storage->disconnect;
}

refused(
  name => 'latin1 table with a TEXT column',
  from => { charset => 'latin1', collate => 'latin1_swedish_ci' },
  to   => {},
  prep => 'ALTER TABLE `note` MODIFY `body` text',
  rows => [ [ 1, 'Müller', 'straße', 'AA', 'BB' ] ],
  error => qr/table `note` has the collation latin1_swedish_ci and the target gives it utf8mb4_unicode_ci.*column `body` is a text and the server changes its type/s,
  why   => 'naming the table, both collations and the column',
);
refused(
  name => 'utf8mb4 to latin1 with an emoji in it',
  from => { collate => 'utf8mb4_unicode_ci' },
  to   => { charset => 'latin1', collate => 'latin1_swedish_ci' },
  rows => [ [ 1, 'Müller', '😀', 'AA', 'BB' ] ],
  error => qr/table `note` has the collation utf8mb4_unicode_ci and the target gives it latin1_swedish_ci.*may lose characters/s,
  why   => 'naming the table and both collations',
);

# A unique key that collides under the new collation: the server refuses.
{
  fresh_database();
  my $old = schema_version(collate => 'utf8mb4_bin', unique => 1);
  DBIO::MySQL::Deploy->new(schema => $old)->install;
  $old->storage->disconnect;
  fill([ [ 1, 'abc', 'x', 'AA', 'BB' ], [ 2, 'ABC', 'y', 'AA', 'BB' ] ]);
  my @before = @{ rows() };

  my $new = schema_version(collate => 'utf8mb4_unicode_ci', unique => 1);
  ok !eval { DBIO::MySQL::Deploy->new(schema => $new)->upgrade; 1 }, 'a unique key that collides under the new collation: the upgrade dies';
  like "$@", qr/duplicate/i, '... with the server\'s duplicate-entry error';
  is table_collation(), 'utf8mb4_bin', '... the table keeps its collation';
  is_deeply rows(), \@before, '... and its rows';
  $new->storage->disconnect;
}

done_testing;
