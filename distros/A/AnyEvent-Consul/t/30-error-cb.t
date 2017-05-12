#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;

use AnyEvent::Consul;

{
    my $cv = AE::cv;

    my $global_error = 0;
    my $agent = AnyEvent::Consul->agent(error_cb => sub { $global_error++; $cv->send });
    ok $agent, "got Agent API object";

    lives_ok { $agent->members } "failing call with global error callback succeeds";
    $cv->recv;
    ok $global_error, "global error callback was called";
}

{
    my $cv = AE::cv;

    my $agent = AnyEvent::Consul->agent;
    ok $agent, "got Agent API object";

    my $error = 0;
    lives_ok { $agent->members(error_cb => sub { $error++; $cv->send }) } "failing call with error callback succeeds";
    $cv->recv;
    ok $error, "error callback was called";
}

=pod
{
    my $global_error = 0;
    my $agent = AnyEvent::Consul->agent(error_cb => sub { $global_error++ });
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
=cut

done_testing;
