#!/usr/bin/env perl
# Test: CRUD operations for File backend (validation skipped)

use v5.36;
use Test2::V0;
use File::Temp qw/ tempdir /;
use File::Path qw/ remove_tree /;

use Concierge::Users;

# Helper to setup test environment
sub setup_test_env {
    my $backend = shift;
    my $format = shift || 'tsv';

    my $storage_dir = tempdir(CLEANUP => 1);

    my $config = {
        storage_dir => $storage_dir,
        backend_class => "Concierge::Users::" . ucfirst($backend),
        file_format => $format,
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
        first_name => 'Test',
        last_name => 'User',
    };
}

# ==============================================================================
# Test Group 1: Register User (TSV)
# ==============================================================================
subtest 'File (TSV): Register user' => sub {
    my ($users, $storage_dir) = setup_test_env('file', 'tsv');

    my $user_data = test_user_data();
    my $result = $users->register_user($user_data);

    ok($result->{success}, 'User registered successfully');
    like($result->{message}, qr/created|successfully/, 'Message indicates success');

    # Verify user was created
    my $get_result = $users->get_user('testuser01');
    ok($get_result->{success}, 'Can retrieve registered user');
    is($get_result->{user}{user_id}, 'testuser01', 'User ID matches');
    is($get_result->{user}{email}, 'test@example.com', 'Email matches');

    # Verify timestamps were added
    ok($get_result->{user}{created_date}, 'Created date set');

    # Verify file exists and has content
    ok(-f "$storage_dir/users.tsv", 'TSV file exists');
};

# ==============================================================================
# Test Group 2: Register User (CSV)
# ==============================================================================
subtest 'File (CSV): Register user' => sub {
    my ($users, $storage_dir) = setup_test_env('file', 'csv');

    my $user_data = test_user_data();
    my $result = $users->register_user($user_data);

    ok($result->{success}, 'User registered successfully');

    my $get_result = $users->get_user('testuser01');
    ok($get_result->{success}, 'Can retrieve registered user');

    # Verify file exists
    ok(-f "$storage_dir/users.csv", 'CSV file exists');
};

# ==============================================================================
# Test Group 3: Get User
# ==============================================================================
subtest 'File: Get user' => sub {
    my ($users, $storage_dir) = setup_test_env('file', 'tsv');

    $users->register_user(test_user_data());

    # Test 1: Get existing user
    my $result = $users->get_user('testuser01');
    ok($result->{success}, 'Retrieve existing user');

    # Test 2: Get non-existent user
    my $missing = $users->get_user('nonexistent');
    ok(!$missing->{success}, 'Non-existent user fails');

    # Test 3: Field selection
    my $selected = $users->get_user('testuser01', { fields => [qw/ email phone /] });
    ok($selected->{success}, 'Field selection works');
    ok(exists $selected->{user}{email}, 'Selected field present');
};

# ==============================================================================
# Test Group 4: Update User
# ==============================================================================
subtest 'File: Update user' => sub {
    my ($users, $storage_dir) = setup_test_env('file', 'tsv');

    $users->register_user(test_user_data());

    my $updates = {
        email => 'newemail@example.com',
        phone => '555-9999',
        first_name => 'Updated',
    };

    my $result = $users->update_user('testuser01', $updates);
    ok($result->{success}, 'Update successful');

    # Verify updates persisted
    my $get_result = $users->get_user('testuser01');
    is($get_result->{user}{email}, 'newemail@example.com', 'Email updated');
    is($get_result->{user}{phone}, '555-9999', 'Phone updated');

    # Test 2: Update non-existent user
    my $missing = $users->update_user('nobody', { email => 'test@test.com' });
    ok(!$missing->{success}, 'Update non-existent user fails');
};

# ==============================================================================
# Test Group 5: List Users
# ==============================================================================
subtest 'File: List users' => sub {
    my ($users, $storage_dir) = setup_test_env('file', 'tsv');

    # Add multiple users
    my @test_users = (
        { user_id => 'user01', moniker => 'Moniker01', email => 'user01@example.com' },
        { user_id => 'user02', moniker => 'Moniker02', email => 'user02@example.com' },
        { user_id => 'user03', moniker => 'Moniker03', email => 'user03@example.com' },
    );

    $users->register_user($_) for @test_users;

    my $list = $users->list_users();
    ok($list->{success}, 'List succeeds');
    is($list->{total_count}, 3, 'Three users listed');

    # Test filtering
    my $filtered = $users->list_users('user_id=user02');
    is($filtered->{total_count}, 1, 'Filter works');
};

# ==============================================================================
# Test Group 6: Delete User
# ==============================================================================
subtest 'File: Delete user' => sub {
    my ($users, $storage_dir) = setup_test_env('file', 'tsv');

    $users->register_user(test_user_data());

    my $result = $users->delete_user('testuser01');
    ok($result->{success}, 'Delete successful');

    # Verify user is gone
    my $get_result = $users->get_user('testuser01');
    ok(!$get_result->{success}, 'Deleted user not found');
};

# ==============================================================================
# Test Group 7: Multiple Users CRUD
# ==============================================================================
subtest 'File: Multiple users CRUD' => sub {
    my ($users, $storage_dir) = setup_test_env('file', 'csv');

    # Register multiple users
    my @users_data = (
        { user_id => 'user01', moniker => 'Moniker01', email => 'user01@test.com' },
        { user_id => 'user02', moniker => 'Moniker02', email => 'user02@test.com' },
        { user_id => 'user03', moniker => 'Moniker03', email => 'user03@test.com' },
    );

    $users->register_user($_) for @users_data;

    # List all
    my $list = $users->list_users();
    is($list->{total_count}, 3, 'All users listed');

    # Update one
    $users->update_user('user02', { email => 'updated@test.com' });

    # Verify
    my $updated = $users->get_user('user02');
    is($updated->{user}{email}, 'updated@test.com', 'Update persisted');

    # Delete one
    $users->delete_user('user01');

    # Verify count
    my $list_after = $users->list_users();
    is($list_after->{total_count}, 2, 'Count reduced after deletion');
};

# ==============================================================================
# Test Group 8: File Persistence
# ==============================================================================
subtest 'File: File persistence across instantiations' => sub {
    my ($users, $storage_dir) = setup_test_env('file', 'tsv');
    my $config_file = "$storage_dir/users-config.json";

    # Add a user
    $users->register_user(test_user_data());

    # Create new instance from same config
    my $users2 = Concierge::Users->new($config_file);
    $users2->{skip_validation} = 1;

    # Verify user is accessible
    my $result = $users2->get_user('testuser01');
    ok($result->{success}, 'User persisted across instances');
    is($result->{user}{email}, 'test@example.com', 'Data intact');
};

done_testing();
