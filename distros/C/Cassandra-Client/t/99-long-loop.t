#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Cassandra::Client;

plan skip_all => "CASSANDRA_HOST not set" unless $ENV{CASSANDRA_HOST};

my $time_to_run= $ENV{CASSANDRA_SLOW_TEST};
unless ($time_to_run) {
    plan skip_all => "CASSANDRA_SLOW_TEST not set";
}
if ($time_to_run == 1) {
    $time_to_run= 10; # hehe
}
my $time_to_finish= time() + $time_to_run;

my $client= Cassandra::Client->new( contact_points => [split /,/, $ENV{CASSANDRA_HOST}], username => $ENV{CASSANDRA_USER}, password => $ENV{CASSANDRA_AUTH}, anyevent => (rand()<.5), tls => $ENV{CASSANDRA_TLS}, port => $ENV{CASSANDRA_PORT} );
my $db= 'perl_cassandra_client_tests';
SETUP: {
    $client->connect();
    $client->execute("drop keyspace if exists $db");
    $client->execute("create keyspace $db with replication={'class':'SimpleStrategy', 'replication_factor': 1}");
    $client->execute("create table $db.test_int (id int primary key, value int)");
}

while (time() < $time_to_finish) {
    sleep 1;
    eval {
        $client->execute("insert into $db.test_int (id, value) values (5, 6)");

        {
            my ($result)= $client->execute("select id, value from $db.test_int where id=5");
            my $rows= $result->rows;
            ok(@$rows == 1);
            ok($rows->[0][0] == 5);
            ok($rows->[0][1] == 6);
        }

        $client->execute("delete from $db.test_int where id=5");
        {
            my ($result)= $client->execute("select id, value from $db.test_int where id=5");
            my $rows= $result->rows;
            ok(@$rows == 0);
        }

        1;
    } or do {
        my $error= $@ || "??";
        ok(0) or diag($error);
    };
}

done_testing;
