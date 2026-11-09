use strict;
use warnings;
use Test::More;

# LIVE half of karr k82 (t/117 has the offline half and the reasoning): the
# table that DBIO::MySQL::Deploy->upgrade creates in an empty database has the
# character set and collation install() gives it.
#
# WHY: the CREATE TABLE of a diff named the character set only, so the server
# filled in its own default collation (utf8mb4_0900_ai_ci on MySQL 8,
# utf8mb4_uca1400_ai_ci on MariaDB 11) while install_ddl writes
# utf8mb4_unicode_ci. Every text column of an upgraded table then differed from
# the schema, and each later diff reported a MODIFY COLUMN that changed nothing.
#
# What this file claims, for a table with text columns:
#   * the upgrade of the empty database runs;
#   * the text columns of the table carry utf8mb4_unicode_ci -- the server's
#     default is not what they end up with;
#   * the next diff is empty, and so is the diff of an install().
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/113).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB = "mysql_k82_$$";

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
  my $ns = 'K82Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my $class = "${ns}::Result::Note";
  eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
  $class->table('note');
  $class->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 100 },
    body  => { data_type => 'text', is_nullable => 1 },
    code  => { data_type => 'char', size => 8 },
  );
  $class->set_primary_key('id');
  $ns->register_class(Note => $class);
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

sub collations {
  return $raw->selectall_arrayref(
    'SELECT COLUMN_NAME, COLLATION_NAME FROM information_schema.COLUMNS '
  . 'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLLATION_NAME IS NOT NULL ORDER BY COLUMN_NAME',
    undef, $DB, 'note');
}

my @WANT = (
  [ body => 'utf8mb4_unicode_ci' ], [ code => 'utf8mb4_unicode_ci' ], [ title => 'utf8mb4_unicode_ci' ],
);

sub next_diff_empty {
  my ($schema, $name) = @_;
  my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $again && !$again->has_changes, $name
    or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";
}

# --- upgrade of an empty database --------------------------------------------
{
  my $schema = schema_version();
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade };
  ok $diff && !$@, 'upgrade of the empty database runs' or diag $@;
  is_deeply collations(), \@WANT, 'the text columns of the table carry the collation of install_ddl';
  next_diff_empty($schema, 'the next diff has nothing left');
  $schema->storage->disconnect;
}

# --- install, for comparison -------------------------------------------------
{
  drop_database();
  $raw->do("CREATE DATABASE `$DB`");
  my $schema = schema_version();
  ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'install runs' or diag $@;
  is_deeply collations(), \@WANT, '... with the same collations';
  next_diff_empty($schema, '... and the diff of it is empty');
  $schema->storage->disconnect;
}

done_testing;
