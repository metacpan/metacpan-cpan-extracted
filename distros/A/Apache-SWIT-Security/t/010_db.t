use strict;
use warnings FATAL => 'all';

use Test::More tests => 22;
use T::TempDB;
use Apache::SWIT::Security qw(Hash);

BEGIN { use_ok('T::Test'); }

my @users = Apache::SWIT::Security::DB::User->retrieve_all;
is(scalar(@users), 1);
is($users[0]->name, 'admin');
local $ENV{AS_SECURITY_SALT} = 'ajweqwe';
is($users[0]->password, Hash('password'));
is_deeply([ $users[0]->role_ids ], [ 1 ]);

my $u = Apache::SWIT::Security::DB::User->create({
		name => 'another',
		password => 'p' });
ok($u);
is_deeply([ $u->role_ids ], []);

$u->add_role_id(2);
is_deeply([ $u->role_ids ], [ 2 ]);

$u->add_role_id(1);
is_deeply([ sort $u->role_ids ], [ 1, 2 ]);

eval { $u->add_role_id(3) };
like($@, qr/valid_role_id_chk/);
is_deeply([ sort $u->role_ids ], [ 1, 2 ]);

$u->delete_role_id(1);
is_deeply([ $u->role_ids ], [ 2 ]);

$u->add_role_id(1);
is_deeply([ sort $u->role_ids ], [ 1, 2 ]);

@users = sort { $a->id <=> $b->id || $a->role_id <=> $b->role_id }
		Apache::SWIT::Security::DB::User->search_all_with_roles;
is(scalar(@users), 3);
is($users[0]->name, 'admin');
is($users[1]->name, 'another');
is($users[1]->role_id, 1);
is($users[2]->role_id, 2);

@users = sort { $a->id <=> $b->id || $a->role_id <=> $b->role_id }
		Apache::SWIT::Security::DB::User->search_all_with_roles;
is(scalar(@users), 3);
is($users[2]->role_id, 2);
ok($users[2]->delete);

eval { $users[0]->add_role_id(1); };
like($@, qr/user_roles_pk/);
