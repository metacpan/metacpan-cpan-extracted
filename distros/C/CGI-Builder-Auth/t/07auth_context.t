# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 36;

BEGIN { 
	unlink('.htpasswd');
	unlink('.htgroup');
	use_ok('CGI::Builder::Auth::Context');
};

# TODO Ensure database from previous test is cleaned up

# TODO Get an auth object from somewhere reasonable
my ($user, $auth, @users, %users, @groups, %groups);

$auth = CGI::Builder::Auth::Context->new;
isa_ok($auth, 'CGI::Builder::Auth::Context', 	'$auth');

isa_ok($auth->user, 'CGI::Builder::Auth::User', '$user');
is($auth->user,  'anonymous',	"user defaults to 'anonymous'.");
is($auth->realm, 'main', 		"realm defaults to 'main'.");

ok(!$auth->user_list, 		"user_list initially empty.");
ok(!$auth->group_list, 		"group_list initially empty.");

ok(!$auth->require_valid_user, 			"require_valid_user false when not logged in.");
ok(!$auth->require_group('testgroup'), 	"require_group false when not logged in.");
ok(!$auth->require_user('bob'), 		"require_user false when not logged in.");

ok($auth->add_group('testgroup'), 	"group added");
	
# 
# Explicit add_user with no (or blank) password, account should be created but
# suspended.
#
$user = $auth->add_user({ username => 'bob', password => ''});

#ok(!$auth->login($user, ''), 					'User with blank password cannot login');

# 
# Explicit add_user with password, account should be created and usable.
#
$user = $auth->add_user({ username => 'carol', password => 'password'});

isa_ok($user, 	'CGI::Builder::Auth::User', 	'add_user w/pass');
ok(!$auth->login($user, 'wrong'), 				'User cannot login with wrong password');
ok($auth->login($user, 'password'), 			'User can login with password');
is($auth->user, 'carol', 						'Property "user" set after login');


# 
# Authentication checks with user set
#
@users = $auth->user_list;
@groups = $auth->group_list;
%users = map { $_ => 1 } @users;

ok(%users,								"user_list not empty.");
ok($users{'bob'} && $users{'carol'},	"user_list complete.");
ok(@groups, 							"group_list not empty.");

ok($auth->require_valid_user, 			"require_valid_user true when logged in.");
ok(!$auth->require_group('testgroup'), 	"require_group false when user not a member.");
ok(!$auth->require_user('bob'), 		"require_user false when different user.");
ok($auth->require_user('carol'), 		"require_user true when true.");

# 
# Group Membership
#
ok($auth->add_member('testgroup', 'carol'), 	"add_member");
ok($auth->require_group('testgroup'), 			"require_group true when user is a member.");

$auth->add_member('testgroup', 'bob');
@users = $auth->group_members('testgroup');
%users = map { $_ => 1 } @users;

ok(%users,								"group_members not empty.");
ok($users{'bob'} && $users{'carol'},	"group_members complete.");

ok($auth->remove_member('testgroup', 'carol', 'bob'), 	"remove_member");
ok(!$auth->require_group('testgroup'), 					"require_group false when user not a member.");

@groups = $auth->group_list;
ok(@groups, 					"group_list not empty after emptying member list.");

# 
# Logging out
#

ok($auth->logout,				"logout");
is($auth->user,  'anonymous',	"user reverts to 'anonymous' after logout.");
ok(!$auth->require_valid_user, 	"require_valid_user false after logout.");

# 
# Deleting stuff
#

ok($auth->delete_group('testgroup'), 	"delete_group");
ok($auth->delete_user('bob'), 			"delete_user");
$auth->delete_user('carol');
ok(!$auth->user_list, 					"user_list empty.");
ok(!$auth->group_list, 					"group_list empty.");

# vim:ft=perl:tw=80:
