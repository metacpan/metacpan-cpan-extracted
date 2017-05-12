#!/usr/bin/perl

use warnings;
use strict;

my $res;
use Test::More tests => 8;
#use Test::More 'no_plan';
use Apache2::AuthAny::DB();

BEGIN {
    use_ok('Apache2::AuthAny::DB');
};

my $aaDB = Apache2::AuthAny::DB->new();

ok($aaDB, "Apache2::AuthAny::DB->new()");

my $uniq = time() . $$;
my $username = "test_user_$uniq";
my $new_uid = $aaDB->addUser(
                               username => $username,
                               organization => 'test_org',
                               firstName => 'test_user_firstName',
                               active => 1,
                              );
ok($new_uid, "Create a user; UID: '$new_uid'");

warn "\n";
my $dup_uid = $aaDB->addUser(
                               username => $username,
                               organization => 'test_org',
                               firstName => 'test_user_firstName',
                               active => 1,
                              );

is($dup_uid, undef, "Try to create a duplicate user");

# create identities for this user
my $uw_ident         = $username . '@washington.edu';
my $protectnet_ident = $username . '@idp.protectnetwork.org';

$res = $aaDB->addUserIdent($new_uid, $uw_ident, 'uw');
ok($res, "Identity for $username at uw");

$res = $aaDB->addUserIdent($new_uid, $protectnet_ident, 'protectnet');
ok($res, "Identity for $username at protectnet");

warn "\n";
my $dup_res = $aaDB->addUserIdent($new_uid, $protectnet_ident, 'protectnet');
is($dup_res, undef, "Try to create a duplicate identity for $username at protectnet");

# add roles
$res = $aaDB->addUserRole($new_uid, 'contributor');
ok($res, "Contributor role added");
