#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Net::EmptyPort qw( empty_port );

use Consul;

{
    my $agent = Consul->agent( port=>empty_port() );
    ok $agent, "got Agent API object";

    dies_ok { $agent->members } "failing call with no error callback dies";

    {
        my $error = 0;
        lives_ok { $agent->members(error_cb => sub { $error++ }) } "failing call with error callback succeeds";
        ok $error, "error callback was called";
    }
}

{
    my $global_error = 0;
    my $agent = Consul->agent(error_cb => sub { $global_error++ }, port=>empty_port());
    ok $agent, "got Agent API object with global error callback";

    lives_ok { $agent->members } "failing call with global error callback succeeds";
    ok $global_error, "global error callback was called";

    {
        $global_error = 0;
        my $error = 0;
        lives_ok { $agent->members(error_cb => sub { $error++ }) } "failing call with error callback succeeds";
        ok $error, "error callback was called";
        ok !$global_error, "global error callback was not called";
    }
}

done_testing;
