use strict;
use warnings FATAL => 'all';

use Test::More tests => 55;
use Apache::SWIT::Security::Test qw(Is_URL_Secure);
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('T::Test'); }

my $t = T::Test->new;
$t->reset_db;

$t->ok_ht_login_r(make_url => 1, ht => { username => '', password => '' });
$t->ht_login_u(ht => { username => 'admin', password => 'password' });
$t->ok_ht_result_r(ht => { username => 'admin' });

$t->ok_follow_link(text => 'Add more users');
$t->ok_ht_userform_r(ht => { username => '', password => '', });
$t->with_or_without_mech_do(9, sub {
	unlike($t->mech->content, qr/The name cannot be empty/);
	$t->ht_userform_u(ht => { username => '', password => 'p'
			, password2 => 'p' });
	$t->ok_ht_userform_r(ht => { username => '', password => 'p', });
	like($t->mech->content, qr/The name cannot be empty/);

	unlike($t->mech->content, qr/The password cannot be empty/);
	unlike($t->mech->content, qr/The confirmation password/);
	$t->ht_userform_u(ht => { username => 'fooo', password => ''
			, password2 => '' });
	like($t->mech->content, qr/The password cannot be empty/);
	like($t->mech->content, qr/The confirmation password cannot be empty/);

	unlike($t->mech->content, qr/The passwords do not match/);
	$t->ht_userform_u(ht => { username => 'fooo', password => 'p'
			, password2 => 'x' });
	like($t->mech->content, qr/The passwords do not match/);
});

$t->ht_userform_u(ht => { username => 'user', password => 'p'
		, password2 => 'p' });

$t->ok_ht_login_r(make_url => 1, ht => { username => '', password => '' });
$t->ht_login_u(ht => { username => 'user', password => 'p' });
$t->ok_ht_result_r(ht => { username => 'user' });

$t->with_or_without_mech_do(8, sub {
	is($t->mech->follow_link(text => 'Add more users'), undef);
	is($t->mech->follow_link(text => 'User Role List'), undef);
	ok(Is_URL_Secure($t, $_)) for map { ("$_/r", "$_/u") }
		qw(userform userlist userrolelist);
});

$t->ok_ht_login_r(make_url => 1, ht => { username => '', password => '' });
$t->ht_login_u(ht => { username => 'admin', password => 'password' });
$t->ok_ht_result_r(ht => { username => 'admin' });

$t->ok_follow_link(text => 'User Role List');
$t->ok_ht_userrolelist_r(ht => { user_list => [
	{ HT_SEALED_ht_id => '1', name => 'admin', role_name => 'admin'
		, HT_SEALED_role_id => 1 }
	, { HT_SEALED_ht_id => '2', name => 'user', role_name => ''
		, HT_SEALED_role_id => '' }
] });

$t->ok_ht_result_r(make_url => 1, ht => { username => 'admin' });
$t->ok_follow_link(text => 'Logout');
$t->ok_ht_login_r(param => { logout => 'admin' }
		, ht => { username => '', password => '', logout => 'admin' });

$t->with_or_without_mech_do(2, sub {
	like($t->mech->content, qr/admin.*logged out/);
	$t->ht_userform_r(make_url => 1);
	is($t->mech->status, 403);
});

$t->ok_ht_login_r(make_url => 1, ht => { username => '', password => '' });
$t->ht_login_u(ht => { username => 'admin', password => 'password' });
$t->ok_ht_result_r(ht => { username => 'admin' });

$t->ok_ht_userprofile_r(make_url => 1, param => { HT_SEALED_user_id => 1 }
	, ht => { name => 'admin', old_password => '', new_password => ''
		, new_password_confirm => '' });
$t->with_or_without_mech_do(4, sub {
	$t->ht_userprofile_u(ht => {
		HT_SEALED_user_id => 1, old_password => 'p', new_password => 'h'
		, new_password_confirm => 'h'
	});

	$t->ok_ht_userprofile_r(param => { HT_SEALED_user_id => 1 }
		, ht => { name => 'admin', old_password => 'p'
			, new_password => 'h'
			, new_password_confirm => 'h' });
	like($t->mech->content, qr/Wrong password/);

	$t->ht_userprofile_u(ht => {
		HT_SEALED_user_id => 1, old_password => 'password'
		, new_password => 'h2'
		, new_password_confirm => 'h'
	});

	$t->ok_ht_userprofile_r(param => { HT_SEALED_user_id => 1 }
		, ht => { name => 'admin', old_password => 'password'
			, new_password => 'h2'
			, new_password_confirm => 'h' });
	like($t->mech->content, qr/Passwords do not match/);
});

$t->ht_userprofile_u(ht => {
	HT_SEALED_user_id => 1, old_password => 'password'
	, new_password => 'h2', name => ''
	, new_password_confirm => 'h2'
}, $t->mech ? () : (error_ok => 1));

$t->with_or_without_mech_do(7, sub {
	$t->ok_ht_userprofile_r(param => { HT_SEALED_user_id => 1 }
		, ht => { name => '', old_password => 'password'
			, new_password => 'h2'
			, new_password_confirm => 'h2' });
	like($t->mech->content, qr/The name cannot be empty/);
	unlike($t->mech->content, qr/The password cannot be empty/);

	$t->ht_userprofile_u(ht => {
		HT_SEALED_user_id => 1, old_password => ''
		, new_password => '', name => 'fooo'
		, new_password_confirm => ''
	});

	$t->ok_ht_userprofile_r(param => { HT_SEALED_user_id => 1 }
		, ht => { name => 'fooo', old_password => ''
			, new_password => '', new_password_confirm => '' });
	like($t->mech->content, qr/The password cannot be empty/);
	like($t->mech->content, qr/New password cannot be empty/);
	like($t->mech->content, qr/Confirmation password cannot be empty/);
});

$t->ht_userprofile_u(ht => {
	HT_SEALED_user_id => 1, old_password => 'password'
	, new_password => 'h2', name => 'admin2'
	, new_password_confirm => 'h2'
});

$t->ok_ht_userprofile_r(param => { HT_SEALED_user_id => 1 }
	, ht => { name => 'admin2', old_password => ''
		, new_password => ''
		, new_password_confirm => '' });

$t = T::Test->new;
$t->ok_ht_login_r(make_url => 1, ht => { username => '', password => '' });
$t->ht_login_u(ht => { username => 'admin2', password => 'h2' });
$t->ok_ht_result_r(ht => { username => 'admin2' });

$t = T::Test->new;
$t->ok_ht_login_r(make_url => 1, ht => { username => '', password => '' });
$t->ht_login_u(ht => { username => 'user', password => 'p' });
$t->ok_ht_result_r(ht => { username => 'user' });

$t->ok_ht_userprofile_r(make_url => 1, param => { HT_SEALED_user_id => 2 }
	, ht => { name => 'user', old_password => '', new_password => ''
		, new_password_confirm => '' });

$t->ok_ht_userprofile_r(make_url => 1
	, param => { HT_SEALED_user_id => 1 }
	, ht => { HT_NO_name => 'admin2' });
$t->with_or_without_mech_do(1, sub { is($t->mech->status, 403); });
