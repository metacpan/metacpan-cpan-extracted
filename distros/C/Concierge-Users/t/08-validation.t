#!/usr/bin/env perl
# Test: Field validation system

use v5.36;
use Test2::V0;
use Test2::Tools::Exception qw/ dies lives /;
use File::Temp qw/ tempdir /;
use Concierge::Users;

# Helper to setup test environment
sub setup_test_env {
    my $backend = shift;

    my $storage_dir = tempdir(CLEANUP => 1);

    my $config = {
        storage_dir => $storage_dir,
        backend => $backend,
        include_standard_fields => [qw/ email phone first_name last_name organization /],
    };

    my $setup_result = Concierge::Users->setup($config);
    die "Setup failed: $setup_result->{message}" unless $setup_result->{success};

    my $users = Concierge::Users->new($setup_result->{config_file});

    return ($users, $storage_dir, $setup_result->{config_file});
}

# ==============================================================================
# Test Group 1: Required Fields with must_validate => 1
# ==============================================================================
subtest 'Required field validation (must_validate => 1)' => sub {
    my ($users, $storage_dir) = setup_test_env('database');

    # Test 1: Moniker is required and must validate
    my $result1 = $users->register_user({
        user_id => 'test1',
        moniker => '',  # Empty moniker
    });
    ok(!$result1->{success}, 'Fails with empty moniker');
    like($result1->{message}, qr/moniker/, 'Error mentions moniker');

    # Test 2: Moniker format validation
    my $result2 = $users->register_user({
        user_id => 'test2',
        moniker => 'Invalid Moniker!',  # Has space and special char
    });
    ok(!$result2->{success}, 'Fails with invalid moniker format');
    like($result2->{message}, qr/moniker/, 'Error mentions moniker');

    # Test 3: Valid moniker
    my $result3 = $users->register_user({
        user_id => 'test3',
        moniker => 'ValidMoniker42',
    });
    ok($result3->{success}, 'Accepts valid moniker');
};

# ==============================================================================
# Test Group 2: Optional Fields with must_validate => 0
# ==============================================================================
subtest 'Optional field validation (must_validate => 0)' => sub {
    my ($users, $storage_dir) = setup_test_env('file');

    # Test 1: Invalid email (must_validate=0) - should succeed with warning
    my $result1 = $users->register_user({
        user_id => 'emailtest1',
        moniker => 'EmailTest1',
        email => 'not-an-email',  # Invalid format
    });
    ok($result1->{success}, 'Succeeds but stores default (empty string) for invalid email');
    ok($result1->{warnings}, 'Has warnings about invalid email');

    # Verify email is empty string (default)
    my $check1 = $users->get_user('emailtest1');
    is($check1->{user}{email}, '', 'Invalid email not stored, default used');

    # Test 2: Valid email
    my $result2 = $users->register_user({
        user_id => 'emailtest2',
        moniker => 'EmailTest2',
        email => 'valid@example.com',
    });
    ok($result2->{success}, 'Accepts valid email');

    my $check2 = $users->get_user('emailtest2');
    is($check2->{user}{email}, 'valid@example.com', 'Valid email stored correctly');
};

