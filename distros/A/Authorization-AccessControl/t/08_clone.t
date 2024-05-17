use v5.26;
use warnings;

use Test2::V0;

use experimental qw(signatures);

use Authorization::AccessControl qw(acl);

my $log = [];

acl->role('admin')->grant(User => 'edit')->grant(User => 'delete')->role->grant(Book => 'read');

acl->hook(on_permit => sub ($grant) {push($log->@*, {status => 'permit', grant => "$grant"})});
acl->hook(on_deny   => sub ($req) {push($log->@*, {status => 'deny', req => "$req"})});

is(acl->request->with_resource('Book')->with_action('delete')->permitted, !1, 'no grant for book delete');

is($log, [{status => 'deny', req => 'Book => delete()'}], 'confirm on_deny hook');

my $custom = acl->clone;

$custom->grant(Book => 'delete');

is(acl->request->with_resource('Book')->with_action('delete')->permitted,     !1, 'check custom not added to original acl');
is($custom->request->with_resource('Book')->with_action('delete')->permitted, !0, 'check grant added to custom acl');

is($log->[2], {status => 'permit', grant => 'Book => delete()'}, 'confirm hook ran in cloned acl');

done_testing;
