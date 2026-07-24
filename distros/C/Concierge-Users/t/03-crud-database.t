#!/usr/bin/env perl
# Test: CRUD operations for Database backend (validation skipped)

use v5.36;
use Test2::V0;
use File::Temp qw/ tempdir /;
use File::Path qw/ remove_tree /;

use Concierge::Users;

# Helper to setup test environment
sub setup_test_env {
    my $storage_dir = tempdir(CLEANUP => 1);

    my $config = {
        storage_dir => $storage_dir,
        backend_class => 'Concierge::Users::SQLite',
        include_standard_fields => [qw/ email phone /],
    };

    my $setup_result = Concierge::Users->setup($config);
    die "Setup failed: $setup_result->{message}" unless $setup_result->{success};

    my $users = Concierge::Users->new($setup_result->{config_file});

    # Enable skip_validation flag
    $users->{skip_validation} = 1;

    return ($users, $storage_dir);
}

# Helper to create test user data
sub test_user_data {
    return {
        user_id => 'testuser01',
        moniker => 'TestUser01',
        email => 'test@example.com',
        phone => '555-1234',
    };
}

# ==============================================================================
# Test Group 1: Register User
# ==============================================================================
subtest 'Database: Register user' => sub {
    my ($users, $storage_dir) = setup_test_env();

    # Test 1: Register a new user
    my $user_data = test_user_data();
    my $result = $users->register_user($user_data);

    ok($result->{success}, 'User registered successfully');
    like($result->{message}, qr/created|successfully/, 'Message indicates success');

    # Test 2: Verify user was created
    my $get_result = $users->get_user('testuser01');
    ok($get_result->{success}, 'Can retrieve registered user');
    is($get_result->{user}{user_id}, 'testuser01', 'User ID matches');
    is($get_result->{user}{moniker}, 'TestUser01', 'Moniker matches');
    is($get_result->{user}{email}, 'test@example.com', 'Email matches');

    # Test 3: Verify timestamps were added
    ok($get_result->{user}{created_date}, 'Created date set');
    like($get_result->{user}{created_date}, qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/,
         'Created date format correct');
    ok($get_result->{user}{last_mod_date}, 'Last mod date set');

    # Test 4: Attempt duplicate registration
    my $dup_result = $users->register_user($user_data);
    ok(!$dup_result->{success}, 'Duplicate registration fails');
    like($dup_result->{message}, qr/already exists/, 'Error mentions exists');

    # Cleanup handled by tempdir
};

# ==============================================================================
# Test Group 2: Get User
# ==============================================================================
subtest 'Database: Get user' => sub {
    my ($users, $storage_dir) = setup_test_env();

    # Create a user first
    my $user_data = test_user_data();
    $users->register_user($user_data);

    # Test 1: Get existing user
    my $result = $users->get_user('testuser01');
    ok($result->{success}, 'Retrieve existing user');
    is($result->{user_id}, 'testuser01', 'User ID correct');

    # Test 2: Get non-existent user
    my $missing = $users->get_user('nonexistent');
    ok(!$missing->{success}, 'Non-existent user fails');

    # Test 3: Field selection
    my $selected = $users->get_user('testuser01', { fields => [qw/ email phone /] });
    ok($selected->{success}, 'Field selection works');
    ok(exists $selected->{user}{email}, 'Selected field present');
    ok(exists $selected->{user}{user_id}, 'user_id always included');

    # Cleanup handled by tempdir
};

# ==============================================================================
# Test Group 3: Update User
# ==============================================================================
subtest 'Database: Update user' => sub {
    my ($users, $storage_dir) = setup_test_env();

    # Create a user first
    my $user_data = test_user_data();
    $users->register_user($user_data);

    # Test 1: Update user fields
    my $updates = {
        email => 'newemail@example.com',
        phone => '555-9999',
    };

    my $result = $users->update_user('testuser01', $updates);
    ok($result->{success}, 'Update successful');
    like($result->{message}, qr/updated|successfully/, 'Message indicates update');

    # Test 2: Verify updates persisted
    my $get_result = $users->get_user('testuser01');
    is($get_result->{user}{email}, 'newemail@example.com', 'Email updated');
    is($get_result->{user}{phone}, '555-9999', 'Phone updated');

    # Test 3: Verify last_mod_date changed
    like($get_result->{user}{last_mod_date}, qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/,
         'Last mod date updated');

    # Test 4: Update non-existent user
    my $missing = $users->update_user('nobody', { email => 'test@test.com' });
    ok(!$missing->{success}, 'Update non-existent user fails');

    # Test 5: Cannot update readonly fields
    my $ro_result = $users->update_user('testuser01', {
        user_id => 'different_id',
        created_date => '2025-01-01 00:00:00',
    });

    # Should still succeed, but these fields should be ignored
    my $verify = $users->get_user('testuser01');
    is($verify->{user}{user_id}, 'testuser01', 'user_id unchanged');

    # Cleanup handled by tempdir
};