# ==============================================================================
# Test Group 3: Field Type Validators
# ==============================================================================
subtest 'Field type validators' => sub {
    my ($users, $storage_dir) = setup_test_env('yaml');

    # Test 1: Phone validator (must_validate=0)
    my $result1 = $users->register_user({
        user_id => 'phonetest1',
        moniker => 'PhoneTest1',
        phone => '123',  # Too short
    });
    ok($result1->{success}, 'Succeeds with invalid phone (must_validate=0)');
    ok($result1->{warnings}, 'Has warnings about phone format');

    # Test 2: Valid phone
    my $result2 = $users->register_user({
        user_id => 'phonetest2',
        moniker => 'PhoneTest2',
        phone => '+1 (555) 123-4567',
    });
    ok($result2->{success}, 'Accepts valid phone');

    my $check2 = $users->get_user('phonetest2');
    is($check2->{user}{phone}, '+1 (555) 123-4567', 'Phone stored with internal spaces preserved');

    # Test 3: Organization field validator (must_validate=0)
    # Text validator checks max_length, organization max is 100
    my $result3 = $users->register_user({
        user_id => 'orgtest1',
        moniker => 'OrgTest1',
        organization => 'X' x 150,  # Too long (max 100)
    });
    ok($result3->{success}, 'Succeeds with invalid organization (must_validate=0)');
    ok($result3->{warnings}, 'Has warnings about organization length');

    # Test 4: Valid name fields (must_validate=1, so they must pass)
    my $result4 = $users->register_user({
        user_id => 'nametest2',
        moniker => 'NameTest2',
        first_name => 'Mary-Jane',
        last_name => "O'Brien",
    });
    ok($result4->{success}, 'Accepts valid names with hyphens and apostrophes');

    my $check4 = $users->get_user('nametest2');
    is($check4->{user}{first_name}, 'Mary-Jane', 'First name stored correctly');
    is($check4->{user}{last_name}, "O'Brien", 'Last name stored correctly');

    # Test 5: Invalid name should fail (must_validate=1)
    my $result5 = $users->register_user({
        user_id => 'nametest3',
        moniker => 'NameTest3',
        first_name => 'John123',  # Invalid - has numbers
    });
    ok(!$result5->{success}, 'Fails with invalid name (must_validate=1)');
    like($result5->{message}, qr/invalid/i, 'Error mentions invalid characters');
};

# ==============================================================================
# Test Group 4: Moniker Validation in Updates
# ==============================================================================
subtest 'Moniker validation in updates' => sub {
    my ($users, $storage_dir) = setup_test_env('database');

    # Create user with valid moniker
    $users->register_user({
        user_id => 'updatetest1',
        moniker => 'OriginalMoniker',
    });

    # Test 1: Try to update with invalid moniker
    my $result1 = $users->update_user('updatetest1', {
        moniker => 'Invalid Moniker!',  # Has space and special char
    });
    ok(!$result1->{success}, 'Fails to update with invalid moniker');
    like($result1->{message}, qr/moniker/, 'Error mentions moniker');

    # Verify moniker wasn't changed
    my $check1 = $users->get_user('updatetest1');
    is($check1->{user}{moniker}, 'OriginalMoniker', 'Moniker unchanged after failed update');

    # Test 2: Update with valid moniker
    my $result2 = $users->update_user('updatetest1', {
        moniker => 'UpdatedMoniker',
    });
    ok($result2->{success}, 'Accepts valid moniker update');

    my $check2 = $users->get_user('updatetest1');
    is($check2->{user}{moniker}, 'UpdatedMoniker', 'Moniker updated correctly');
};

# ==============================================================================
# Test Group 5: Warnings Accumulation
# ==============================================================================
subtest 'Warnings accumulation for multiple validation failures' => sub {
    my ($users, $storage_dir) = setup_test_env('file');

    # Register user with multiple invalid fields (all must_validate=0 except names)
    my $result = $users->register_user({
        user_id => 'warntest',
        moniker => 'WarnTest',
        email => 'invalid-email',
        phone => '123',
        organization => 'X' x 150,  # Too long
    });

    ok($result->{success}, 'Succeeds despite multiple validation failures');
    ok($result->{warnings}, 'Has warnings array');
    is(ref($result->{warnings}), 'ARRAY', 'Warnings is an array reference');

    # Should have warnings for email, phone, organization
    ok(scalar(@{$result->{warnings}}) >= 3, 'Has at least 3 warnings');

    # Verify all fields have default values
    my $check = $users->get_user('warntest');
    is($check->{user}{email}, '', 'Email is default');
    is($check->{user}{phone}, '', 'Phone is default');
    is($check->{user}{organization}, '', 'Organization is default');
};

