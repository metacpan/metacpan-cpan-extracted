#!/usr/bin/env perl
# Test: CRUD operations for YAML backend (validation skipped)

use v5.36;
use Test2::V0;
use File::Temp qw/ tempdir /;
use File::Path qw/ remove_tree /;
use File::Spec;

use Concierge::Users;

# Helper to setup test environment
sub setup_test_env {
    my $storage_dir = tempdir(CLEANUP => 1);

    my $config = {
        storage_dir => $storage_dir,
        backend_class => 'Concierge::Users::YAML',
        include_standard_fields => [qw/ email phone first_name last_name /],
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

# Helper to get YAML file path for a user
sub yaml_file_for {
    my ($storage_dir, $user_id) = @_;
    return File::Spec->catfile($storage_dir, "$user_id.yaml");
}

# ==============================================================================
# Test Group 1: Register User
# ==============================================================================
subtest 'YAML: Register user' => sub {
    my ($users, $storage_dir) = setup_test_env();

    my $user_data = test_user_data();
    my $result = $users->register_user($user_data);

    ok($result->{success}, 'User registered successfully');
    like($result->{message}, qr/created|successfully/, 'Message indicates success');

    # Verify YAML file was created
    my $yaml_file = yaml_file_for($storage_dir, 'testuser01');
    ok(-f $yaml_file, 'YAML file created for user');

    # Verify user was created
    my $get_result = $users->get_user('testuser01');
    ok($get_result->{success}, 'Can retrieve registered user');
    is($get_result->{user}{user_id}, 'testuser01', 'User ID matches');
    is($get_result->{user}{email}, 'test@example.com', 'Email matches');

    # Verify timestamps
    ok($get_result->{user}{created_date}, 'Created date set');
    ok($get_result->{user}{last_mod_date}, 'Last mod date set');
};

# ==============================================================================
# Test Group 2: Get User
# ==============================================================================
subtest 'YAML: Get user' => sub {
    my ($users, $storage_dir) = setup_test_env();

    $users->register_user(test_user_data());

    # Test 1: Get existing user
    my $result = $users->get_user('testuser01');
    ok($result->{success}, 'Retrieve existing user');
    is($result->{user}{moniker}, 'TestUser01', 'Moniker correct');

    # Test 2: Get non-existent user
    my $missing = $users->get_user('nonexistent');
    ok(!$missing->{success}, 'Non-existent user fails');

    # Test 3: Field selection
    my $selected = $users->get_user('testuser01', { fields => [qw/ email phone /] });
    ok($selected->{success}, 'Field selection works');
    ok(exists $selected->{user}{email}, 'Selected field present');
    ok(!exists $selected->{user}{moniker}, 'Non-selected field absent');
};

# ==============================================================================
# Test Group 3: Update User
# ==============================================================================
subtest 'YAML: Update user' => sub {
    my ($users, $storage_dir) = setup_test_env();

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
    is($get_result->{user}{first_name}, 'Updated', 'First name updated');

    # Verify last_mod_date changed
    ok($get_result->{user}{last_mod_date}, 'Last mod date updated');

    # Test 2: Update non-existent user
    my $missing = $users->update_user('nobody', { email => 'test@test.com' });
    ok(!$missing->{success}, 'Update non-existent user fails');
};

# ==============================================================================
# Test Group 4: List Users
# ==============================================================================
subtest 'YAML: List users' => sub {
    my ($users, $storage_dir) = setup_test_env();

    # Test 1: Empty list
    my $empty = $users->list_users();
    ok($empty->{success}, 'List succeeds when empty');
    is($empty->{total_count}, 0, 'No users yet');

    # Test 2: Add multiple users
    my @test_users = (
        { user_id => 'user01', moniker => 'Moniker01', email => 'user01@example.com' },
        { user_id => 'user02', moniker => 'Moniker02', email => 'user02@example.com' },
        { user_id => 'user03', moniker => 'Moniker03', email => 'user03@example.com' },
    );

    $users->register_user($_) for @test_users;

    # Verify individual YAML files
    ok(-f yaml_file_for($storage_dir, 'user01'), 'user01.yaml exists');
    ok(-f yaml_file_for($storage_dir, 'user02'), 'user02.yaml exists');
    ok(-f yaml_file_for($storage_dir, 'user03'), 'user03.yaml exists');

    my $list = $users->list_users();
    ok($list->{success}, 'List succeeds');
    is($list->{total_count}, 3, 'Three users listed');

    # Test 3: List with filter
    my $filtered = $users->list_users('user_id=user02');
    is($filtered->{total_count}, 1, 'Filter reduces results');
    is($filtered->{user_ids}[0], 'user02', 'Correct user returned');

    # Test 4: List with pattern match
    my $pattern = $users->list_users('email:user02');
    is($pattern->{total_count}, 1, 'Pattern match works');
};

# ==============================================================================
# Test Group 5: Delete User
# ==============================================================================
subtest 'YAML: Delete user' => sub {
    my ($users, $storage_dir) = setup_test_env();

    $users->register_user(test_user_data());

    my $yaml_file = yaml_file_for($storage_dir, 'testuser01');
    ok(-f $yaml_file, 'YAML file exists before deletion');

    my $result = $users->delete_user('testuser01');
    ok($result->{success}, 'Delete successful');

    # Verify YAML file is deleted
    ok(!-f $yaml_file, 'YAML file removed after deletion');

    # Verify user is gone
    my $get_result = $users->get_user('testuser01');
    ok(!$get_result->{success}, 'Deleted user not found');

    # Test 2: Delete non-existent user
    my $missing = $users->delete_user('nobody');
    ok(!$missing->{success}, 'Delete non-existent user fails');
};

# ==============================================================================
# Test Group 6: Multiple Users CRUD
# ==============================================================================
subtest 'YAML: Multiple users CRUD' => sub {
    my ($users, $storage_dir) = setup_test_env();

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
    $users->update_user('user02', { email => 'updated@test.com', phone => '555-0000' });

    # Verify
    my $updated = $users->get_user('user02');
    is($updated->{user}{email}, 'updated@test.com', 'Update persisted');

    # Delete one
    $users->delete_user('user01');

    # Verify count and file removal
    my $list_after = $users->list_users();
    is($list_after->{total_count}, 2, 'Count reduced after deletion');
    ok(!-f yaml_file_for($storage_dir, 'user01'), 'Deleted user file removed');
};

# ==============================================================================
# Test Group 7: YAML File Structure
# ==============================================================================
subtest 'YAML: File structure and format' => sub {
    my ($users, $storage_dir) = setup_test_env();

    my $user_data = test_user_data();

    $users->register_user($user_data);

    my $yaml_file = yaml_file_for($storage_dir, 'testuser01');

    # Read YAML file directly
    open my $fh, '<', $yaml_file or die "Cannot read YAML: $!";
    local $/;
    my $yaml_content = <$fh>;
    close $fh;

    # Basic YAML structure checks
    like($yaml_content, qr/user_id/, 'YAML contains user_id');
    like($yaml_content, qr/email/, 'YAML contains email');
    like($yaml_content, qr/created_date/, 'YAML contains created_date');

    # Verify data integrity through API
    my $result = $users->get_user('testuser01');
    is($result->{user}{email}, 'test@example.com', 'Email field persisted correctly');
    is($result->{user}{phone}, '555-1234', 'Phone field persisted correctly');
};

# ==============================================================================
# Test Group 8: Persistence Across Instances
# ==============================================================================
subtest 'YAML: Persistence across instances' => sub {
    my ($users, $storage_dir) = setup_test_env();
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

    # Update through second instance
    $users2->update_user('testuser01', { email => 'second@test.com' });

    # Verify through first instance
    my $verify = $users->get_user('testuser01');
    is($verify->{user}{email}, 'second@test.com', 'Changes visible across instances');
};

# ==============================================================================
# Test Group 9: Special Characters in user_id
# ==============================================================================
subtest 'YAML: Special characters in user_id' => sub {
    my ($users, $storage_dir) = setup_test_env();

    # Test email as user_id
    my $email_data = {
        user_id => 'user@example.com',
        moniker => 'EmailUser',
        email => 'user@example.com',
    };

    my $result = $users->register_user($email_data);
    ok($result->{success}, 'Email as user_id works');

    my $yaml_file = yaml_file_for($storage_dir, 'user@example.com');
    ok(-f $yaml_file, 'YAML file created with email in filename');

    my $get_result = $users->get_user('user@example.com');
    ok($get_result->{success}, 'Can retrieve user with email ID');
};

done_testing();
