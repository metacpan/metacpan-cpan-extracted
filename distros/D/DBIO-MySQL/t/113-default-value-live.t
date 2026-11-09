use strict;
use warnings;
use Test::More;

# LIVE half of karr k78 / k96 (t/112 has the offline half and the reasoning):
# a DEFAULT survives the whole round trip on the server -- declared in the
# schema, written by install or by a diff (CREATE TABLE, ADD COLUMN, MODIFY
# COLUMN), read back from the catalog -- and the next diff has nothing to say.
#
# What this file claims:
#   * a column with DEFAULT CURRENT_TIMESTAMP (a scalar reference in the schema)
#     is created by the diff: the server evaluates it (1067 before the fix, the
#     diff had written the string 'CURRENT_TIMESTAMP');
#   * a string default with an apostrophe and with a backslash reaches the
#     server unchanged: a row inserted without the column reads the value
#     declared, character for character (the backslash is an escape on both
#     servers in the default sql_mode, measured MySQL 8.0.30 / MariaDB 11.8.9);
#   * the catalog form (MySQL: the value, DEFAULT_GENERATED in EXTRA for an
#     expression; MariaDB: a quoted literal, current_timestamp()) is read back
#     as value and expression flag, so the diff after it is empty;
#   * install and upgrade of an empty database give the same defaults.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/109).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB = "mysql_k78_$$";

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

my $APOS = q{it's O'K};
my $BS   = 'C:\\tmp\\new\\x\\';

my $version = 0;
# $with: the columns beyond the key. $other: a second table with the same.
sub schema_version {
  my (%opt) = @_;
  my $ns = 'K78Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $t (grep { $opt{$_} } qw(item other)) {
    my $class = "${ns}::Result::\u$t";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($t);
    $class->add_columns(
      id => { data_type => 'int' },
      %{ $opt{$t} },
    );
    $class->set_primary_key('id');
    $ns->register_class("\u$t" => $class);
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

my %defaults = (
  created => { data_type => 'timestamp', is_nullable => 1, default_value => \'CURRENT_TIMESTAMP' },
  apos    => { data_type => 'varchar', size => 40, default_value => $APOS },
  bs      => { data_type => 'varchar', size => 40, default_value => $BS },
  code    => { data_type => 'char',    size => 5,  default_value => '007' },
  hits    => { data_type => 'int',     default_value => 3 },
  uid     => { data_type => 'varchar', size => 40, is_nullable => 1, default_value => \q{(concat('x','y'))} },
);

# What a row inserted without these columns reads.
sub row_of {
  my ($table, $id) = @_;
  $raw->do("INSERT INTO `$DB`.`$table` (`id`) VALUES (?)", undef, $id);
  return $raw->selectrow_hashref("SELECT * FROM `$DB`.`$table` WHERE `id` = ?", undef, $id);
}

sub check_row {
  my ($row, $what) = @_;
  like $row->{created}, qr/\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d/, "$what: DEFAULT CURRENT_TIMESTAMP is evaluated, not the string";
  is $row->{apos}, $APOS, "$what: the apostrophe default reads back as declared";
  is $row->{bs},   $BS,   "$what: the backslash default reads back as declared";
  is $row->{code}, '007', "$what: a string that looks like a number stays a string";
  is $row->{hits}, 3,     "$what: a number";
  is $row->{uid}, 'xy', "$what: an expression other than the time is evaluated, quotes inside it intact";
}

sub apply_and_check_empty {
  my ($schema, $what) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade };
  unless (ok $diff && !$@, "$what: the upgrade runs") {
    diag "upgrade failed: $@";
    return;
  }
  my @sql = map { $_->as_sql } @{ $diff->operations };
  note "  $_" for @sql;
  my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $again && !$again->has_changes, "$what: the next diff has nothing left"
    or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
  return \@sql;
}

# --- install gives the defaults -------------------------------------------------
{
  my $schema = schema_version(item => { %defaults });
  ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'install runs' or diag $@;
  check_row(row_of(item => 1), 'install');
  my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $again && !$again->has_changes, 'install: the diff of the installed schema is empty'
    or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
  $schema->storage->disconnect;
}

# --- upgrade of an empty database: CREATE TABLE ------------------------------
{
  drop_database();
  $raw->do("CREATE DATABASE `$DB`");
  my $schema = schema_version(item => { %defaults });
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade };
  ok $diff && !$@, 'CREATE TABLE: the upgrade runs' or diag $@;
  note "  $_" for map { $_->as_sql } @{ $diff->operations };
  my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $again && !$again->has_changes, 'CREATE TABLE: the next diff has nothing left'
    or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
  check_row(row_of(item => 1), 'CREATE TABLE');
  $schema->storage->disconnect;
}

# --- ADD COLUMN: the columns are new to an existing table --------------------
{
  drop_database();
  $raw->do("CREATE DATABASE `$DB`");
  $raw->do("CREATE TABLE `$DB`.`item` (`id` int NOT NULL, PRIMARY KEY (`id`)) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
  my $schema = schema_version(item => { %defaults });
  my $sql = apply_and_check_empty($schema, 'ADD COLUMN');
  is scalar(grep { /ADD COLUMN/ } @{ $sql // [] }), scalar(keys %defaults), '... one ADD COLUMN per column'
    or diag explain $sql;
  check_row(row_of(item => 1), 'ADD COLUMN');
  $schema->storage->disconnect;
}

# --- MODIFY COLUMN: the defaults change to others ----------------------------
{
  my $schema = schema_version(item => {
    %defaults,
    apos => { data_type => 'varchar', size => 40, default_value => "O'Neil\\" },
    bs   => { data_type => 'varchar', size => 40, default_value => $BS . "'" },
  });
  my $sql = apply_and_check_empty($schema, 'MODIFY COLUMN');
  is scalar(grep { /MODIFY COLUMN/ } @{ $sql // [] }), 2, '... the two changed columns are modified' or diag explain $sql;
  my $row = row_of(item => 2);
  is $row->{apos}, "O'Neil\\", 'MODIFY COLUMN: the new apostrophe default';
  is $row->{bs},   $BS . "'",  'MODIFY COLUMN: the new backslash default';
  like $row->{created}, qr/\A\d{4}-/, 'MODIFY COLUMN: the columns not touched keep theirs';
  $schema->storage->disconnect;
}

done_testing;
