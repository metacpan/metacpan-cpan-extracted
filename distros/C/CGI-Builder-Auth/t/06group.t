# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 21;

BEGIN { 
	# Clean up from previous tests
	unlink('.htgroup.lock');
	unlink('.htgroup');
	use_ok('CGI::Builder::Auth::Group');
};
use CGI::Builder::Auth::User;
my ($user, $group, $group_factory, $user_factory, @users, %users, @groups, %groups);

$user_factory = CGI::Builder::Auth::User->new;

#-------------------------------------------------------------------- 
# Class Methods
#-------------------------------------------------------------------- 

isa_ok($group_factory = CGI::Builder::Auth::Group->new(), 'CGI::Builder::Auth::Group', 'Factory constructor new');
isa_ok($group_factory->_group_admin, 'CGI::Builder::Auth::GroupAdmin', '_group_admin');

@groups = $group_factory->list;
ok(!@groups,	'group_list initially empty');
# ok(!CGI::Builder::Auth::Group->exists('testgroup'), 	"exists class method");

$group = $group_factory->load(id => 'testgroup');
is($group, undef,  	'$group not constructed when does not exist');

#-------------------------------------------------------------------- 
# Add group
#-------------------------------------------------------------------- 
$group = $group_factory->add('testgroup');
isa_ok($group, 'CGI::Builder::Auth::Group', 	'$group');
ok($group_factory->load(id => 'testgroup'), "load after create");

#-------------------------------------------------------------------- 
# Object Methods
#-------------------------------------------------------------------- 

# ok($group->exists, "exists as object method");
is($group->id, 'testgroup', "id");


#-------------------------------------------------------------------- 
# List with multiple groups
#-------------------------------------------------------------------- 
$group = $group_factory->add('mygroup');

@groups = $group_factory->list;
%groups = map { $_ => 1 } @groups;
ok(@groups, 	"list");
ok($groups{'testgroup'} && $groups{'mygroup'},	"group_list complete.");


#-------------------------------------------------------------------- 
# Membership
#-------------------------------------------------------------------- 
$user = $user_factory->add({ username => 'bob', password => '1'});
$user_factory->add({ username => 'carol', password => '1'});

ok($group->add_member('bob'), 	'add_member as object method');
ok($group_factory->add_member('mygroup','carol'), 	'add_member as factory method');

@users = $group->member_list;
%users = map { $_ => 1 } @users;
ok($users{'bob'} && $users{'carol'},	"member_list complete.");

ok($group->remove_member('bob'), 	'remove_member as object method');
ok($group_factory->remove_member('mygroup','carol'), 	'remove_member as factory method');

@users = $group->member_list;
ok(!$group->member_list,	"removed members successfully");

#-------------------------------------------------------------------- 
# Add group that exists
#-------------------------------------------------------------------- 
$group = $group_factory->add('testgroup');
ok(!$group, 	"add fails when group exists");

#-------------------------------------------------------------------- 
# Delete
#-------------------------------------------------------------------- 
$group = $group_factory->load(id => 'testgroup');
ok($group->delete,	"delete as object method");
ok($group_factory->load(id => 'mygroup')->delete, 	"delete 'in place'");
ok(!$group_factory->list,	"groups deleted successfully");

$group = undef;
$group_factory = undef;
ok(!-f '.htgroup.lock', 	"Database unlocked when unused");

# vim:ft=perl:tw=80:
