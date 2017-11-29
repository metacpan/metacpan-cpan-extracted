use 5.010;
use warnings;
use strict;
use Test::More;

unless ($ENV{CASSANDRA_HOST}) {
    plan skip_all => "CASSANDRA_HOST not set";
}

plan tests => 2;

use DBI;
my $tls= $ENV{CASSANDRA_TLS} // '';
my $port= $ENV{CASSANDRA_PORT} ? ";port=$ENV{CASSANDRA_PORT}" : "";
my $dbh= DBI->connect("dbi:Cassandra:host=$ENV{CASSANDRA_HOST};consistency=quorum;tls=$tls$port", $ENV{CASSANDRA_USER}, $ENV{CASSANDRA_AUTH}, {RaiseError => 1, Warn => 1, PrintWarn => 0, PrintError => 0});
ok($dbh);

my $keyspace= "dbd_cassandra_tests";

$dbh->do("drop keyspace if exists $keyspace");
$dbh->do("create keyspace $keyspace with replication={'class': 'SimpleStrategy', 'replication_factor': 1}");
$dbh->do("create table $keyspace.test_int (id bigint primary key, val text, id2 uuid)");
my $sth1= $dbh->prepare("insert into $keyspace.test_int (id, val, id2) values (?, ?, ?)");
$sth1->bind_param(1, 1);
$sth1->bind_param(2, "test");
$sth1->bind_param(3, "12345678-1234-1234-1234-123412341234");
$sth1->execute;

my $sth2= $dbh->prepare("select id, val, id2 from $keyspace.test_int where id=?", {async=>1});
$sth2->bind_param(1, 1);
$sth2->execute;
my $row= $sth2->fetchall_arrayref()->[0];
is_deeply($row, [
    1,
    "test",
    "12345678-1234-1234-1234-123412341234",
]);

$dbh->disconnect;
