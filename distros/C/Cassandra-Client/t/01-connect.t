#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Cassandra::Client;
use AnyEvent;

# Add some junk into our Perl magic variables
local $"= "junk join string ,";
local $/= "junk slurp";
local $\= "abcdef";

plan skip_all => "CASSANDRA_HOST not set" unless $ENV{CASSANDRA_HOST};
plan tests => 4;

{
    my $cv= AnyEvent->condvar;

    my $client= Cassandra::Client->new( contact_points => [split /,/, $ENV{CASSANDRA_HOST}], username => $ENV{CASSANDRA_USER}, password => $ENV{CASSANDRA_AUTH}, anyevent => 1, tls => $ENV{CASSANDRA_TLS}, port => $ENV{CASSANDRA_PORT});
    $client->async_connect->then(sub {
        $client->shutdown

    })->then(sub {
        $cv->send;
        ok(1);
    }, sub {
        $cv->send;
        ok(0) or diag($_[0]);
    });

    $cv->recv;
}



{
    my $client= Cassandra::Client->new( contact_points => [split /,/, $ENV{CASSANDRA_HOST}], username => $ENV{CASSANDRA_USER}, password => $ENV{CASSANDRA_AUTH}, anyevent => (rand()<.5), tls => $ENV{CASSANDRA_TLS}, port => $ENV{CASSANDRA_PORT} );
    eval {
        $client->connect;
        $client->shutdown;
        ok(1);
        1;
    } or do {
        ok(0) or diag($@);
    };
}

{
    my $client= Cassandra::Client->new( contact_points => [split /,/, $ENV{CASSANDRA_HOST}], username => $ENV{CASSANDRA_USER}, password => $ENV{CASSANDRA_AUTH}, anyevent => (rand()<.5), tls => $ENV{CASSANDRA_TLS}, port => $ENV{CASSANDRA_PORT} );
    my ($error)= $client->call_connect;
    ok(!$error) or diag($error);

    $client->shutdown;
}

{
    my $client= Cassandra::Client->new( contact_points => [split /,/, $ENV{CASSANDRA_HOST}], username => $ENV{CASSANDRA_USER}, password => $ENV{CASSANDRA_AUTH}, anyevent => (rand()<.5), tls => $ENV{CASSANDRA_TLS}, port => $ENV{CASSANDRA_PORT} );
    eval {
        my $cfuture= $client->future_connect;
        $cfuture->();

        $client->shutdown;

        ok(1);
    } or do {
        ok(0) or diag($@);
    };
}
