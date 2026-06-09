#!/usr/bin/env perl
# Test: Setup configuration for all backends

use v5.36;
use Test2::V0;
use File::Temp qw/ tempdir /;
use File::Path qw/ remove_tree /;
use JSON::PP qw/ decode_json /;

# Load main module
use Concierge::Users;

# Helper function to create a temporary directory
my $temp_base = tempdir(CLEANUP => 1);

# Helper function to create test config
sub make_config {
    my ($storage_dir, $backend, $extra) = @_;

    my $config = {
        storage_dir => $storage_dir,
        backend => $backend,
        include_standard_fields => 'all',
        %{$extra || {}},
    };

    return $config;
}

# ==============================================================================
# Test Group 1: Database Backend Setup
# ==============================================================================
subtest 'Database backend setup' => sub {
    my $storage_dir = "$temp_base/db-test";
    my $config = make_config($storage_dir, 'database');

    # Test 1: Successful setup
    my $result = Concierge::Users->setup($config);
    ok($result->{success}, 'Database setup succeeds');
    like($result->{message}, qr/configured successfully|successfully/, 'Setup message indicates success');
    ok($result->{config_file}, 'Config file path returned');
    ok(-f $result->{config_file}, 'Config file created');

    # Test 2: Verify config file contents
    open my $fh, '<', $result->{config_file} or die "Cannot read config: $!";
    local $/;
    my $json = <$fh>;
    close $fh;
    my $saved_config = decode_json($json);

    is($saved_config->{backend_module}, 'Concierge::Users::Database', 'Correct backend module saved');
    ok($saved_config->{fields}, 'Fields array saved');
    is(ref $saved_config->{fields}, 'ARRAY', 'Fields is an array');
    ok($saved_config->{field_definitions}, 'Field definitions saved');
    is(ref $saved_config->{field_definitions}, 'HASH', 'Field definitions is a hash');
    is($saved_config->{storage_initialized}, 1, 'Storage initialized flag set');
    like($saved_config->{generated}, qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, 'Timestamp generated');

    # Test 3: Verify database file created
    my $db_file = "$storage_dir/users.db";
    ok(-f $db_file, 'Database file created');

    # Test 4: Verify can instantiate from config
    my $users = Concierge::Users->new($result->{config_file});
    ok($users, 'Users object instantiated from config');
    isa_ok($users, 'Concierge::Users');

    # Cleanup
    remove_tree($storage_dir);
};

# ==============================================================================
# Test Group 2: File Backend Setup (CSV)
# ==============================================================================
subtest 'File backend setup (CSV)' => sub {
    my $storage_dir = "$temp_base/csv-test";
    my $config = make_config($storage_dir, 'file', { file_format => 'csv' });

    # Test 1: Successful setup
    my $result = Concierge::Users->setup($config);
    ok($result->{success}, 'CSV file backend setup succeeds');
    ok(-f $result->{config_file}, 'Config file created');

    # Test 2: Verify CSV file created
    my $csv_file = "$storage_dir/users.csv";
    ok(-f $csv_file, 'CSV file created');

    # Test 3: Verify CSV header
    open my $fh, '<:encoding(UTF-8)', $csv_file or die "Cannot read CSV: $!";
    my $header = <$fh>;
    close $fh;
    like($header, qr/user_id/, 'CSV header contains user_id');

    # Test 4: Verify can instantiate from config
    my $users = Concierge::Users->new($result->{config_file});
    ok($users, 'Users object instantiated from config');

    # Cleanup
    remove_tree($storage_dir);
};

# ==============================================================================
# Test Group 3: File Backend Setup (TSV)
# ==============================================================================
subtest 'File backend setup (TSV)' => sub {
    my $storage_dir = "$temp_base/tsv-test";
    my $config = make_config($storage_dir, 'file', { file_format => 'tsv' });

    my $result = Concierge::Users->setup($config);
    ok($result->{success}, 'TSV file backend setup succeeds');

    my $tsv_file = "$storage_dir/users.tsv";
    ok(-f $tsv_file, 'TSV file created');

    my $users = Concierge::Users->new($result->{config_file});
    ok($users, 'Users object instantiated from config');

    # Cleanup
    remove_tree($storage_dir);
};

