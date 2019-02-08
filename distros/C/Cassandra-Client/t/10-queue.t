#!perl
use 5.010;
use strict;
use warnings;
use File::Basename qw//; use lib File::Basename::dirname(__FILE__).'/lib';
use Test::More;
use TestCassandra;

plan skip_all => "Missing Cassandra test environment" unless TestCassandra->is_ok;
plan tests => 15;

my $client= TestCassandra->new(
    # This test
    max_concurrent_queries => 5,
    command_queue => Cassandra::Client::Policy::Queue::Default->new(
        max_entries => 5,
    ),
);
$client->connect();

my $db= 'perl_cassandra_client_tests';
$client->execute("drop keyspace if exists $db");
$client->execute("create keyspace $db with replication={'class':'SimpleStrategy', 'replication_factor': 1}");
$client->execute("create table $db.test_int (id int primary key, value int)");

my @queries;
push @queries, $client->future_execute("insert into $db.test_int (id, value) values (?, ?)", [ $_, $_+1 ]) for 1..15;

for my $i (1..15) {
    my $success= eval { (shift @queries)->(); 1; } || 0;
    ok($success == ( $i <= 10 )); # Only first ten should work
}
