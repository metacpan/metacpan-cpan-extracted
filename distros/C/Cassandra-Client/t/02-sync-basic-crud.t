#!perl
use 5.010;
use strict;
use warnings;
use File::Basename qw//; use lib File::Basename::dirname(__FILE__).'/lib';
use Test::More;
use TestCassandra;

plan skip_all => "Missing Cassandra test environment" unless TestCassandra->is_ok;
plan tests => 5;

my $client= TestCassandra->new;
$client->connect();

my $db= 'perl_cassandra_client_tests';
$client->execute("drop keyspace if exists $db");
$client->execute("create keyspace $db with replication={'class':'SimpleStrategy', 'replication_factor': 1}");
$client->execute("create table $db.test_int (id int primary key, value int)");
$client->execute("insert into $db.test_int (id, value) values (5, 6)");
$client->prepare("insert into $db.test_int (id, value) values (5, 7)");
{
    my ($result)= $client->execute("select id, value from $db.test_int where id=5");
    my $rows= $result->rows;
    ok(@$rows == 1);
    ok($rows->[0][0] == 5);
    ok($rows->[0][1] == 6);
    my $hashes= $result->row_hashes;
    is_deeply($hashes, [
        {
            id => 5,
            value => 6,
        }
    ]);
}

$client->execute("delete from $db.test_int where id=5");
{
    my ($result)= $client->execute("select id, value from $db.test_int where id=5");
    my $rows= $result->rows;
    ok(@$rows == 0);
}
