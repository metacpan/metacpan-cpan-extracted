#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 21;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN {
    use_ok('TestApp');
}

use Catalyst::Test 'TestApp';

my ($query, $resp, $user, $uid, $pwd);

my ($res, $c) = ctx_request('/');

$user = $c->user;
$user->supports(qw/roles/);


$user->id('jrandomuser');
$user->roles(qw/delete editor/);

$query = '/edit';
$resp = request($query);
ok($resp->code == 200, "fetch $query 200 OK");
is($resp->content, 'action: edit', "content correct");

$query = '/killit';
$resp = request($query);
ok($resp->code == 403, "fetch $query 403 Forbidden");
is($resp->content, 'access denied', "content correct");

$query = '/crews';
$resp = request($query);
ok($resp->code == 403, "fetch $query 403 Forbidden");
is($resp->content, 'access denied', "content correct");

# add the required role (banana) so user can visit the action
$user->roles(qw/delete editor banana/);

$query = '/crews?someparm=42';
$resp = request($query);
ok($resp->code == 200, "fetch $query 200 OK");
is($resp->content, 'action: crews', "content correct");

# /reese' ACL permits users with either 'sarah' or 'shahi' role
$query = '/reese';
$resp = request($query);
ok($resp->code == 403, "fetch $query 403 Forbidden");
is($resp->content, 'access denied', "content correct");

# add one of the AllowedRole roles (sarah) so user can visit the action
$user->roles(qw/delete editor banana sarah/);
$resp = request($query);
ok($resp->code == 200, "fetch $query 200 OK");
is($resp->content, 'action: reese', "content correct");

# remove all roles, save one of the AllowedRole roles
$user->roles('shahi');
ok($resp->code == 200, "fetch $query 200 OK");
is($resp->content, 'action: reese', "content correct");

# action requires role 'swayze' and at least one of 'actor'
# or 'guerilla'
$query = '/wolverines?attacker=spetznatz';
$resp = request($query);
ok($resp->code == 403, "fetch $query 403 Forbidden");
is($resp->content, 'access denied', "content correct");
# give user the RequiresRole role
$user->roles($user->roles, 'swayze');
# request should fail because AllowedRole still not satisfied
ok($resp->code == 403, "fetch $query 403 Forbidden");
is($resp->content, 'access denied', "content correct");
# give user one of the AllowedRoles roles
$user->roles($user->roles, 'actor');
$resp = request($query);
ok($resp->code == 200, "fetch $query 200 OK");
is($resp->content, 'action: wolverines', "content correct");

