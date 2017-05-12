#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use Catalyst::Test 'TestApp';
{
    my ($res, $ctx) = ctx_request('/');
    ok $res->is_success;
    ok $ctx->res->body =~ m|Hello <span id="name">Dave</span>|;
}

{
    my ($res, $ctx) = ctx_request('/foo/bar');
    ok $res->is_success;
    ok $ctx->res->body =~ m|Hello my name is <span id="name">Foo Foo</span>|;
}

{
    my ($res, $ctx) = ctx_request('/direct_render');
    ok $res->is_success;
    ok $ctx->res->body =~ m|Hello <span id="name">Dave</span>|;
}

{
    my ($res, $ctx) = ctx_request('/name_zaction');
    ok $res->is_success;
    ok $ctx->res->body =~ m|Hello <span id="name">Dave</span>|;
}

{
    my ($res, $ctx) = ctx_request('/foo/name_zaction_class');
    ok $res->is_success;
    ok $ctx->res->body =~ m|Hello <span id="name">Dave</span>|;
}

{
    my ($res, $ctx) = ctx_request('/foo/name_zaction_class_short');
    ok $res->is_success;
    ok $ctx->res->body =~ m|Hello <span id="name">Dave</span>|;
}

{
    my ($res, $ctx) = ctx_request('/inlined_action');
    ok $res->is_success;
    ok $ctx->res->body =~ m|Hello <span id="name">John</span>|;
}

done_testing;
