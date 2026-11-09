use strict;
use warnings;
use Test::More;

# LIVE half of karr k121 (t/169 has the offline half): the pool connections of
# the future_io transport leave a session in strict mode, also where the
# server would start it without -- as the sync storage does since karr k120
# (t/164). Claims, on MySQL and on MariaDB:
#   1. a pool connection whose handshake leaves sql_mode empty (init_command)
#      is strict after the transport opened it;
#   2. eleven characters in CHARACTER(10) are rejected by the async insert
#      instead of being stored as ten;
#   3. an on_connect_do of the caller, replayed on the pool connection, still
#      has the last word.
# Works in a database of its own.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::MySQL::Storage::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async, IO::Async and Future::IO::Impl::IOAsync required for the future_io transport';
}

use DBI;
use Time::HiRes ();

my $DB = "dbio_k121_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
my @schemas;
END {
  local ($@, $?);
  eval { $_->storage->disconnect } for @schemas;
  eval { drop_database() } if $raw;
}

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}

my $loop = IO::Async::Loop->new;
sub wait_for {
  my ($f) = @_;
  my $deadline = Time::HiRes::time() + 30;
  until ($f->is_ready) {
    die "a Future did not settle\n" if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return $f->get;
}

my $dbd = $dsn =~ /\Adbi:(\w+):/i ? lc $1 : 'mysql';
my $n = 0;
sub connect_schema {
  my (%extra) = @_;
  my $class = 'K121Live::Schema' . ++$n;
  eval "package $class; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my $rc = "$class\::Result::Sized";
  eval "package $rc; use DBIO 'Core', -mysql; 1" or die $@;
  $rc->table('sized');
  $rc->add_columns(id => { data_type => 'integer' }, c => { data_type => 'char', size => 10 });
  $rc->set_primary_key('id');
  $class->register_class(Sized => $rc);
  my $schema = $class->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
    "${dbd}_init_command" => "SET sql_mode = ''",
    async => 'future_io', pool_size => 2,
    on_connect_do => ["USE `$DB`"],
    %extra,
  });
  push @schemas, $schema;
  return $schema;
}
sub pool_mode {
  my ($schema) = @_;
  my $f = $schema->storage->async->pool->acquire;
  my $conn = wait_for($f);
  my ($mode) = $conn->{dbh}->selectrow_array('SELECT @@SESSION.sql_mode');
  $schema->storage->async->pool->release($conn);
  return $mode;
}

my $schema = connect_schema();
$raw->do("CREATE TABLE `$DB`.sized (id int primary key, c char(10))");

# 1.
like pool_mode($schema), qr/STRICT_ALL_TABLES/,
  '1: the session of a pool connection that started non-strict is strict';

# 2.
my $f = $schema->resultset('Sized')->create_async({ id => 1, c => 'x' x 11 });
ok !eval { wait_for($f); 1 }, '2: eleven characters in CHARACTER(10) are rejected by the async insert';
is scalar $raw->selectrow_array("SELECT COUNT(*) FROM `$DB`.sized"), 0, '... and no cut value was stored';

# 3.
my $loose = connect_schema(on_connect_do => ["USE `$DB`", "SET SESSION sql_mode = ''"]);
is pool_mode($loose), '', '3: an on_connect_do of the caller runs after and decides';

done_testing;