# ==============================================================================
# Test Group 6: Data Cleaning and Trimming
# ==============================================================================
subtest 'Data cleaning before validation' => sub {
    my ($users, $storage_dir) = setup_test_env('yaml');

    # Test 1: Leading/trailing whitespace trimmed from email
    my $result1 = $users->register_user({
        user_id => 'trimtest',
        moniker => 'TrimTest',
        email => '  test@example.com  ',
    });
    ok($result1->{success}, 'Succeeds and trims email');

    my $check1 = $users->get_user('trimtest');
    is($check1->{user}{email}, 'test@example.com', 'Email trimmed correctly');

    # Test 2: Undefined values converted to empty string
    my $result2 = $users->register_user({
        user_id => 'undef-test',
        moniker => 'UndefTest',
        email => undef,
        phone => undef,
    });
    ok($result2->{success}, 'Handles undefined values');

    my $check2 = $users->get_user('undef-test');
    is($check2->{user}{email}, '', 'Undef email becomes empty string');
    is($check2->{user}{phone}, '', 'Undef phone becomes empty string');

    # Test 3: Internal whitespace preserved in valid data
    my $result3 = $users->register_user({
        user_id => 'internal-space-test',
        moniker => 'InternalSpace',
        organization => 'ACME Corporation Inc',  # Internal spaces are OK
    });
    ok($result3->{success}, 'Accepts internal whitespace in text fields');

    my $check3 = $users->get_user('internal-space-test');
    is($check3->{user}{organization}, 'ACME Corporation Inc', 'Internal spaces preserved');
};

# ==============================================================================
# Test Group 7: Required vs Optional Fields
# ==============================================================================
subtest 'Required fields enforcement' => sub {
    my ($users, $storage_dir) = setup_test_env('database');

    # Test 1: Missing required field (moniker)
    my $result1 = $users->register_user({
        user_id => 'requiredtest1',
        # moniker is missing
    });
    ok(!$result1->{success}, 'Fails without required moniker');
    like($result1->{message}, qr/moniker.*required/i, 'Error says moniker is required');

    # Test 2: All required fields provided, optional missing
    my $result2 = $users->register_user({
        user_id => 'requiredtest2',
        moniker => 'RequiredTest2',
        # email, phone, first_name, last_name all missing (optional)
    });
    ok($result2->{success}, 'Succeeds with only required fields');

    my $check2 = $users->get_user('requiredtest2');
    is($check2->{user}{email}, '', 'Optional email is default');
    is($check2->{user}{phone}, '', 'Optional phone is default');
};

# ==============================================================================
# Test Group 8: Readonly Field Protection
# ==============================================================================
subtest 'Readonly fields in validation' => sub {
    my ($users, $storage_dir) = setup_test_env('file');

    # Create user
    $users->register_user({
        user_id => 'readonlytest',
        moniker => 'ReadOnlyTest',
        email => 'original@example.com',
    });

    my $original = $users->get_user('readonlytest');
    my $original_created = $original->{user}{created_date};

    # Try to update readonly field
    my $result = $users->update_user('readonlytest', {
        created_date => '2025-01-01 00:00:00',  # Readonly
        email => 'updated@example.com',
    });

    ok($result->{success}, 'Update succeeds');

    my $updated = $users->get_user('readonlytest');
    is($updated->{user}{created_date}, $original_created, 'created_date unchanged');
    is($updated->{user}{email}, 'updated@example.com', 'Email updated');
};


# ==============================================================================
# Test Group 9: USERS_SKIP_VALIDATION Environment Variable
# ==============================================================================
subtest 'USERS_SKIP_VALIDATION environment variable' => sub {
    my ($users, $storage_dir) = setup_test_env('database');

    local $ENV{USERS_SKIP_VALIDATION} = 1;

    my $result = $users->register_user({
        user_id  => 'skiptest',
        moniker  => 'SkipTest',
        email    => 'not-an-email',
        phone    => '123',
    });
    ok($result->{success}, 'register_user succeeds when USERS_SKIP_VALIDATION is set');
    ok(!$result->{warnings}, 'No warnings generated when validation skipped');

    my $user = $users->get_user('skiptest');
    is($user->{user}{email}, 'not-an-email', 'Invalid data stored as-is when validation skipped');
};

