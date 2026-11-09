use strict;
use warnings;
use Test::More;

# LIVE half of karr k118 (t/147 has the offline half and the reasoning): the
# shared test schema of core, with Track pointing at two virtual views, deploys
# whole (no 1824), Track has foreign keys to its tables and none to a view, and
# the next diff has nothing left.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/138).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use DBIO::Test::Schema;

my $DB  = "mysql_k118_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END { if ($raw) { local ($@, $?); eval { drop_database() } } }

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
}
note sprintf 'server %s', scalar $raw->selectrow_array('SELECT VERSION()');

{
  package K118Live::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
K118Live::Schema->register_class($_ => DBIO::Test::Schema->source($_)->result_class)
  for DBIO::Test::Schema->sources;

my $schema = K118Live::Schema->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });

ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the test schema installs'
  or diag "install failed: $@";

ok $raw->selectrow_array(
  'SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?', undef, $DB, 'track'),
  'Track is deployed';

my @fk = @{ $raw->selectall_arrayref(
  'SELECT REFERENCED_TABLE_NAME FROM information_schema.KEY_COLUMN_USAGE '
. 'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND REFERENCED_TABLE_NAME IS NOT NULL', undef, $DB, 'track') };
ok scalar(@fk), 'Track keeps the foreign keys to its tables';
is_deeply [ grep { /^year\d+cds$/ } map { $_->[0] } @fk ], [], 'no foreign key to a view';

my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
ok $again && !$again->has_changes, 'the next diff has nothing left'
  or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";

$schema->storage->disconnect;
done_testing;
