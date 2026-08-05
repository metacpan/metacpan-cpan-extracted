#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;
use File::Temp qw(tempdir);

use Concierge::Desk::Setup;
use Concierge;

# Setup test desk
my $test_dir = tempdir(CLEANUP => 1);

Concierge::Desk::Setup::build_quick_desk($test_dir, ['theme', 'role']);
my $desk = Concierge->open_desk($test_dir);
my $concierge = $desk->{concierge};

subtest 'add_user basic functionality' => sub {
    my $result = $concierge->add_user({
        user_id  => 'alice',
        moniker  => 'Alice',
        email    => 'alice@example.com',
        password => 'secret123',
        theme    => 'dark',
    });

    ok $result->{success}, 'add_user succeeds';
    is $result->{user_id}, 'alice', 'returns user_id';
};

subtest 'add_user validates required fields' => sub {
    # Missing user_id
    my $result = $concierge->add_user({
        moniker  => 'NoId',
        password => 'pass1234',
    });
    ok !$result->{success}, 'fails without user_id';

    # Missing moniker
    $result = $concierge->add_user({
        user_id  => 'nomon',
        password => 'pass1234',
    });
    ok !$result->{success}, 'fails without moniker';

    # Missing password
    $result = $concierge->add_user({
        user_id => 'nopass',
        moniker => 'NoPass',
    });
    ok !$result->{success}, 'fails without password';
};

subtest 'add_user prevents duplicates' => sub {
    $concierge->add_user({
        user_id  => 'duplicate',
        moniker  => 'Dup',
        password => 'pass1234',
    });

    my $result = $concierge->add_user({
        user_id  => 'duplicate',
        moniker  => 'Dup2',
        password => 'pass4567',
    });

    ok !$result->{success}, 'fails on duplicate user_id';
};

subtest 'verify_user checks existence' => sub {
    my $result = $concierge->verify_user('alice');

    ok $result->{success}, 'verify_user succeeds';
    ok $result->{verified}, 'user is verified';
    ok $result->{exists_in_auth}, 'exists in auth';
    ok $result->{exists_in_users}, 'exists in users';
};

subtest 'verify_user detects missing user' => sub {
    my $result = $concierge->verify_user('nonexistent');

    ok $result->{success}, 'verify_user call succeeds';
    ok !$result->{verified}, 'user not verified';
    ok !$result->{exists_in_auth}, 'not in auth';
    ok !$result->{exists_in_users}, 'not in users';
};

subtest 'get_user_data retrieves user info' => sub {
    my $result = $concierge->get_user_data('alice');

    ok $result->{success}, 'get_user_data succeeds';
    is $result->{user}{user_id}, 'alice', 'user_id correct';
    is $result->{user}{moniker}, 'Alice', 'moniker correct';
    is $result->{user}{email}, 'alice@example.com', 'email correct';
    is $result->{user}{theme}, 'dark', 'custom field correct';
    ok !exists $result->{user}{password}, 'password not in user data';
};

subtest 'get_user_data with field selection' => sub {
    my $result = $concierge->get_user_data('alice', 'moniker', 'email');

    ok $result->{success}, 'get_user_data with fields succeeds';
    is $result->{user}{moniker}, 'Alice', 'moniker returned';
    is $result->{user}{email}, 'alice@example.com', 'email returned';
    ok !exists $result->{user}{theme}, 'theme not returned';
};

subtest 'update_user_data modifies user' => sub {
    my $result = $concierge->update_user_data('alice', {
        theme => 'light',
        role  => 'admin',
    });

    ok $result->{success}, 'update_user_data succeeds';

    # Verify changes
    my $check = $concierge->get_user_data('alice');
    is $check->{user}{theme}, 'light', 'theme updated';
    is $check->{user}{role}, 'admin', 'role updated';
};

subtest 'update_user_data filters protected fields' => sub {
    my $result = $concierge->update_user_data('alice', {
        user_id  => 'hacker',  # Should be filtered out
        password => 'newpass',  # Should be filtered out
        theme    => 'blue',
    });

    ok $result->{success}, 'update succeeds';

    # Verify user_id didn't change
    my $check = $concierge->get_user_data('alice');
    is $check->{user}{user_id}, 'alice', 'user_id unchanged';
    is $check->{user}{theme}, 'blue', 'theme updated';
};

subtest 'list_users returns user_ids' => sub {
    # Add another user
    $concierge->add_user({
        user_id  => 'bob',
        moniker  => 'Bob',
        password => 'bobpass1',
    });

    my $result = $concierge->list_users();

    ok $result->{success}, 'list_users succeeds';
    ref_ok $result->{user_ids}, 'ARRAY', 'user_ids is array';
    ok $result->{count} >= 2, 'has multiple users';
    ok scalar(grep { $_ eq 'alice' } @{$result->{user_ids}}), 'alice in list';
    ok scalar(grep { $_ eq 'bob' } @{$result->{user_ids}}), 'bob in list';
};

subtest 'list_users with include_data' => sub {
    my $result = $concierge->list_users('', { include_data => 1 });

    ok $result->{success}, 'list_users with data succeeds';
    ref_ok $result->{users}, 'HASH', 'users is hash';
    ok exists $result->{users}{alice}, 'alice data included';
    is $result->{users}{alice}{moniker}, 'Alice', 'alice data correct';
};

subtest 'verify_password checks credentials' => sub {
    my $result = $concierge->verify_password('alice', 'secret123');
    ok $result->{success}, 'correct password verified';

    $result = $concierge->verify_password('alice', 'wrongpass');
    ok !$result->{success}, 'incorrect password rejected';
};

subtest 'reset_password changes password' => sub {
    my $result = $concierge->reset_password('alice', 'newsecret456');
    ok $result->{success}, 'reset_password succeeds';

    # Verify old password doesn't work
    my $check = $concierge->verify_password('alice', 'secret123');
    ok !$check->{success}, 'old password rejected';

    # Verify new password works
    $check = $concierge->verify_password('alice', 'newsecret456');
    ok $check->{success}, 'new password accepted';
};

subtest 'remove_user deletes from all components' => sub {
    # Create and login user to create session
    $concierge->add_user({
        user_id  => 'removeme',
        moniker  => 'RemoveMe',
        password => 'temppass1',
    });

    $concierge->login_user({
        user_id  => 'removeme',
        password => 'temppass1',
    });

    # Remove user
    my $result = $concierge->remove_user('removeme');

    ok $result->{success}, 'remove_user succeeds';
    like $result->{message}, qr/removed/i, 'success message';

    # Verify user is gone from all components
    my $verify = $concierge->verify_user('removeme');
    ok !$verify->{verified}, 'user no longer verified';
    ok !$verify->{exists_in_auth}, 'removed from auth';
    ok !$verify->{exists_in_users}, 'removed from users';
};

subtest 'add_user with non-hashref input' => sub {
    my $result = $concierge->add_user('not a hash');
    ok !$result->{success}, 'add_user fails with non-hashref';
    like $result->{message}, qr/hash/i, 'error mentions hash';
};

subtest 'remove_user input validation' => sub {
    my $r1 = $concierge->remove_user(undef);
    ok !$r1->{success}, 'remove_user fails with undef user_id';

    my $r2 = $concierge->remove_user('');
    ok !$r2->{success}, 'remove_user fails with empty user_id';
};

subtest 'verify_user input validation' => sub {
    my $r1 = $concierge->verify_user(undef);
    ok !$r1->{success}, 'verify_user fails with undef user_id';

    my $r2 = $concierge->verify_user('');
    ok !$r2->{success}, 'verify_user fails with empty user_id';
};

subtest 'update_user_data input validation' => sub {
    # Undefined user_id
    my $r1 = $concierge->update_user_data(undef, { theme => 'dark' });
    ok !$r1->{success}, 'update_user_data fails with undef user_id';

    # Empty user_id
    my $r2 = $concierge->update_user_data('', { theme => 'dark' });
    ok !$r2->{success}, 'update_user_data fails with empty user_id';

    # Non-hashref update data
    my $r3 = $concierge->update_user_data('alice', 'not a hash');
    ok !$r3->{success}, 'update_user_data fails with non-hashref updates';

    # Only protected fields (filtered to empty)
    my $r4 = $concierge->update_user_data('alice', { user_id => 'hacker', password => 'bad' });
    ok !$r4->{success}, 'update_user_data fails when all updates are filtered out';
};

subtest 'get_user_data input validation' => sub {
    my $r1 = $concierge->get_user_data(undef);
    ok !$r1->{success}, 'get_user_data fails with undef user_id';

    my $r2 = $concierge->get_user_data('');
    ok !$r2->{success}, 'get_user_data fails with empty user_id';

    my $r3 = $concierge->get_user_data('nobody_exists_here');
    ok !$r3->{success}, 'get_user_data fails for nonexistent user';
};

subtest 'list_users with fields option' => sub {
    my $result = $concierge->list_users('', { fields => ['moniker', 'email'] });
    ok $result->{success}, 'list_users with fields option succeeds';
    ref_ok $result->{user_ids}, 'ARRAY', 'user_ids is array';
};

subtest '$user-level verify_password/reset_password/logout mirrors -- logged-in user' => sub {
    $concierge->add_user({
        user_id  => 'usermirror',
        moniker  => 'UserMirror',
        password => 'origpass1',
    });

    my $login = $concierge->login_user({
        user_id  => 'usermirror',
        password => 'origpass1',
    });
    ok $login->{success}, 'login succeeds';
    my $user = $login->{user};
    my $session_id = $user->session_id();

    is $user->verify_password('origpass1'), 1, 'verify_password true for correct password';
    is $user->verify_password('wrongpass'), 0, 'verify_password 0 for wrong password';

    ok $user->reset_password('newpass456'), 'reset_password succeeds';
    is $user->verify_password('newpass456'), 1, 'verify_password true for new password after reset';
    is $user->verify_password('origpass1'), 0, 'old password no longer verifies';

    ok $user->logout(), 'logout succeeds';
    my $check_session = $concierge->sessions->get_session($session_id);
    ok !$check_session->{success}, 'session gone after logout';

    # Post-logout cleanup: $user degrades to visitor-equivalent status
    # in place, rather than retaining stale session/backend capability.
    ok !$user->is_logged_in, 'is_logged_in false after logout';
    ok !$user->is_guest, 'is_guest false after logout';
    ok $user->is_visitor, 'is_visitor true after logout';
    is $user->session_id, undef, 'session_id cleared after logout';
    is $user->session, undef, 'session object cleared after logout';
    is $user->get_session_data, undef, 'get_session_data undef after logout';
    is $user->verify_password('newpass456'), undef, 'verify_password no longer works after logout';
    is $user->reset_password('anotherpass'), undef, 'reset_password no longer works after logout';
    is $user->refresh_user_data, undef, 'refresh_user_data no longer works after logout';
    is $user->update_user_data({ theme => 'dark' }), undef, 'update_user_data no longer works after logout';
    is $user->logout, undef, 'calling logout again is a graceful no-op';
    is $user->user_id, 'usermirror', 'user_id preserved after logout';
    ok $user->user_key, 'user_key preserved after logout';
};

subtest '$user-level verify_password/reset_password/logout mirrors -- guest' => sub {
    my $guest_result = $concierge->checkin_guest();
    ok $guest_result->{success}, 'checkin_guest succeeds';
    my $user = $guest_result->{user};
    my $session_id = $user->session_id();

    is $user->verify_password('whatever'), undef, 'verify_password undef for guest (no Auth identity)';
    is $user->reset_password('whatever'), undef, 'reset_password undef for guest (no Auth identity)';

    ok $user->logout(), 'logout succeeds for guest (session-only, no backend needed)';
    my $check_session = $concierge->sessions->get_session($session_id);
    ok !$check_session->{success}, 'session gone after guest logout';

    ok $user->is_visitor, 'guest degrades to is_visitor after logout';
    is $user->session_id, undef, 'session_id cleared after guest logout';
    is $user->logout, undef, 'calling logout again is a graceful no-op for former guest';
};

subtest '$user-level verify_password/reset_password/logout mirrors -- visitor' => sub {
    my $visitor_result = $concierge->admit_visitor();
    ok $visitor_result->{success}, 'admit_visitor succeeds';
    my $user = $visitor_result->{user};

    is $user->verify_password('whatever'), undef, 'verify_password undef for visitor (no closures)';
    is $user->reset_password('whatever'), undef, 'reset_password undef for visitor (no closures)';
    is $user->logout(), undef, 'logout undef for visitor (no session, no closures)';
};

subtest '$user session-validity gating -- second stale instance after logout elsewhere' => sub {
    $concierge->add_user({
        user_id  => 'staleinstance',
        moniker  => 'StaleInstance',
        password => 'origpass1',
    });

    my $login = $concierge->login_user({
        user_id  => 'staleinstance',
        password => 'origpass1',
    });
    ok $login->{success}, 'login succeeds';
    my $user1 = $login->{user};

    # A second, independent object instance for the same identity/session,
    # as if reconstructed from a cookie in a different request.
    my $restore = $concierge->restore_user($user1->user_key);
    ok $restore->{success}, 'restore_user succeeds for second instance';
    my $user2 = $restore->{user};

    # user2's closures are all present and untouched -- confirm it looks
    # fully live before user1 logs out.
    is $user2->verify_password('origpass1'), 1, 'user2 verify_password works before any logout';

    ok $user1->logout(), 'user1 logs itself out';

    # user2 never had ->logout() called on it -- its own fields (session,
    # closures) are all still populated -- but the session backing both
    # instances is now gone, so the live _session_valid check must catch it.
    is $user2->verify_password('origpass1'), undef,
        'user2 verify_password now undef (session invalidated elsewhere), not silently working';
    is $user2->reset_password('newerpass'), undef,
        'user2 reset_password now undef (session invalidated elsewhere)';
    is $user2->refresh_user_data, undef,
        'user2 refresh_user_data now undef (session invalidated elsewhere)';
    is $user2->update_user_data({ theme => 'dark' }), undef,
        'user2 update_user_data now undef (session invalidated elsewhere)';
    is $user2->get_session_data, undef,
        'user2 get_session_data now undef (session invalidated elsewhere)';
    is $user2->update_session_data({ foo => 'bar' }), undef,
        'user2 update_session_data now undef (session invalidated elsewhere)';

    # user2's own status/closures were never touched by user1's cleanup --
    # this confirms the protection comes from the live _session_valid
    # check, not from any cross-instance mutation.
    ok $user2->is_logged_in, 'user2 still reports is_logged_in (stale, uncleaned -- by design)';
};

done_testing;
