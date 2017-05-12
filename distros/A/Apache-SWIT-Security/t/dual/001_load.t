use strict;
use warnings FATAL => 'all';

use Test::More tests => 19;
use Carp;

BEGIN {
	# $SIG{__DIE__} = sub { diag(Carp::longmess(@_)); };
	use_ok('T::Test');
};

my $t = T::Test->new;
$t->reset_db;

$t->with_or_without_mech_do(1, sub {
	$t->ht_userform_r(make_url => 1);
	is($t->mech->status, 403);
});

$t->ok_ht_login_r(make_url => 1, ht => { username => '', password => '' });
$t->ht_login_u(ht => { username => 'stranger', password => '1234' });
$t->ok_ht_login_r(ht => { username => 'stranger', password => '', 
				failed => 'f' });

$t->ht_login_u(ht => { username => undef });
$t->ok_ht_login_r(ht => { username => '', password => '', failed => 'f' });

$t->ht_login_u(ht => { username => 'admin', password => 'password' });
$t->ok_ht_result_r(ht => { username => 'admin' });
$t->ok_ht_result_r(make_url => 1, ht => { username => 'admin' });

$t->ok_ht_userlist_r(make_url => 1, ht => { 
		user_list => [ { HT_SEALED_ht_id => 1, name => 'admin' } ] });

$t->ok_ht_userform_r(make_url => 1, ht => { 
		username => '', password => '', password2 => '' });

$t->with_or_without_mech_do(2, sub {
	$t->ht_userform_u(ht => { username => 'user', password => 'p'
			, password2 => 'd' });
	$t->ok_ht_userform_r(ht => { 
		username => 'user', password => 'p', password2 => 'd' });
	like($t->mech->content, qr/passwords do not match/);
});

$t->ht_userform_u(ht => { username => 'user', password => 'p'
		, password2 => 'p' });

$t->ok_ht_userlist_r(ht => { user_list => [ 
		{ HT_SEALED_ht_id => 1, check => [ 1 ], name => 'admin' }, 
		{ HT_SEALED_ht_id => 2, check => [ 1 ], name => 'user' } 
] });

$t->ht_userlist_u(ht => { user_list => [ { HT_SEALED_ht_id => 1 }, {
				HT_SEALED_ht_id => 2, check => 1, } ] });
$t->ok_ht_userlist_r(ht => { user_list => [ 
		{ HT_SEALED_ht_id => 1, check => [ 1 ], name => 'admin' }, 
] });

$t->ok_ht_userrolelist_r(make_url => 1, ht => { user_list => [
	{ HT_SEALED_ht_id => '1', name => 'admin', role_name => 'admin'
		, HT_SEALED_role_id => 1 } ]
});

$t->ok_ht_userlist_r(make_url => 1, ht => { 
	role_sel => [ [ 0, 'Select Role' ], [ 1, 'admin' ], [ 2, 'user' ] ],
	user_list => [ { HT_SEALED_ht_id => 1, name => 'admin' } ] });

$t->ht_userlist_u(ht => { user_list => [ { HT_SEALED_ht_id => 1, check => 1 } ]
		, role_sel => 2 });

$t->ok_ht_userrolelist_r(ht => { user_list => [
	{ HT_SEALED_ht_id => '1', name => 'admin', role_name => 'admin', 
			, HT_SEALED_role_id => 1, check => [ 1 ] },
	{ HT_SEALED_ht_id => '1', name => 'admin', role_name => 'user'
			, HT_SEALED_role_id => 2, check => [ 1 ] },
] });

$t->ht_userrolelist_u(ht => { user_list => [
	{ HT_SEALED_ht_id => 1, HT_SEALED_role_id => 1 }
	, { HT_SEALED_ht_id => 1, HT_SEALED_role_id => 2, check => [ 1 ] }
] });

$t->ok_ht_userrolelist_r(ht => { user_list => [
	{ HT_SEALED_ht_id => 1, name => 'admin', role_name => 'admin'
		, HT_SEALED_role_id => 1, check => [ 1 ] },
] });

$t->ok_ht_login_r(make_url => 1, param => { redirect => "../userrolelist/r" }
		, ht => { username => '', password => '' });
$t->ht_login_u(ht => { username => 'admin', password => 'password' });
$t->ok_ht_userrolelist_r(ht => { user_list => [
	{ HT_SEALED_ht_id => 1, name => 'admin', role_name => 'admin'
		, HT_SEALED_role_id => 1, check => [ 1 ] },
] });

