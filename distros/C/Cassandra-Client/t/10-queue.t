#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Cassandra::Client;

plan skip_all => "CASSANDRA_HOST not set" unless $ENV{CASSANDRA_HOST};
plan tests => 15;

my $client= Cassandra::Client->new(
    contact_points => [split /,/, $ENV{CASSANDRA_HOST}],
    username => $ENV{CASSANDRA_USER},
    password => $ENV{CASSANDRA_AUTH},
    anyevent => (rand()<.5),
    tls      => $ENV{CASSANDRA_TLS},

    # This test
    max_concurrent_queries => 5,
    command_queue_config => {
        max_entries => 5,
    }
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