# ==============================================================================
# Test Group 4: YAML Backend Setup
# ==============================================================================
subtest 'YAML backend setup' => sub {
    my $storage_dir = "$temp_base/yaml-test";
    my $config = make_config($storage_dir, 'yaml');

    my $result = Concierge::Users->setup($config);
    ok($result->{success}, 'YAML backend setup succeeds');
    ok(-f $result->{config_file}, 'Config file created');

    # Note: YAML backend doesn't create a file until first user is added
    ok(-d $storage_dir, 'Storage directory exists');

    my $users = Concierge::Users->new($result->{config_file});
    ok($users, 'Users object instantiated from config');

    # Cleanup
    remove_tree($storage_dir);
};

# ==============================================================================
# Test Group 5: Field Selection Options
# ==============================================================================
subtest 'Field selection options' => sub {
    # Test 1: All standard fields (default)
    my $storage_dir1 = "$temp_base/all-fields";
    my $config1 = make_config($storage_dir1, 'database');

    my $result1 = Concierge::Users->setup($config1);
    ok($result1->{success}, 'Setup with all standard fields');

    my $users1 = Concierge::Users->new($result1->{config_file});
    ok(scalar(@{$users1->{fields}}) > 10, 'Includes many fields');

    remove_tree($storage_dir1);

    # Test 2: Specific standard fields
    my $storage_dir2 = "$temp_base/specific-fields";
    my $config2 = make_config($storage_dir2, 'database', {
        include_standard_fields => [qw/ email phone /]
    });

    my $result2 = Concierge::Users->setup($config2);
    ok($result2->{success}, 'Setup with specific standard fields');

    my $users2 = Concierge::Users->new($result2->{config_file});
    ok((grep { $_ eq 'email' } @{$users2->{fields}}), 'Includes email field');
    ok((grep { $_ eq 'phone' } @{$users2->{fields}}), 'Includes phone field');

    # Cleanup
    remove_tree($storage_dir2);
};

# ==============================================================================
# Test Group 6: Custom App Fields
# ==============================================================================
subtest 'Custom app fields' => sub {
    my $storage_dir = "$temp_base/app-fields";
    my $config = make_config($storage_dir, 'database', {
        app_fields => [
            { field_name => 'favorite_color', type => 'text', max_length => 50 },
            { field_name => 'age', type => 'integer' },
            'simple_field',  # Simple string field
        ]
    });

    my $result = Concierge::Users->setup($config);
    ok($result->{success}, 'Setup with custom app fields');

    my $users = Concierge::Users->new($result->{config_file});
    ok((grep { $_ eq 'favorite_color' } @{$users->{fields}}), 'Includes favorite_color');
    ok((grep { $_ eq 'age' } @{$users->{fields}}), 'Includes age');
    ok((grep { $_ eq 'simple_field' } @{$users->{fields}}), 'Includes simple_field');

    # Cleanup
    remove_tree($storage_dir);
};

# ==============================================================================
# Test Group 7: Setup Error Handling
# ==============================================================================
subtest 'Setup error handling' => sub {
    # Test 1: Missing storage_dir - fatal error, should croak
    like(
        dies { Concierge::Users->setup({ backend => 'database' }) },
        qr/storage_dir/,
        'Croaks with storage_dir error when storage_dir missing'
    );

    # Test 2: Missing backend - fatal error, should croak
    like(
        dies { Concierge::Users->setup({ storage_dir => '/tmp/test' }) },
        qr/backend/,
        'Croaks with backend error when backend missing'
    );

    # Test 3: Invalid backend - fatal error, should croak
    like(
        dies {
            Concierge::Users->setup({
                storage_dir => '/tmp/test',
                backend => 'invalid'
            })
        },
        qr/Invalid backend|backend/,
        'Croaks with error for invalid backend'
    );

    # Test 4: Invalid file format - backend returns error hashref
    my $storage_dir = tempdir(CLEANUP => 1);
    my $result4 = Concierge::Users->setup({
        storage_dir => $storage_dir,
        backend => 'file',
        file_format => 'xml'
    });
    ok(!$result4->{success}, 'Fails with invalid file format');
    like($result4->{message}, qr/file_format|invalid/, 'Error mentions file_format');
};

