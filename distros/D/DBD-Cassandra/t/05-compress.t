use 5.010;
use warnings;
use strict;
use DBI;
use Test::More;

unless ($ENV{CASSANDRA_HOST}) {
    plan skip_all => "CASSANDRA_HOST not set";
}

plan tests => 6;

my $keyspace= "dbd_cassandra_tests";

for my $compression (qw/lz4 snappy none/) {
    my $tls= $ENV{CASSANDRA_TLS} // '';
    my $dbh= DBI->connect("dbi:Cassandra:host=$ENV{CASSANDRA_HOST};compression=$compression;tls=$tls", $ENV{CASSANDRA_USER}, $ENV{CASSANDRA_AUTH}, {RaiseError => 1});
    ok($dbh);

    $dbh->do("drop keyspace if exists $keyspace");
    $dbh->do("create keyspace $keyspace with replication={'class': 'SimpleStrategy', 'replication_factor': 1}");

    $dbh->do("create table $keyspace.test (id bigint primary key, b blob)");

    my $original= '0' x 1000000;

    my $sth= $dbh->prepare("insert into $keyspace.test (id, b) values (?, ?)");
    $sth->execute(1, $original);

    my $row= $dbh->selectrow_arrayref("select b from $keyspace.test where id=1");
    ok($row->[0] eq $original);

    $dbh->disconnect;
}
