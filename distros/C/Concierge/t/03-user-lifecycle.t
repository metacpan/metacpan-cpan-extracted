#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;
use File::Temp qw(tempdir);

use Concierge::Setup;
use Concierge;

# Setup test desk
my $test_dir = tempdir(CLEANUP => 1);

Concierge::Setup::build_quick_desk($test_dir, ['theme']);
my $desk = Concierge->open_desk($test_dir);
my $concierge = $desk->{concierge};

subtest 'Visitor lifecycle' => sub {
    my $result = $concierge->admit_visitor();

    ok $result->{success}, 'admit_visitor succeeds';
    ok $result->{is_visitor}, 'is_visitor flag set';
    isa_ok $result->{user}, ['Concierge::User'], 'returns User object';

    my $visitor = $result->{user};

    ok $visitor->user_id(), 'visitor has user_id';
    ok $visitor->user_key(), 'visitor has user_key';
    is $visitor->session_id(), undef, 'visitor has no session_id';
    is $visitor->is_visitor(), 1, 'is_visitor() returns true';
    is $visitor->is_guest(), 0, 'is_guest() returns false';
    is $visitor->is_logged_in(), 0, 'is_logged_in() returns false';
    is $visitor->session(), undef, 'visitor has no session';
};

subtest 'Guest lifecycle' => sub {
    my $result = $concierge->checkin_guest();

    ok $result->{success}, 'checkin_guest succeeds';
    ok $result->{is_guest}, 'is_guest flag set';
    isa_ok $result->{user}, ['Concierge::User'], 'returns User object';

    my $guest = $result->{user};

    ok $guest->user_id(), 'guest has user_id';
    ok $guest->user_key(), 'guest has user_key';
    ok $guest->session_id(), 'guest has session_id';
    is $guest->is_visitor(), 0, 'is_visitor() returns false';
    is $guest->is_guest(), 1, 'is_guest() returns true';
    is $guest->is_logged_in(), 0, 'is_logged_in() returns false';

    isa_ok $guest->session(), ['Concierge::Sessions::Session'], 'guest has session object';
    ok $guest->session()->is_active(), 'guest session is active';
};

subtest 'Logged-in user lifecycle' => sub {
    # Add user first
    my $add_result = $concierge->add_user({
        user_id  => 'testuser',
        moniker  => 'TestUser',
        email    => 'test@example.com',
        password => 'testpass123',
    });
    ok $add_result->{success}, 'add_user succeeds';

    # Login
    my $login_result = $concierge->login_user({
        user_id  => 'testuser',
        password => 'testpass123',
    });

    ok $login_result->{success}, 'login_user succeeds';
    isa_ok $login_result->{user}, ['Concierge::User'], 'returns User object';

    my $user = $login_result->{user};

    is $user->user_id(), 'testuser', 'user_id correct';
    ok $user->user_key(), 'user has user_key';
    ok $user->session_id(), 'user has session_id';
    is $user->is_visitor(), 0, 'is_visitor() returns false';
    is $user->is_guest(), 0, 'is_guest() returns false';
    is $user->is_logged_in(), 1, 'is_logged_in() returns true';

    is $user->moniker(), 'TestUser', 'moniker accessible';
    is $user->email(), 'test@example.com', 'email accessible';
    isa_ok $user->session(), ['Concierge::Sessions::Session'], 'user has session object';
};

subtest 'Logged-in user status and access fields' => sub {
    my $add_result = $concierge->add_user({
        user_id  => 'statususer',
        moniker  => 'StatusUser',
        password => 'status123',
    });
    ok $add_result->{success}, 'add_user succeeds';

    my $login_result = $concierge->login_user({
        user_id  => 'statususer',
        password => 'status123',
    });
    ok $login_result->{success}, 'login_user succeeds';

    my $user = $login_result->{user};
    ok defined($user->user_status()),  'user_status() is defined';
    ok defined($user->access_level()), 'access_level() is defined';
};

subtest 'enable_user without options argument' => sub {
    use Concierge::User;
    my $user = Concierge::User->enable_user('bare_user');
    isa_ok $user, ['Concierge::User'], 'returns User object';
    is $user->user_id(),    'bare_user', 'user_id set';
    is $user->is_visitor(), 1,           'is_visitor when no options given';
};

subtest 'Guest to logged-in conversion' => sub {
    # Create guest with session data
    my $guest_result = $concierge->checkin_guest();
    my $guest = $guest_result->{user};
    my $guest_key = $guest->user_key();

    # Add cart data to guest session
    $guest->update_session_data({ cart => ['item1', 'item2'] });

    # Convert guest to logged-in user (creates the account and logs in)
    my $convert_result = $concierge->login_guest(
        { user_id => 'converter', moniker => 'Converter', password => 'convert123' },
        $guest_key
    );

    ok $convert_result->{success}, 'login_guest succeeds';
    isa_ok $convert_result->{user}, ['Concierge::User'], 'returns User object';

    my $user = $convert_result->{user};
    is $user->user_id(), 'converter', 'converted to correct user';
    is $user->is_logged_in(), 1, 'user is logged in';

    # Check if cart data transferred
    my $session_data = $user->get_session_data();
    is $session_data->{cart}, ['item1', 'item2'], 'cart data transferred';

    # Verify guest session/key was deleted
    ok !exists $concierge->{user_keys}{$guest_key}, 'guest user_key removed from mapping';
};

done_testing;
