#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN {
    use_ok('TestCanVisit');
}

use Catalyst::Test 'TestCanVisit';

my ($action, $query, $resp, $user, $uid, $pwd);

my ($res, $c) = ctx_request('/');

$user = $c->user;
$user->supports(qw/roles/);

$user->id('jrandomuser');

$query = '/access?action_name=';

$user->roles(qw/user/);
$action = 'edit';
$resp = get($query.$action);
is($resp, 'no', "user cannot visit 'edit'");

$user->roles(qw/admin/);
$action = 'edit';
$resp = get($query.$action);
is($resp, 'yes', "user can visit 'edit'");

$user->roles(qw/admin/);
$action = 'read';
$resp = get($query.$action);
is($resp, 'no', "user cannot visit 'read'");

$user->roles(qw/user/);
$action = 'read';
$resp = get($query.$action);
is($resp, 'yes', "user can visit 'read'");