# ==============================================================================
# Test Group 10: Date Validator
# ==============================================================================
subtest 'Date validator (term_ends)' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);
    my $config = {
        storage_dir             => $storage_dir,
        backend                 => 'database',
        include_standard_fields => [qw/ term_ends /],
    };
    my $setup_result = Concierge::Users->setup($config);
    my $users = Concierge::Users->new($setup_result->{config_file});

    # Valid date
    my $result1 = $users->register_user({
        user_id   => 'datetest1',
        moniker   => 'DateTest1',
        term_ends => '2027-12-31',
    });
    ok($result1->{success}, 'Accepts valid YYYY-MM-DD date');
    ok(!$result1->{warnings}, 'No warnings for valid date');

    my $check1 = $users->get_user('datetest1');
    is($check1->{user}{term_ends}, '2027-12-31', 'Date stored correctly');

    # Invalid date format (must_validate=0 for term_ends, so warns rather than fails)
    my $result2 = $users->register_user({
        user_id   => 'datetest2',
        moniker   => 'DateTest2',
        term_ends => '31/12/2027',
    });
    ok($result2->{success}, 'Succeeds with invalid date format (must_validate=0)');
    ok($result2->{warnings}, 'Has warnings about invalid date format');
    like($result2->{warnings}[0], qr/date/i, 'Warning mentions date');
};

# ==============================================================================
# Test Group 11: Timestamp Validator
# ==============================================================================
subtest 'Timestamp validator (last_login_date)' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);
    my $config = {
        storage_dir => $storage_dir,
        backend     => 'database',
    };
    my $setup_result = Concierge::Users->setup($config);
    my $users = Concierge::Users->new($setup_result->{config_file});

    # Valid space-separated timestamp
    my $result1 = $users->register_user({
        user_id         => 'tstest1',
        moniker         => 'TSTest1',
        last_login_date => '2027-06-15 14:30:00',
    });
    ok($result1->{success}, 'Accepts valid YYYY-MM-DD HH:MM:SS timestamp');
    ok(!$result1->{warnings}, 'No warnings for valid timestamp');

    my $check1 = $users->get_user('tstest1');
    is($check1->{user}{last_login_date}, '2027-06-15 14:30:00', 'Timestamp stored correctly');

    # Valid ISO 8601 T-separated timestamp
    my $result2 = $users->register_user({
        user_id         => 'tstest2',
        moniker         => 'TSTest2',
        last_login_date => '2027-06-15T14:30:00',
    });
    ok($result2->{success}, 'Accepts ISO 8601 T-separated timestamp');

    # Invalid timestamp format (must_validate=0, so warns)
    my $result3 = $users->register_user({
        user_id         => 'tstest3',
        moniker         => 'TSTest3',
        last_login_date => '2027-06-15 14:30',
    });
    ok($result3->{success}, 'Succeeds with invalid timestamp format (must_validate=0)');
    ok($result3->{warnings}, 'Has warnings about invalid timestamp');
    like($result3->{warnings}[0], qr/timestamp/i, 'Warning mentions timestamp');
};

