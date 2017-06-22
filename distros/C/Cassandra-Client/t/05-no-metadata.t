#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Cassandra::Client;

plan skip_all => "CASSANDRA_HOST not set" unless $ENV{CASSANDRA_HOST};

my $client= Cassandra::Client->new( contact_points => [split /,/, $ENV{CASSANDRA_HOST}], username => $ENV{CASSANDRA_USER}, password => $ENV{CASSANDRA_AUTH}, anyevent => (rand()<.5), tls => $ENV{CASSANDRA_TLS} );
$client->connect();

{
    my $result;
    eval {
        ($result)= $client->execute("list users");
        1;
    } or do {
        plan skip_all => "Need a cluster with authentication configured for this test to work" if $@ =~ /onymous to perform this reques/;
        die $@;
    };
    my $headers= $result->column_names;
    ok(0+@$headers > 1);
    ok($_) for @$headers;
}

done_testing;
