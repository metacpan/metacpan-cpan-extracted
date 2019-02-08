#!perl
use 5.010;
use strict;
use warnings;
use File::Basename qw//; use lib File::Basename::dirname(__FILE__).'/lib';
use Test::More;
use TestCassandra;
use AnyEvent;

# Add some junk into our Perl magic variables
local $"= "junk join string ,";
local $/= "junk slurp";
local $\= "abcdef";

plan skip_all => "Missing Cassandra test environment" unless TestCassandra->is_ok;
plan tests => 4;

{
    my $cv= AnyEvent->condvar;

    my $client= TestCassandra->new( anyevent => 1 );
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
    my $client= TestCassandra->new;
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
    my $client= TestCassandra->new;
    my ($error)= $client->call_connect;
    ok(!$error) or diag($error);

    $client->shutdown;
}

{
    my $client= TestCassandra->new;
    eval {
        my $cfuture= $client->future_connect;
        $cfuture->();

        $client->shutdown;

        ok(1);
    } or do {
        ok(0) or diag($@);
    };
}