# ==============================================================================
# Test Group 12: Boolean Validator
# ==============================================================================
subtest 'Boolean validator (text_ok)' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);
    my $config = {
        storage_dir             => $storage_dir,
        backend                 => 'database',
        include_standard_fields => [qw/ text_ok /],
    };
    my $setup_result = Concierge::Users->setup($config);
    my $users = Concierge::Users->new($setup_result->{config_file});

    # Valid boolean: 1
    my $result1 = $users->register_user({
        user_id => 'booltest1',
        moniker => 'BoolTest1',
        text_ok => '1',
    });
    ok($result1->{success}, 'Accepts boolean value 1');
    ok(!$result1->{warnings}, 'No warnings for boolean 1');

    my $check1 = $users->get_user('booltest1');
    is($check1->{user}{text_ok}, '1', 'Boolean 1 stored correctly');

    # Valid boolean: 0
    my $result2 = $users->register_user({
        user_id => 'booltest2',
        moniker => 'BoolTest2',
        text_ok => '0',
    });
    ok($result2->{success}, 'Accepts boolean value 0');

    # Invalid boolean value (must_validate=0, so warns)
    my $result3 = $users->register_user({
        user_id => 'booltest3',
        moniker => 'BoolTest3',
        text_ok => 'yes',
    });
    ok($result3->{success}, 'Succeeds with invalid boolean (must_validate=0)');
    ok($result3->{warnings}, 'Has warnings about invalid boolean');
    like($result3->{warnings}[0], qr/boolean/i, 'Warning mentions boolean');
};

# ==============================================================================
# Test Group 13: Integer Validator
# ==============================================================================
subtest 'Integer validator (app field)' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);
    my $config = {
        storage_dir             => $storage_dir,
        backend                 => 'database',
        include_standard_fields => [],
        app_fields              => [
            { field_name => 'score', type => 'integer', required => 0, label => 'Score' },
        ],
    };
    my $setup_result = Concierge::Users->setup($config);
    my $users = Concierge::Users->new($setup_result->{config_file});

    # Valid integer
    my $result1 = $users->register_user({
        user_id => 'inttest1',
        moniker => 'IntTest1',
        score   => '42',
    });
    ok($result1->{success}, 'Accepts valid integer');
    ok(!$result1->{warnings}, 'No warnings for valid integer');

    my $check1 = $users->get_user('inttest1');
    is($check1->{user}{score}, '42', 'Integer stored correctly');

    # Valid negative integer
    my $result2 = $users->register_user({
        user_id => 'inttest2',
        moniker => 'IntTest2',
        score   => '-5',
    });
    ok($result2->{success}, 'Accepts valid negative integer');

    # Invalid: float (must_validate not set, so warns)
    my $result3 = $users->register_user({
        user_id => 'inttest3',
        moniker => 'IntTest3',
        score   => '3.14',
    });
    ok($result3->{success}, 'Succeeds with non-integer value (no must_validate)');
    ok($result3->{warnings}, 'Has warnings about invalid integer');
    like($result3->{warnings}[0], qr/whole number/i, 'Warning mentions whole number');
};

# ==============================================================================
# Test Group 14: Enum Validator (user_status and access_level)
# ==============================================================================
subtest 'Enum validator (user_status and access_level)' => sub {
    my ($users, $storage_dir) = setup_test_env('database');

    # Valid user_status
    my $result1 = $users->register_user({
        user_id     => 'enumtest1',
        moniker     => 'EnumTest1',
        user_status => 'OK',
    });
    ok($result1->{success}, 'Accepts valid user_status value');

    my $check1 = $users->get_user('enumtest1');
    is($check1->{user}{user_status}, 'OK', 'Valid user_status stored correctly');

    # Invalid user_status (must_validate=1, so fails)
    my $result2 = $users->register_user({
        user_id     => 'enumtest2',
        moniker     => 'EnumTest2',
        user_status => 'banned',
    });
    ok(!$result2->{success}, 'Rejects invalid user_status value (must_validate=1)');
    like($result2->{message}, qr/must be one of/i, 'Error mentions valid options');

    # Valid access_level
    my $result3 = $users->register_user({
        user_id      => 'enumtest3',
        moniker      => 'EnumTest3',
        access_level => 'admin',
    });
    ok($result3->{success}, 'Accepts valid access_level value');
};

done_testing();