# ==============================================================================
# Test Group 8: Field Overrides - Basic Enum Overrides
# ==============================================================================
subtest 'Field overrides - basic enum overrides' => sub {
    use Capture::Tiny qw/ capture_stderr /;

    my $storage_dir = "$temp_base/enum-overrides";
    my $config = make_config($storage_dir, 'database', {
        field_overrides => [
            {
                field_name => 'user_status',
                options => ['*Active', 'Inactive', 'Suspended', 'Banned'],
                label => 'Account Status',
            },
            {
                field_name => 'prefix',
                options => ['*', 'Gen', 'Col', 'Capt', 'Lt', 'Sgt'],
            },
        ],
    });

    my $result = Concierge::Users->setup($config);
    ok($result->{success}, 'Setup with enum overrides succeeds');

    # Load config and verify overrides
    my $users = Concierge::Users->new($result->{config_file});

    # Check user_status override
    my $status_def = $users->get_field_definition('user_status');
    is($status_def->{label}, 'Account Status', 'Label overridden for user_status');
    is($status_def->{options}, ['*Active', 'Inactive', 'Suspended', 'Banned'],
        'Options overridden for user_status');
    is($status_def->{default}, 'Active', 'Default set to option with *');

    # Check prefix override
    my $prefix_def = $users->get_field_definition('prefix');
    is($prefix_def->{options}, ['*', 'Gen', 'Col', 'Capt', 'Lt', 'Sgt'],
        'Options overridden for prefix');

    # Test validation with overridden values
    my $test_user = {
        user_id => 'test1',
        moniker => 'TestUser',
        user_status => 'Active',
        prefix => 'Capt',
    };

    my $reg_result = $users->register_user($test_user);
    ok($reg_result->{success}, 'User registered with overridden enum values');

    my $get_result = $users->get_user('test1');
    is($get_result->{user}{user_status}, 'Active', 'Overridden value stored');
    is($get_result->{user}{prefix}, 'Capt', 'Overridden prefix stored');

    # Test validation rejects old enum values
    my $bad_user = {
        user_id => 'test2',
        moniker => 'TestUser2',
        user_status => 'Eligible',  # Old value not in new options
    };

    my $bad_result = $users->register_user($bad_user);
    ok(!$bad_result->{success}, 'Rejects value not in overridden options');
    like($bad_result->{message}, qr/Account Status must be one of/, 'Error message includes overridden label');

    # Cleanup
    remove_tree($storage_dir);
};

# ==============================================================================
# Test Group 9: Field Overrides - Type Changes
# ==============================================================================
subtest 'Field overrides - type changes' => sub {
    my $storage_dir = "$temp_base/type-changes";
    my $config = make_config($storage_dir, 'database', {
        field_overrides => [
            {
                field_name => 'title',
                type => 'enum',  # Change from text to enum
                options => ['*Engineer', 'Manager', 'Director', 'Staff'],
                label => 'Job Title',
                required => 1,
            },
        ],
    });

    my $result = Concierge::Users->setup($config);
    ok($result->{success}, 'Setup with type change succeeds');

    my $users = Concierge::Users->new($result->{config_file});
    my $title_def = $users->get_field_definition('title');

    is($title_def->{type}, 'enum', 'Type changed from text to enum');
    is($title_def->{label}, 'Job Title', 'Label overridden');
    is($title_def->{required}, 1, 'Required flag overridden');
    is($title_def->{options}, ['*Engineer', 'Manager', 'Director', 'Staff'],
        'Options set for converted enum field');

    # Test that enum validation works
    my $test_user = {
        user_id => 'emp1',
        moniker => 'Employee',
        title => 'Manager',
    };

    my $reg_result = $users->register_user($test_user);
    ok($reg_result->{success}, 'User registered with converted enum field');

    my $get_result = $users->get_user('emp1');
    is($get_result->{user}{title}, 'Manager', 'Enum value stored correctly');

    # Test validation rejects non-enum values
    my $bad_user = {
        user_id => 'emp2',
        moniker => 'Employee2',
        title => 'Some random text',
    };

    my $bad_result = $users->register_user($bad_user);
    ok(!$bad_result->{success}, 'Rejects non-enum value for converted field');

    # Cleanup
    remove_tree($storage_dir);
};

