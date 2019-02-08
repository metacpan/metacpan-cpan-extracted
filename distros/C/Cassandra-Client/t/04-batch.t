#!perl
use 5.010;
use strict;
use warnings;
use File::Basename qw//; use lib File::Basename::dirname(__FILE__).'/lib';
use Test::More;
use TestCassandra;

plan skip_all => "Missing Cassandra test environment" unless TestCassandra->is_ok;
plan tests => 7;

my $client= TestCassandra->new;
$client->connect();

my $db= 'perl_cassandra_client_tests';
$client->execute("drop keyspace if exists $db");
$client->execute("create keyspace $db with replication={'class':'SimpleStrategy', 'replication_factor': 1}");
$client->execute("create table $db.test_int (id int primary key, value int)");
$client->batch([
    [ "insert into $db.test_int (id, value) values (?, ?)", [5, 6] ],
    [ "insert into $db.test_int (id, value) values (?, ?)", [6, 6] ],
    [ "insert into $db.test_int (id, value) values (?, ?)", [7, 6] ],
]);
{
    my ($result)= $client->execute("select id, value from $db.test_int where id in (5, 6, 7, 8)");
    my $rows= $result->rows;
    ok(@$rows == 3);
    ok($rows->[0][0] == 5);
    ok($rows->[0][1] == 6);
    ok($rows->[1][0] == 6);
    ok($rows->[1][1] == 6);
    ok($rows->[2][0] == 7);
    ok($rows->[2][1] == 6);
}
