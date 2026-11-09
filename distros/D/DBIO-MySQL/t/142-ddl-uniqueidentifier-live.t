use strict;
use warnings;
use Test::More;

# LIVE half of karr k115 (t/141 has the offline half and the reasoning): the
# shared test schema of core, with its uniqueidentifier columns (ArtistGUID),
# deploys on the server, the GUID columns come back as varchar(36), and the
# next diff has nothing left.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here (see t/138).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use DBIO::Test::Schema;

my $DB  = "mysql_k115_$$";
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
  package K115Live::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
K115Live::Schema->register_class($_ => DBIO::Test::Schema->source($_)->result_class)
  for DBIO::Test::Schema->sources;

my $schema = K115Live::Schema->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });

ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the test schema installs'
  or diag "install failed: $@";

is_deeply
  [ sort { $a->[0] cmp $b->[0] } @{ $raw->selectall_arrayref(
    'SELECT COLUMN_NAME, COLUMN_TYPE, EXTRA FROM information_schema.COLUMNS '
  . "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'artist_guid' AND COLUMN_NAME IN ('artistid', 'a_guid')"
  , undef, $DB) } ],
  [ [ a_guid => 'varchar(36)', '' ], [ artistid => 'varchar(36)', '' ] ],
  'the GUID columns are varchar(36), and not AUTO_INCREMENT';

my $again = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
ok $again && !$again->has_changes, 'the next diff has nothing left'
  or diag $again ? explain [ map { $_->as_sql } @{ $again->operations } ] : "the diff failed: $@";

$schema->storage->disconnect;
done_testing;
