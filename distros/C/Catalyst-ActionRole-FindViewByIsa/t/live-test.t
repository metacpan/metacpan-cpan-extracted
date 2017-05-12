#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# a live test against TestApp, the test application
use Catalyst::Test 'TestApp';

my ($res, $c);
($res, $c) = ctx_request('/');
is $c->res->body, 'Processed by view TestApp::View::D', 'Default ok';

($res, $c) = ctx_request('/viewa');
is $c->res->body, 'Processed by view TestApp::View::A', 'Find view A ok';

($res, $c) = ctx_request('/viewb');
is $c->res->body, 'Processed by view TestApp::View::B', 'Find view B ok';

($res, $c) = ctx_request('/override');
is $c->res->body, 'Processed by view TestApp::View::C',
    '$c->stash->{current_view} set overrides';

