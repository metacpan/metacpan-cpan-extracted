use strict;
use warnings;
use Test::More;

# LIVE half of karr k120 (t/163 has the offline half and the measurement). The
# connect of the sync storage leaves a session in strict mode, also where the
# server would start it without. Claims, on MySQL and on MariaDB:
#   1. the statement adds STRICT_ALL_TABLES to an empty and to a non-strict
#      mode, keeping what was there, and changes a strict mode by nothing;
#   2. a connection whose handshake leaves sql_mode empty (init_command) is
#      strict after DBIO connected it, and the server rejects eleven characters
#      in CHARACTER(10) instead of storing ten;
#   3. an on_connect_do of the caller still has the last word.
# Works in a database of its own.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Storage;

my $DB = "dbio_k120_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END { if ($raw) { local ($@, $?); eval { drop_database() } } }

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}

my $stmt = DBIO::MySQL::Storage::strict_sql_mode_statement();
sub mode { scalar $raw->selectrow_array('SELECT @@SESSION.sql_mode') }
sub after { my ($set) = @_; $raw->do("SET SESSION sql_mode = '$set'"); $raw->do($stmt); mode() }

# 1.
is after(''), 'STRICT_ALL_TABLES', '1: an empty mode becomes STRICT_ALL_TABLES, no stray comma';
is after('ANSI_QUOTES,NO_BACKSLASH_ESCAPES'),
  'ANSI_QUOTES,NO_BACKSLASH_ESCAPES,STRICT_ALL_TABLES', '1: a mode without it keeps what it had';
is after('STRICT_TRANS_TABLES,ANSI_QUOTES'), 'ANSI_QUOTES,STRICT_TRANS_TABLES',
  '1: STRICT_TRANS_TABLES counts, nothing is added';
is after('STRICT_ALL_TABLES'), 'STRICT_ALL_TABLES', '1: STRICT_ALL_TABLES is left as it is';

# 2.
my $dbd = $dsn =~ /\Adbi:(\w+):/i ? lc $1 : 'mysql';
my $schema_class = 'K120Live::Schema';
eval "package $schema_class; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
my $rc = "$schema_class\::Result::Sized";
eval "package $rc; use DBIO 'Core', -mysql; 1" or die $@;
$rc->table('sized');
$rc->add_columns(id => { data_type => 'integer' }, c => { data_type => 'char', size => 10 });
$rc->set_primary_key('id');
$schema_class->register_class(Sized => $rc);

my $schema = $schema_class->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
  "${dbd}_init_command" => "SET sql_mode = ''",
  on_connect_do => ["USE `$DB`"],
});
my ($mode) = $schema->storage->dbh->selectrow_array('SELECT @@SESSION.sql_mode');
like $mode, qr/STRICT_ALL_TABLES/, '2: the session of a connect that started non-strict is strict';
$schema->storage->dbh->do('CREATE TABLE sized (id int primary key, c char(10))');
ok !eval { $schema->resultset('Sized')->create({ id => 1, c => 'x' x 11 }); 1 },
  '2: eleven characters in CHARACTER(10) are rejected';
is $schema->resultset('Sized')->count, 0, '... and no cut value was stored';
$schema->storage->disconnect;

# 3.
my $loose = $schema_class->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
  "${dbd}_init_command" => "SET sql_mode = ''",
  on_connect_do => ["USE `$DB`", "SET SESSION sql_mode = ''"],
});
is scalar $loose->storage->dbh->selectrow_array('SELECT @@SESSION.sql_mode'), '',
  '3: an on_connect_do of the caller runs after and decides';
$loose->storage->disconnect;

done_testing;
