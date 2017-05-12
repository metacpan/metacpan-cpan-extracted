use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::WWW::Mechanize::Catalyst;

my $m = new Test::WWW::Mechanize::Catalyst catalyst_app => 'TestApp';

# issue a request for / without setting any headers

{
	$m->get_ok('/');
}

# issue a request for /, providing the user header, but no role headers

{
	my $res = $m->get('/', 'X-Catalyst-Credential-Upstream-User' => 'bob');

	my ($has_user, $username, $roles) = split /\n/, $res->content;

	cmp_ok $has_user,	'==', 1,		'user object exists';
	cmp_ok $username,	'eq', 'bob',	'user name is bob';
	cmp_ok $roles,		'eq', '',		'user has no roles';
}

# issue a request for /, providing the user and role headers

{
	my $res = $m->get('/', 'X-Catalyst-Credential-Upstream-User' => 'bob', 'X-Catalyst-Credential-Upstream-Roles' => 'user|admin|tester');

	my ($has_user, $username, $roles) = split /\n/, $res->content;

	cmp_ok $has_user,	'==', 1,					'user object exists';
	cmp_ok $username,	'eq', 'bob',				'user name is bob';
	cmp_ok $roles,		'eq', 'admin;tester;user',	'user has three roles';
}

# test that authorization works

$m->get_ok('/protected', { 'X-Catalyst-Credential-Upstream-User' => 'bob', 'X-Catalyst-Credential-Upstream-Roles' => 'user|tester' });
$m->get_ok('/admin', { 'X-Catalyst-Credential-Upstream-User' => 'bob', 'X-Catalyst-Credential-Upstream-Roles' => 'admin' });

ok not $m->get('/protected', { 'X-Catalyst-Credential-Upstream-User' => 'bob' })->is_success;
ok not $m->get('/protected', { 'X-Catalyst-Credential-Upstream-User' => 'bob', 'X-Catalyst-Credential-Upstream-Roles' => 'tester' })->is_success;
ok not $m->get('/protected', { 'X-Catalyst-Credential-Upstream-User' => 'bob', 'X-Catalyst-Credential-Upstream-Roles' => 'user' })->is_success;
ok not $m->get('/admin', { 'X-Catalyst-Credential-Upstream-User' => 'bob', 'X-Catalyst-Credential-Upstream-Roles' => 'user|tester' })->is_success;

done_testing;

