#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN {
    use_ok('TestChained');
}

use Catalyst::Test 'TestChained';


my ($expect, $query, $resp, $user, $uid, $pwd);

my ($res, $c) = ctx_request('/');

$user = $c->user;
$user->supports(qw/roles/);


$user->id('jrandomuser');

# request chained action:
# first action in chain requires role 'admin',
# second action requires role 'superuser',
# third and final action requires role 'editor'.

$query = '/stage1/stage2/edit';

$user->roles(qw/admin/);
$resp = request($query);
ok($resp->code == 403, "fetch $query 403 Forbidden");
is($resp->content, 'access denied', "content correct");

$user->roles(qw/admin superuser/);
$resp = request($query);
ok($resp->code == 403, "fetch $query 403 Forbidden");
is($resp->content, 'access denied', "content correct");

$user->roles(qw/admin superuser editor/);
$resp = request($query);
ok($resp->code == 200, "fetch $query 200 OK");
$expect = '-stage1-stage2-edit';
is($resp->content, $expect, "content correct: $expect");