# ==============================================================================
# Test Group 10: Field Overrides - Protected Fields
# ==============================================================================
subtest 'Field overrides - protected fields' => sub {
    use Capture::Tiny qw/ capture_stderr /;

    my $storage_dir = "$temp_base/protected-fields";

    # Blocked attribute on user_id: warns with new message, setup still succeeds
    my $config1 = make_config($storage_dir . '/test1', 'database', {
        field_overrides => [
            {
                field_name => 'user_id',
                max_length => 50,
            },
        ],
    });

    my ($stderr1, $result1) = capture_stderr sub {
        Concierge::Users->setup($config1);
    };

    like($stderr1, qr/Field 'user_id' is protected; ignoring: max_length/,
        'Warns about blocked attribute on protected user_id field');
    ok($result1->{success}, 'Setup still succeeds despite blocked override on protected field');

    # Blocked attribute on created_date: warns, setup succeeds
    my $config2 = make_config($storage_dir . '/test2', 'database', {
        field_overrides => [
            {
                field_name => 'created_date',
                required => 1,
            },
        ],
    });

    my ($stderr2, $result2) = capture_stderr sub {
        Concierge::Users->setup($config2);
    };

    like($stderr2, qr/Field 'created_date' is protected; ignoring: required/,
        'Warns about blocked attribute on protected created_date field');
    ok($result2->{success}, 'Setup succeeds');

    # Blocked attribute on last_mod_date: warns, setup succeeds
    my $config3 = make_config($storage_dir . '/test3', 'database', {
        field_overrides => [
            {
                field_name => 'last_mod_date',
                required => 1,
            },
        ],
    });

    my ($stderr3, $result3) = capture_stderr sub {
        Concierge::Users->setup($config3);
    };

    like($stderr3, qr/Field 'last_mod_date' is protected; ignoring: required/,
        'Warns about blocked attribute on protected last_mod_date field');
    ok($result3->{success}, 'Setup succeeds');

    # Allowed overrides (format_as, label) on protected fields: applied silently
    my $config4 = make_config($storage_dir . '/test4', 'database', {
        field_overrides => [
            { field_name => 'user_id',         format_as => 'uid'      },
            { field_name => 'last_login_date',  format_as => 'dt',
                                                label     => 'Last Login' },
            { field_name => 'last_mod_date',    format_as => 'dt'      },
            { field_name => 'created_date',     label     => 'Created'  },
        ],
    });

    my ($stderr4, $result4) = capture_stderr sub {
        Concierge::Users->setup($config4);
    };

    is($stderr4, '', 'No warning when only format_as/label overridden on protected fields');
    ok($result4->{success}, 'Setup succeeds with allowed overrides on protected fields');

    my $users4 = Concierge::Users->new($result4->{config_file});
    is($users4->get_field_hints('user_id')->{format_as},        'uid',       'format_as applied to user_id');
    is($users4->get_field_hints('last_login_date')->{format_as},'dt',        'format_as applied to last_login_date');
    is($users4->get_field_hints('last_login_date')->{label},    'Last Login','label applied to last_login_date');
    is($users4->get_field_hints('last_mod_date')->{format_as},  'dt',        'format_as applied to last_mod_date');
    is($users4->get_field_hints('created_date')->{label},       'Created',   'label applied to created_date');

    # Cleanup
    remove_tree($storage_dir);
};

# ==============================================================================
# Test Group 11: Field Overrides - Unknown Validator Types
# ==============================================================================
subtest 'Field overrides - unknown validator types' => sub {
    use Capture::Tiny qw/ capture_stderr /;

    my $storage_dir = "$temp_base/unknown-validator";

    my $config = make_config($storage_dir, 'database', {
        field_overrides => [
            {
                field_name => 'organization',
                validate_as => 'unknown_type',  # Invalid validator
            },
        ],
    });

    my ($stderr, $result) = capture_stderr sub {
        Concierge::Users->setup($config);
    };

    like($stderr, qr/unknown validator type 'unknown_type' - falling back to 'text'/,
        'Warns about unknown validator and falls back to text');
    ok($result->{success}, 'Setup still succeeds with unknown validator');

    my $users = Concierge::Users->new($result->{config_file});
    is($users->get_field_definition('organization')->{validate_as}, 'text',
        'Validator fell back to text');

    # Cleanup
    remove_tree($storage_dir);
};

