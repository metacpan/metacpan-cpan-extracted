#!/usr/bin/env perl

use strictures 1;
use Test::More;

use lib 't/lib';
use Catalyst::Test 'TestApp2';


{
    # Basic initial '/show' that should be empty
    my $resp = request('/show');
    ok($resp->is_success, 'HTTP 200 response');
    is($resp->content, 'NA');
}

{
    # Message with session
    my $resp = request('/with_session', );
    ok($resp->is_redirect, 'HTTP 302 response');
    my $redir_uri1 = $resp->header('location');
    diag("Redirected to $redir_uri1");
    like($redir_uri1, qr|http://localhost/show\?my_msg=\d{8}|, "Redirect URI");

    # Follow redirect to get the message
    my $resp2 = request($redir_uri1);
    ok($resp2->is_success, 'HTTP 200 response');
    is($resp2->content, "message: Test message\ntype: success\n\nmessage: Test message\ntype: danger\n\n", 'Check messages with session');

    # Make sure we don't get it twice
    is(get($redir_uri1), 'NA', 'Message gone on second access');
}

{
    # Message with stash
    my $resp = request('/with_stash');
    ok($resp->is_success, 'HTTP 200 response');
    is($resp->content, "message: Test message\ntype: info\n\nmessage: Test message\ntype: warning\n\n", 'Check messages with stash');
    
    # Make sure we don't get it twice
    is(get('/show'), 'NA', 'Message gone on second access');    
}

{
    # Message with session and stash
    my $resp = request('/with_session?redir=with_stash', );
    ok($resp->is_redirect, 'HTTP 302 response');
    my $redir_uri1 = $resp->header('location');
    diag("Redirected to $redir_uri1");
    like($redir_uri1, qr|http://localhost/with_stash\?my_msg=\d{8}|, "Redirect URI");

    # Follow redirect to get the message
    my $resp2 = request($redir_uri1);
    ok($resp2->is_success, 'HTTP 200 response');
    is($resp2->content, "message: Test message\ntype: info\n\nmessage: Test message\ntype: warning\n\nmessage: Test message\ntype: success\n\nmessage: Test message\ntype: danger\n\n", 'Check messages with session and stash');

    # Make sure we don't get it twice
    is(get('/show'), 'NA', 'Message gone on second access');
}

done_testing();
