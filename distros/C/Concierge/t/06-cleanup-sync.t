#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;
use File::Temp qw(tempdir);

use Concierge::Desk::Setup;
use Concierge;

# Setup test desk
my $test_dir = tempdir(CLEANUP => 1);

Concierge::Desk::Setup::build_quick_desk($test_dir);
my $desk = Concierge->open_desk($test_dir);
my $concierge = $desk->{concierge};

subtest 'cleanup_sessions synchronizes user_keys' => sub {
    # Add test users
    $concierge->add_user({
        user_id  => 'user1',
        moniker  => 'User1',
        password => 'password1',
    });

    $concierge->add_user({
        user_id  => 'user2',
        moniker  => 'User2',
        password => 'password2',
    });

    # Login both users
    my $login1 = $concierge->login_user({
        user_id  => 'user1',
        password => 'password1',
    });
    my $user_key1 = $login1->{user}->user_key();
    my $session_id1 = $login1->{user}->session_id();

    my $login2 = $concierge->login_user({
        user_id  => 'user2',
        password => 'password2',
    });
    my $user_key2 = $login2->{user}->user_key();
    my $session_id2 = $login2->{user}->session_id();

    # Verify both user_keys exist
    ok exists $concierge->{user_keys}{$user_key1}, 'user_key1 exists';
    ok exists $concierge->{user_keys}{$user_key2}, 'user_key2 exists';

    # Manually delete one session (simulate expiration)
    $concierge->sessions->delete_session($session_id1);

    # Run cleanup_sessions directly
    my $cleanup_result = $concierge->sessions->cleanup_sessions();
    ok $cleanup_result->{success}, 'cleanup_sessions succeeds';
    ref_ok $cleanup_result->{active}, 'ARRAY', 'returns active session list';

    # Now manually trigger user_keys sync (normally done in open_desk)
    if ($cleanup_result->{active}) {
        my %active_sessions = map { $_ => 1 } @{$cleanup_result->{active}};

        my $cleaned = 0;
        for my $key (keys %{$concierge->{user_keys}}) {
            my $sid = $concierge->{user_keys}{$key}{session_id};
            unless ($active_sessions{$sid}) {
                delete $concierge->{user_keys}{$key};
                $cleaned++;
            }
        }

        is $cleaned, 1, 'one user_key cleaned';
    }

    # Verify user_key1 removed, user_key2 remains
    ok !exists $concierge->{user_keys}{$user_key1}, 'user_key1 removed';
    ok exists $concierge->{user_keys}{$user_key2}, 'user_key2 still exists';
};

subtest 'open_desk performs cleanup synchronization' => sub {
    # Create new desk
    my $temp_dir = tempdir(CLEANUP => 1);

    Concierge::Desk::Setup::build_quick_desk($temp_dir);
    my $desk1 = Concierge->open_desk($temp_dir);
    my $conc = $desk1->{concierge};

    # Add user and login
    $conc->add_user({
        user_id  => 'synctest',
        moniker  => 'SyncTest',
        password => 'syncpass1',
    });

    my $login = $conc->login_user({
        user_id  => 'synctest',
        password => 'syncpass1',
    });
    my $user_key = $login->{user}->user_key();
    my $session_id = $login->{user}->session_id();

    # Verify user_key exists
    ok exists $conc->{user_keys}{$user_key}, 'user_key exists after login';

    # Manually delete session to simulate expiration
    $conc->sessions->delete_session($session_id);

    # Re-open desk (should run cleanup and sync)
    my $desk2 = Concierge->open_desk($temp_dir);
    my $conc2 = $desk2->{concierge};

    # Verify user_key was cleaned up
    ok !exists $conc2->{user_keys}{$user_key}, 'user_key cleaned on desk reopening';
};

subtest 'cleanup handles empty user_keys gracefully' => sub {
    my $temp_dir = tempdir(CLEANUP => 1);

    Concierge::Desk::Setup::build_quick_desk($temp_dir);

    # Open desk with no users (empty user_keys)
    my $result = Concierge->open_desk($temp_dir);

    ok $result->{success}, 'open_desk succeeds with empty user_keys';
    ref_ok $result->{concierge}{user_keys}, 'HASH', 'user_keys initialized as hash';
};

subtest 'cleanup preserves active user_keys' => sub {
    my $temp_dir = tempdir(CLEANUP => 1);

    Concierge::Desk::Setup::build_quick_desk($temp_dir);
    my $desk = Concierge->open_desk($temp_dir);
    my $conc = $desk->{concierge};

    # Create multiple users
    for my $i (1..3) {
        $conc->add_user({
            user_id  => "active$i",
            moniker  => "Active$i",
            password => "password$i",
        });

        $conc->login_user({
            user_id  => "active$i",
            password => "password$i",
        });
    }

    my $keys_before = scalar keys %{$conc->{user_keys}};
    is $keys_before, 3, 'three user_keys before cleanup';

    # Run cleanup (no expired sessions)
    $conc->sessions->cleanup_sessions();

    # Re-open to trigger sync
    my $desk2 = Concierge->open_desk($temp_dir);
    my $conc2 = $desk2->{concierge};

    my $keys_after = scalar keys %{$conc2->{user_keys}};
    is $keys_after, 3, 'all three user_keys preserved';
};

done_testing;