# ==============================================================================
# Test Group 4: List Users
# ==============================================================================
subtest 'Database: List users' => sub {
    my ($users, $storage_dir) = setup_test_env();

    # Test 1: Empty list
    my $empty = $users->list_users();
    ok($empty->{success}, 'List succeeds when empty');
    is(scalar(@{$empty->{user_ids}}), 0, 'No users yet');

    # Test 2: Add multiple users
    my @test_users = (
        { user_id => 'user01', moniker => 'Moniker01', email => 'user01@example.com' },
        { user_id => 'user02', moniker => 'Moniker02', email => 'user02@example.com' },
        { user_id => 'user03', moniker => 'Moniker03', email => 'user03@example.com' },
    );

    $users->register_user($_) for @test_users;

    my $list = $users->list_users();
    ok($list->{success}, 'List succeeds');
    is($list->{total_count}, 3, 'Three users listed');
    is(scalar(@{$list->{user_ids}}), 3, 'Three user IDs returned');

    # Test 3: List with filter (simple)
    my $filtered = $users->list_users('user_id=user02');
    is($filtered->{total_count}, 1, 'Filter reduces results');
    is($filtered->{user_ids}[0], 'user02', 'Correct user returned');

    # Test 4: List with pattern match
    my $pattern = $users->list_users('email:user02');
    is($pattern->{total_count}, 1, 'Pattern match works');

    # Cleanup handled by tempdir
};

# ==============================================================================
# Test Group 5: Delete User
# ==============================================================================
subtest 'Database: Delete user' => sub {
    my ($users, $storage_dir) = setup_test_env();

    # Create a user first
    my $user_data = test_user_data();
    $users->register_user($user_data);

    # Test 1: Delete existing user
    my $result = $users->delete_user('testuser01');
    ok($result->{success}, 'Delete successful');
    like($result->{message}, qr/deleted|successfully/, 'Message indicates deletion');

    # Test 2: Verify user is gone
    my $get_result = $users->get_user('testuser01');
    ok(!$get_result->{success}, 'Deleted user not found');

    # Test 3: Delete non-existent user
    my $missing = $users->delete_user('nobody');
    ok(!$missing->{success}, 'Delete non-existent user fails');

    # Cleanup handled by tempdir
};

# ==============================================================================
# Test Group 6: Bulk Operations
# ==============================================================================
subtest 'Database: Bulk operations' => sub {
    my ($users, $storage_dir) = setup_test_env();

    # Test 1: Register multiple users
    my @bulk_users = (
        { user_id => 'bulk01', moniker => 'Bulk01', email => 'bulk01@test.com' },
        { user_id => 'bulk02', moniker => 'Bulk02', email => 'bulk02@test.com' },
        { user_id => 'bulk03', moniker => 'Bulk03', email => 'bulk03@test.com' },
        { user_id => 'bulk04', moniker => 'Bulk04', email => 'bulk04@test.com' },
        { user_id => 'bulk05', moniker => 'Bulk05', email => 'bulk05@test.com' },
    );

    my $results = [];
    push @$results, $users->register_user($_) for @bulk_users;

    ok((grep { $_->{success} } @$results) == 5, 'All 5 users registered');

    # Test 2: List all users
    my $list = $users->list_users();
    is($list->{total_count}, 5, 'All 5 users in database');

    # Test 3: Update multiple users
    for my $id (qw/ bulk01 bulk02 bulk03 /) {
        $users->update_user($id, { email => "updated_$id\@test.com" });
    }

    # Verify updates
    my $updated = $users->get_user('bulk01');
    like($updated->{user}{email}, qr/updated_bulk01/, 'Bulk update worked');

    # Cleanup handled by tempdir
};

# ==============================================================================
# Test Group 7: Edge Cases
# ==============================================================================
subtest 'Database: Edge cases' => sub {
    my ($users, $storage_dir) = setup_test_env();

    # Test 1: User with minimal data
    my $minimal = $users->register_user({
        user_id => 'minimal',
        moniker => 'Min',
    });
    ok($minimal->{success}, 'Minimal user registered');

    # Test 2: User with extra fields not in schema
    my $extra = $users->register_user({
        user_id => 'extra',
        moniker => 'Extra',
        email => 'extra@test.com',
    });
    ok($extra->{success}, 'User with configured fields works');

    # Test 3: Empty string values
    my $empty = $users->register_user({
        user_id => 'emptyvals',
        moniker => 'Empty',
        email => '',
        phone => '',
    });
    ok($empty->{success}, 'Empty string values accepted');

    # Cleanup handled by tempdir
};

done_testing();
