#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use Catalyst::Test 'TestAppAltRoot';
{
    my ($res, $ctx) = ctx_request('/');
    ok $res->is_success;
    ok $ctx->res->body =~ m|Hello <span id="name">Dave</span>|;
}


done_testing;
