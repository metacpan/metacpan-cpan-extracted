#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';

{
    local *TestApp::debug = sub { 0 };
    my $res = request('/');
    ok $res->is_success;
    like $res->content, qr/dump_info=1/;
    ok request($res->content)->is_success;
}
{
    local *TestApp::debug = sub { 1 };
    my $res = request('/');
    ok $res->is_success;
    like $res->content, qr/dump_info=1/;
    ok !request($res->content)->is_success;
}
{
    local *TestApp::debug = sub { 0 };
    my $res = request('/foo/222');
    ok $res->is_success, 'success';
    like $res->content, qr/dump_info=1/;
    like $res->content, qr/bar=baz/;    
}

done_testing;
