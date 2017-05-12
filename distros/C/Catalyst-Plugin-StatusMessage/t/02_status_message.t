#!/usr/bin/env perl

use strictures 1;
use Test::More;

use lib 't/lib';
use Catalyst::Test 'TestApp';


{
    # Basic initial '/show' that should be empty
    my $resp = request('/show');
    ok($resp->is_success, 'HTTP 200 response');
    is($resp->content, "status: na\nerror: na");
}

{
    # Load a status message
    my $resp = request('/save_status_msg/Test%20Status%20Message', );
    ok($resp->is_redirect, 'HTTP 302 response');
    my $redir_uri1 = $resp->header('location');
    diag("Redirected to $redir_uri1");
    like($redir_uri1, qr|http://localhost/show\?mid=\d{8}|, "Redirect URI");

    # Follow redirect to get the message
    my $resp2 = request($redir_uri1);
    ok($resp2->is_success, 'HTTP 200 response');
    is($resp2->content, "status: Test Status Message\nerror: na",
        "Check status msg found");

    # Make sure we don't get it twice
    is(get($redir_uri1), "status: na\nerror: na",
        "Message gone on second access");


    # Load a error message
    my $resp3 = request('/save_error_msg/Test%20Error%20Message', );
    ok($resp3->is_redirect, 'HTTP 302 response');
    my $redir_uri2 = $resp3->header('location');
    diag("Redirected to $redir_uri2");
    like($redir_uri2, qr|http://localhost/show\?mid=\d{8}|, "Redirect URI");

    # Follow redirect to get the message
    my $resp4 = request($redir_uri2);
    ok($resp4->is_success, 'HTTP 200 response');
    is($resp4->content, "status: na\nerror: Test Error Message",
        "Check error msg found");

    # Make sure we don't get it twice
    is(get($redir_uri2), "status: na\nerror: na",
        "Message gone on second access");
}

done_testing();
