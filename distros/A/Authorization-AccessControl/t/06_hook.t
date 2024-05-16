use v5.26;
use warnings;

use Test2::V0;

use Authorization::AccessControl qw(acl);

use experimental qw(signatures);

acl->role("admin")->grant(Book => 'write');

my $r = [];

acl->hook(on_permit => sub ($ctx) {push($r->@*, 'success', ref($ctx))});
acl->hook(on_deny   => sub ($ctx) {push($r->@*, 'deny',    ref($ctx))});

acl->request->with_roles('admin')->with_resource('Book')->with_action('write')->permitted;
is($r, ['success', 'Authorization::AccessControl::Grant'], 'check on_permit');

$r = [];
acl->request->with_resource('Book')->with_action('write')->permitted;
is($r, ['deny', 'Authorization::AccessControl::Request'], 'check on_deny');

acl->hook(on_permit => sub ($ctx) {push($r->@*, 'double')});

$r = [];
acl->request->with_roles('admin')->with_resource('Book')->with_action('write')->permitted;
is($r, ['success', 'Authorization::AccessControl::Grant', 'double'], 'check multiple on_permit');

acl->hook(on_deny => sub ($ctx) {push($r->@*, 'elbuod')});

$r = [];
acl->request->with_resource('Book')->with_action('write')->permitted;
is($r, ['deny', 'Authorization::AccessControl::Request', 'elbuod'], 'check multiple on_deny');

done_testing;
