#!perl
use 5.010;
use strict;
use warnings;
use File::Basename qw//; use lib File::Basename::dirname(__FILE__).'/lib';
use Test::More;
use TestCassandra;

plan skip_all => "Missing Cassandra test environment" unless TestCassandra->is_ok;

my $client= TestCassandra->new;
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
