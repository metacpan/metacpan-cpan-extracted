#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;

# Test module loading
ok lives { require Concierge }, 'Concierge loads';
ok lives { require Concierge::Desk::User }, 'Concierge::Desk::User loads';
ok lives { require Concierge::Desk::Setup }, 'Concierge::Desk::Setup loads';

# Test version is defined
ok defined $Concierge::VERSION, 'Concierge version is defined';
ok defined $Concierge::Desk::User::VERSION, 'Concierge::Desk::User version is defined';

# Test that accessor methods exist
can_ok 'Concierge', [qw(
    new_concierge
    open_desk
    auth
    users
    sessions
    save_user_keys
    add_user
    remove_user
    verify_user
    update_user_data
    get_user_data
    list_users
    admit_visitor
    checkin_guest
    login_user
    login_guest
    restore_user
    logout_user
    verify_password
    reset_password
)];

# Test User object methods exist
can_ok 'Concierge::Desk::User', [qw(
    enable_user
    user_id
    user_key
    session_id
    is_visitor
    is_guest
    is_logged_in
    session
    get_session_data
    update_session_data
    moniker
    email
    user_status
    access_level
    get_user_field
    refresh_user_data
    update_user_data
)];

# Test Setup methods exist
can_ok 'Concierge::Desk::Setup', [qw(
    build_quick_desk
    build_desk
    validate_setup_config
)];

done_testing;