# ==============================================================================
# Test Group 12: Field Overrides - Combined with App Fields
# ==============================================================================
subtest 'Field overrides - combined with app fields' => sub {
    my $storage_dir = "$temp_base/mixed-fields";

    my $config = make_config($storage_dir, 'database', {
        field_overrides => [
            {
                field_name => 'user_status',
                options => ['*Active', 'Inactive'],
            },
        ],
        app_fields => [
            {
                field_name => 'department',
                type => 'enum',
                options => ['*Engineering', 'Sales', 'Marketing'],
            },
        ],
    });

    my $result = Concierge::Users->setup($config);
    ok($result->{success}, 'Setup with both overrides and app fields');

    my $users = Concierge::Users->new($result->{config_file});

    # Check override worked
    is($users->get_field_definition('user_status')->{options}, ['*Active', 'Inactive'],
        'Standard field override applied');

    # Check app field added
    ok($users->get_field_definition('department'), 'App field added');
    is($users->get_field_definition('department')->{type}, 'enum',
        'App field type correct');

    # Test with actual user
    my $test_user = {
        user_id => 'user1',
        moniker => 'TestUser',
        user_status => 'Active',
        department => 'Engineering',
    };

    my $reg_result = $users->register_user($test_user);
    ok($reg_result->{success}, 'User registered with both overridden and app fields');

    # Cleanup
    remove_tree($storage_dir);
};


# ==============================================================================
# Test Group 13: Re-setup Archives Existing Data (all backends)
# ==============================================================================
subtest 'Re-setup archives existing data' => sub {

    # Test 1: Database backend - archive when table has data
    my $db_dir = "$temp_base/db-archive";

    my $r1 = Concierge::Users->setup(make_config($db_dir, 'database'));
    ok($r1->{success}, 'First database setup succeeds');

    my $u1 = Concierge::Users->new($r1->{config_file});
    $u1->{skip_validation} = 1;
    $u1->register_user({ user_id => 'archivetest', moniker => 'ArchiveTest' });

    # Second setup on same storage_dir - should archive the existing data
    my $r2 = Concierge::Users->setup(make_config($db_dir, 'database'));
    ok($r2->{success}, 'Second database setup succeeds (data archived)');

    my $u2 = Concierge::Users->new($r2->{config_file});
    $u2->{skip_validation} = 1;
    is($u2->list_users()->{total_count}, 0, 'New table starts empty after archive');

    remove_tree($db_dir);

    # Test 2: Database backend - re-setup with empty table (no data to archive)
    my $db_dir2 = "$temp_base/db-empty-reuse";

    my $r3 = Concierge::Users->setup(make_config($db_dir2, 'database'));
    ok($r3->{success}, 'First database setup (no users added)');

    # Second setup without any users - triggers empty-table drop path
    my $r4 = Concierge::Users->setup(make_config($db_dir2, 'database'));
    ok($r4->{success}, 'Second database setup with empty table succeeds');

    remove_tree($db_dir2);

    # Test 3: File backend - archive when CSV has data
    my $file_dir = "$temp_base/file-archive";

    my $r5 = Concierge::Users->setup(make_config($file_dir, 'file', { file_format => 'csv' }));
    ok($r5->{success}, 'First file setup succeeds');

    my $u3 = Concierge::Users->new($r5->{config_file});
    $u3->{skip_validation} = 1;
    $u3->register_user({ user_id => 'filearchive', moniker => 'FileArchive' });

    # Second setup - archives the CSV with data
    my $r6 = Concierge::Users->setup(make_config($file_dir, 'file', { file_format => 'csv' }));
    ok($r6->{success}, 'Second file setup succeeds (data archived)');

    my $u4 = Concierge::Users->new($r6->{config_file});
    $u4->{skip_validation} = 1;
    is($u4->list_users()->{total_count}, 0, 'New CSV starts empty after archive');

    remove_tree($file_dir);

    # Test 4: YAML backend - archive when YAML files exist
    my $yaml_dir = "$temp_base/yaml-archive";

    my $r7 = Concierge::Users->setup(make_config($yaml_dir, 'yaml'));
    ok($r7->{success}, 'First YAML setup succeeds');

    my $u5 = Concierge::Users->new($r7->{config_file});
    $u5->{skip_validation} = 1;
    $u5->register_user({ user_id => 'yamlarchive', moniker => 'YAMLArchive' });

    # Second setup - archives existing YAML files
    my $r8 = Concierge::Users->setup(make_config($yaml_dir, 'yaml'));
    ok($r8->{success}, 'Second YAML setup succeeds (data archived)');

    my $u6 = Concierge::Users->new($r8->{config_file});
    $u6->{skip_validation} = 1;
    is($u6->list_users()->{total_count}, 0, 'New YAML storage starts empty after archive');

    remove_tree($yaml_dir);
};

done_testing();

