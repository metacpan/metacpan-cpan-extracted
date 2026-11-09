use strict;
use warnings;
use Test::More;

# LIVE half of karr k111 (t/139 has the offline half and the reasoning): a column
# with a character set or collation of its own, off the default of its table, is
# written by MODIFY COLUMN, ADD COLUMN and CREATE TABLE, so the diff converges.
#
# The target is a second database, described by hand with the columns as they
# should be, and introspected like any target; the source is the database the
# upgrade runs on. After the statements ran, the introspection of the source reads
# the collations of the target and the next diff is empty.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in two databases of its own, created and dropped here (see t/134).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Introspect;
use DBIO::MySQL::Diff;

my @DB = ("mysql_k111_src_$$", "mysql_k111_tgt_$$");
my ($src, $tgt);

sub connect_to {
  my ($db) = @_;
  return DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0, mysql_enable_utf8mb4 => 1 });
}
my $raw = connect_to();
sub drop_databases { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$_`") for @DB }
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_databases() };
  }
}

unless (eval { drop_databases(); $raw->do("CREATE DATABASE `$_`") for @DB; 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
}
note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

($src, $tgt) = map { my $d = connect_to(); $d->do("USE `$_`"); $d } @DB;

sub model { return DBIO::MySQL::Introspect->new(dbh => $_[0])->model }
sub diff  { return DBIO::MySQL::Diff->new(source => model($src), target => model($tgt)) }
sub collations {
  return $_[0]->selectall_arrayref(
    'SELECT COLUMN_NAME, COLLATION_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() '
  . 'AND TABLE_NAME = ? AND COLLATION_NAME IS NOT NULL ORDER BY COLUMN_NAME', undef, $_[1]);
}

# the source: a table on the default of the table; the target: columns off it
$src->do('CREATE TABLE t (id int NOT NULL, title varchar(100) NOT NULL, tag varchar(20) NOT NULL, PRIMARY KEY (id)) '
  . 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
$tgt->do('CREATE TABLE t (id int NOT NULL, title varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL, '
  . 'tag varchar(20) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL, '
  . 'note varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL, '
  . 'plain varchar(30) NOT NULL, PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
$tgt->do('CREATE TABLE fresh (id int NOT NULL, name varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL, '
  . 'PRIMARY KEY (id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');

my $diff = diff();
my @sql = map { $_->as_sql } @{ $diff->operations };
like join("\n", @sql), qr/MODIFY COLUMN `title` varchar\(100\) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL/, 'MODIFY writes the collation of the column';
like join("\n", @sql), qr/ADD COLUMN `note` varchar\(30\) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL/, 'ADD COLUMN writes it';
like join("\n", @sql), qr/`name` varchar\(30\) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL/, 'CREATE TABLE writes it';

ok eval { $src->do($_) for @sql; 1 }, 'the statements run' or diag $@;
is_deeply collations($src, 't'), collations($tgt, 't'), 'the columns have the collations of the target';
is_deeply collations($src, 'fresh'), collations($tgt, 'fresh'), '... and so does the new table';

my $again = diff();
ok !$again->has_changes, 'the second diff is empty'
  or diag explain [ map { $_->as_sql } @{ $again->operations } ];

# the other way: back onto the table default
$src->do('ALTER TABLE t MODIFY COLUMN title varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL');
$tgt->do('ALTER TABLE t MODIFY COLUMN title varchar(100) NOT NULL');
my @back = map { $_->as_sql } @{ diff()->operations };
is_deeply \@back, [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(100) NOT NULL;' ], 'a column back on the default is written without';
$src->do($_) for @back;
ok !diff()->has_changes, '... and the diff after it is empty';

done_testing;
