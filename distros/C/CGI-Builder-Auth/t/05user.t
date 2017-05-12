# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 22;

BEGIN { 
	# Clean up from previous tests
	unlink('.htpasswd.lock');
	unlink('.htpasswd');
	use_ok('CGI::Builder::Auth::User');
};

my ($user, $user2, $user_factory, @users, %users, @groups, %groups);

#-------------------------------------------------------------------- 
# Factory Methods
#-------------------------------------------------------------------- 
isa_ok($user_factory = CGI::Builder::Auth::User->new(), 'CGI::Builder::Auth::User', 'Factory constructor new');
isa_ok($user_factory->_user_admin, 'CGI::Builder::Auth::UserAdmin', '_user_admin');

@users = $user_factory->list;
ok(!@users,	'user_list initially empty');
# ok(!CGI::Builder::Auth::User->exists('bob'), 	"exists class method");

$user = $user_factory->load(id => 'bob');
is($user, undef,  	'$user not constructed when does not exist');

$user = $user_factory->anonymous;
is($user, 'anonymous',  'can create anonymous user');

#-------------------------------------------------------------------- 
# Add user
#-------------------------------------------------------------------- 
$user = $user_factory->add({username => 'bob', password => 'password'});
isa_ok($user, 'CGI::Builder::Auth::User', 	'$user');
ok($user_factory->load(id => 'bob'), "load after create");

#-------------------------------------------------------------------- 
# Object Methods
#-------------------------------------------------------------------- 

# ok($user->exists, "exists as object method");
is($user->id, 'bob', "id");


#-------------------------------------------------------------------- 
# List with multiple users
#-------------------------------------------------------------------- 
$user = $user_factory->add({username => 'carol', password => 'password'});

@users = $user_factory->list;
%users = map { $_ => 1 } @users;
ok(@users, 	"list");
ok($users{'bob'} && $users{'carol'},	"user_list complete.");


#-------------------------------------------------------------------- 
# Passwords and Suspend
#-------------------------------------------------------------------- 
ok($user->password_matches('password'), 	'password matches');
ok($user->suspend, 	'suspend');
ok(!$user->password_matches('password'), 	'password does not match when suspended');
ok($user->unsuspend, 	'unsuspend');
ok($user->password_matches('password'), 	'password matches after unsuspend');

#-------------------------------------------------------------------- 
# Add user should fail in these cases
#-------------------------------------------------------------------- 
$user = $user_factory->add({username => 'bob', password => 'password'});
ok(!$user, 	"add fails when user exists");

$user = $user_factory->add({username => 'anonymous', password => 'password'});
ok(!$user, 	"cannot 'add' anonymous user");

#-------------------------------------------------------------------- 
# Delete
#-------------------------------------------------------------------- 
$user = $user_factory->load(id => 'bob');
ok($user->delete,	"delete as object method");
ok($user_factory->load(id => 'carol')->delete, 	"delete 'in place'");
ok(!$user_factory->list,	"users deleted successfully");

$user = undef;
$user_factory = undef;
ok(!-f '.htpasswd.lock',	"Database unlocked when unused");

# vim:ft=perl:tw=80:
