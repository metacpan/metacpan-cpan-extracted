#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;
use File::Temp qw(tempdir);

use Concierge::Desk::Setup;
use Concierge;

# Real-time session timeout tests -- uses actual sleep() calls.
# Run with: prove -l xt/
# Skipped under AUTOMATED_TESTING (CPAN testers, CI) to avoid
# false failures on slow or heavily loaded machines.

skip_all 'Skipping real-time timeout tests under AUTOMATED_TESTING'
    if $ENV{AUTOMATED_TESTING};

my $test_dir = tempdir(CLEANUP => 1);

Concierge::Desk::Setup::build_quick_desk($test_dir, ['pref']);
my $desk = Concierge->open_desk($test_dir);
my $concierge = $desk->{concierge};

subtest 'guest session expires after timeout' => sub {
    my $guest_result = $concierge->checkin_guest({ timeout => 2 });
    ok $guest_result->{success}, 'guest checked in';

    my $user_key   = $guest_result->{user}->user_key();
    my $session_id = $guest_result->{user}->session_id();

    # Session should be valid immediately
    my $check = $concierge->sessions->get_session($session_id);
    ok $check->{success}, 'session valid immediately after creation';

    # Wait for expiry
    sleep 4;

    # Session should now be expired
    $check = $concierge->sessions->get_session($session_id);
    ok !$check->{success}, 'session expired after timeout';

    # restore_user should fail and clean up
    my $result = $concierge->restore_user($user_key);
    ok !$result->{success}, 'restore_user fails for expired session';
    like $result->{message}, qr/expired/i, 'message mentions expired';
    ok !exists $concierge->{user_keys}{$user_key}, 'stale mapping removed';
};

subtest 'logged-in session expires after timeout' => sub {
    $concierge->add_user({
        user_id  => 'timeouttest',
        moniker  => 'TimeoutTest',
        password => 'testpass123',
    });

    my $login = $concierge->login_user(
        { user_id => 'timeouttest', password => 'testpass123' },
        { session_timeout => 2 },
    );
    ok $login->{success}, 'login succeeds';

    my $user_key   = $login->{user}->user_key();
    my $session_id = $login->{user}->session_id();

    sleep 4;

    my $check = $concierge->sessions->get_session($session_id);
    ok !$check->{success}, 'logged-in session expired after timeout';

    my $result = $concierge->restore_user($user_key);
    ok !$result->{success}, 'restore_user fails for expired login session';
};

done_testing;
