#!/usr/bin/env perl
# Test: Field metadata and field definitions

use v5.36;
use Test2::V0;
use File::Temp qw/ tempdir /;
use Concierge::Users;
use Concierge::Users::Meta;

# ==============================================================================
# Test Group 1: init_field_meta
# ==============================================================================
subtest 'init_field_meta' => sub {
    # Test 1: All standard fields
    my $config1 = {
        include_standard_fields => 'all',
        app_fields => [],
    };

    my $field_meta1 = Concierge::Users::Meta::init_field_meta($config1);

    ok($field_meta1, 'init_field_meta returns data');
    is(ref $field_meta1, 'HASH', 'Returns hashref');
    ok($field_meta1->{fields}, 'Has fields key');
    ok($field_meta1->{field_definitions}, 'Has field_definitions key');
    is(ref $field_meta1->{fields}, 'ARRAY', 'Fields is arrayref');
    is(ref $field_meta1->{field_definitions}, 'HASH', 'Field definitions is hashref');

    # Check core fields are present
    my @core_fields = qw/ user_id moniker user_status access_level /;
    for my $field (@core_fields) {
        ok((grep { $_ eq $field } @{$field_meta1->{fields}}), "Core field '$field' present");
    }

    # Check standard fields are included
    ok((grep { $_ eq 'email' } @{$field_meta1->{fields}}), 'email field present');
    ok((grep { $_ eq 'phone' } @{$field_meta1->{fields}}), 'phone field present');

    # Check system fields
    ok((grep { $_ eq 'created_date' } @{$field_meta1->{fields}}), 'created_date present');
    ok((grep { $_ eq 'last_mod_date' } @{$field_meta1->{fields}}), 'last_mod_date present');

    # Test 2: Specific standard fields
    my $config2 = {
        include_standard_fields => [qw/ email phone /],
        app_fields => [],
    };

    my $field_meta2 = Concierge::Users::Meta::init_field_meta($config2);

    ok((grep { $_ eq 'email' } @{$field_meta2->{fields}}), 'Selected email field');
    ok((grep { $_ eq 'phone' } @{$field_meta2->{fields}}), 'Selected phone field');
    ok(!(grep { $_ eq 'first_name' } @{$field_meta2->{fields}}), 'Unselected standard field excluded');

    # Test 3: With app fields
    my $config3 = {
        include_standard_fields => [],
        app_fields => [
            { field_name => 'custom1', type => 'text', max_length => 100 },
            { field_name => 'custom2', type => 'integer' },
            'simple_field',
        ]
    };

    my $field_meta3 = Concierge::Users::Meta::init_field_meta($config3);

    ok((grep { $_ eq 'custom1' } @{$field_meta3->{fields}}), 'Custom field 1 added');
    ok((grep { $_ eq 'custom2' } @{$field_meta3->{fields}}), 'Custom field 2 added');
    ok((grep { $_ eq 'simple_field' } @{$field_meta3->{fields}}), 'Simple field added');
};

# ==============================================================================
# Test Group 2: Field Definitions Structure
# ==============================================================================
subtest 'Field definitions structure' => sub {
    my $config = {
        include_standard_fields => [qw/ email /],
        app_fields => [],
    };

    my $field_meta = Concierge::Users::Meta::init_field_meta($config);
    my $defs = $field_meta->{field_definitions};

    # Test 1: Core field definitions
    ok($defs->{user_id}, 'user_id has definition');
    is($defs->{user_id}{field_name}, 'user_id', 'field_name correct');
    is($defs->{user_id}{label}, 'User ID', 'label correct');
    is($defs->{user_id}{type}, 'text', 'type correct');
    ok($defs->{user_id}{required}, 'required flag set');
    is($defs->{user_id}{max_length}, 30, 'max_length set');

    # Test 2: Standard field definitions
    ok($defs->{email}, 'email has definition');
    is($defs->{email}{type}, 'email', 'email type correct');
    is($defs->{email}{label}, 'Email', 'email label correct');

    # Test 3: System field definitions
    ok($defs->{created_date}, 'created_date has definition');
    is($defs->{created_date}{type}, 'timestamp', 'created_date type correct');
    is($defs->{created_date}{null_value}, '0000-00-00 00:00:00', 'null_value set');

    # Test 4: Enum field with auto-default
    ok($defs->{user_status}, 'user_status has definition');
    is($defs->{user_status}{type}, 'enum', 'user_status is enum');
    ok($defs->{user_status}{options}, 'Has options');
    is(ref $defs->{user_status}{options}, 'ARRAY', 'Options is array');
    ok($defs->{user_status}{default}, 'Auto-set default from options with *');
};

# ==============================================================================
# Test Group 3: App Field Definitions
# ==============================================================================
subtest 'App field definitions' => sub {
    my $config = {
        include_standard_fields => [],
        app_fields => [
            {
                field_name => 'bio',
                type => 'text',
                max_length => 500,
                required => 0,
                label => 'Biography',
            },
            {
                field_name => 'age',
                type => 'integer',
                required => 1,
            },
            'simple_field',
        ]
    };

    my $field_meta = Concierge::Users::Meta::init_field_meta($config);
    my $defs = $field_meta->{field_definitions};

    # Test 1: Detailed app field
    ok($defs->{bio}, 'bio field defined');
    is($defs->{bio}{field_name}, 'bio', 'bio field_name correct');
    is($defs->{bio}{type}, 'text', 'bio type correct');
    is($defs->{bio}{max_length}, 500, 'bio max_length correct');
    is($defs->{bio}{label}, 'Biography', 'bio label correct');
    is($defs->{bio}{category}, 'app', 'bio category is app');

    # Test 2: Minimal app field
    ok($defs->{age}, 'age field defined');
    is($defs->{age}{type}, 'integer', 'age type correct');
    is($defs->{age}{category}, 'app', 'age category is app');

    # Test 3: Simple string app field
    ok($defs->{simple_field}, 'simple_field defined');
    is($defs->{simple_field}{type}, 'text', 'simple field defaults to text');
    is($defs->{simple_field}{category}, 'app', 'simple field category is app');
    is($defs->{simple_field}{label}, 'Simple Field', 'Auto-generated label');
};

# ==============================================================================
# Test Group 4: Field Order Preservation
# ==============================================================================
subtest 'Field order preservation' => sub {
    my $config = {
        include_standard_fields => [qw/ email phone first_name /],
        app_fields => [
            'field1',
            'field2',
        ]
    };

    my $field_meta = Concierge::Users::Meta::init_field_meta($config);
    my @fields = @{$field_meta->{fields}};

    # Core fields come first
    is($fields[0], 'user_id', 'user_id is first');
    is($fields[1], 'moniker', 'moniker is second');

    # Standard fields in specified order
    my $email_idx = -1;
    my $phone_idx = -1;
    my $first_name_idx = -1;

    for my $i (0..$#fields) {
        $email_idx = $i if $fields[$i] eq 'email';
        $phone_idx = $i if $fields[$i] eq 'phone';
        $first_name_idx = $i if $fields[$i] eq 'first_name';
    }

    ok($email_idx > 1, 'Standard fields come after core');
    ok($phone_idx > $email_idx, 'Standard field order preserved');

    # App fields after standard
    my $field1_idx = -1;
    for my $i (0..$#fields) {
        $field1_idx = $i if $fields[$i] eq 'field1';
    }
    ok($field1_idx > $first_name_idx, 'App fields come after standard');

    # System fields at the end
    is($fields[-1], 'created_date', 'created_date is last');
    is($fields[-2], 'last_mod_date', 'last_mod_date is second to last');
};

# ==============================================================================
# Test Group 5: Integration with Setup
# ==============================================================================
subtest 'Field metadata integration with setup' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);

    my $config = {
        storage_dir => $storage_dir,
        backend_class => 'Concierge::Users::SQLite',
        include_standard_fields => [qw/ email phone /],
        app_fields => [
            { field_name => 'custom', type => 'text' },
        ]
    };

    my $result = Concierge::Users->setup($config);
    ok($result->{success}, 'Setup with custom fields succeeds');

    my $users = Concierge::Users->new($result->{config_file});

    # Verify fields in Users object
    ok($users->{fields}, 'Users object has fields');
    is(ref $users->{fields}, 'ARRAY', 'Fields is array');
    ok((grep { $_ eq 'custom' } @{$users->{fields}}), 'Custom field in users object');

    # Verify field definitions
    ok($users->{field_definitions}, 'Users object has field definitions');
    is($users->{field_definitions}{custom}{type}, 'text', 'Custom field definition correct');
};

# ==============================================================================
# Test Group 6: get_field_definition
# ==============================================================================
subtest 'get_field_definition' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);

    my $config = {
        storage_dir => $storage_dir,
        backend_class => 'Concierge::Users::YAML',
        include_standard_fields => [qw/ email /],
    };

    my $result = Concierge::Users->setup($config);
    my $users = Concierge::Users->new($result->{config_file});
    $users->{skip_validation} = 1;

    # Add a user to initialize
    $users->register_user({
        user_id => 'test1',
        moniker => 'Test',
        email => 'test@test.com',
    });

    # Test 1: Get built-in field definition
    my $email_def = $users->get_field_definition('email');
    ok($email_def, 'Got email field definition');
    is($email_def->{field_name}, 'email', 'Field name correct');
    is($email_def->{type}, 'email', 'Type correct');

    # Test 2: Get core field definition
    my $user_id_def = $users->get_field_definition('user_id');
    ok($user_id_def, 'Got user_id definition');
    is($user_id_def->{required}, 1, 'user_id is required');

    # Test 3: Get system field definition
    my $created_def = $users->get_field_definition('created_date');
    ok($created_def, 'Got created_date definition');
    is($created_def->{type}, 'timestamp', 'created_date is timestamp type');

    # Test 4: Non-existent field
    my $missing = $users->get_field_definition('nonexistent');
    ok(!$missing, 'Non-existent field returns undef');
};

# ==============================================================================
# Test Group 7: get_field_hints
# ==============================================================================
subtest 'get_field_hints' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);

    my $config = {
        storage_dir => $storage_dir,
        backend_class => 'Concierge::Users::SQLite',
        include_standard_fields => [qw/ email phone /],
    };

    my $result = Concierge::Users->setup($config);
    my $users = Concierge::Users->new($result->{config_file});
    $users->{skip_validation} = 1;

    $users->register_user({
        user_id => 'test1',
        moniker => 'Test',
        email => 'test@test.com',
    });

    # Get hints for email field
    my $hints = $users->get_field_hints('email');

    ok($hints, 'Got field hints');
    is($hints->{label}, 'Email', 'Label in hints');
    is($hints->{type}, 'email', 'Type in hints');
    is($hints->{required}, 0, 'Required flag in hints');
    is($hints->{max_length}, 255, 'max_length in hints');

    # Get hints for enum field
    my $status_hints = $users->get_field_hints('user_status');
    ok($status_hints, 'Got enum field hints');
    ok($status_hints->{options}, 'Enum field has options');
    is(ref $status_hints->{options}, 'ARRAY', 'Options is array');

    # System fields return hints
    ok($users->get_field_hints('created_date'),    'Got created_date field hints');
    ok($users->get_field_hints('last_login_date'), 'Got last_login_date field hints');
};

# ==============================================================================
# Test Group 8: Enum Default Auto-Setting
# ==============================================================================
subtest 'Enum default auto-setting' => sub {
    my $config = {
        include_standard_fields => [],
        app_fields => [
            {
                field_name => 'priority',
                type => 'enum',
                options => ['*low', 'medium', 'high'],
            }
        ]
    };

    my $field_meta = Concierge::Users::Meta::init_field_meta($config);
    my $defs = $field_meta->{field_definitions};

    is($defs->{priority}{default}, 'low', 'Default auto-set from * option');
    # Note: Custom app fields don't get auto-null_value unless specified
    ok(!exists $defs->{priority}{null_value} || $defs->{priority}{null_value} eq '', 'null_value handling');

    # Test without asterisk
    my $config2 = {
        include_standard_fields => [],
        app_fields => [
            {
                field_name => 'category',
                type => 'enum',
                options => ['option1', 'option2', 'option3'],
            }
        ]
    };

    my $field_meta2 = Concierge::Users::Meta::init_field_meta($config2);
    my $defs2 = $field_meta2->{field_definitions};

    is($defs2->{category}{default}, '', 'No default when no * option');
};

# ==============================================================================
# Test Group 9: Field Name Validation (Reserved Names)
# ==============================================================================
subtest 'Reserved field name handling' => sub {
    my $config = {
        include_standard_fields => [],
        app_fields => [
            'user_id',  # Try to use reserved name
            'email',    # Another reserved name
            'custom1',  # OK
        ]
    };

    # This should generate warnings but not fail
    my $field_meta = Concierge::Users::Meta::init_field_meta($config);

    # Reserved fields should be rejected
    ok(!(grep { $_ eq 'user_id' } @{$field_meta->{fields}}) ||
       (grep { $_ eq 'user_id' } @{$field_meta->{fields}}) == 1, # Only core user_id
       'Duplicate user_id rejected');

    # Custom field should be accepted
    ok((grep { $_ eq 'custom1' } @{$field_meta->{fields}}), 'custom1 accepted');
};


# ==============================================================================
# Test Group 10: Timestamp and Date Utilities
# ==============================================================================
subtest 'Timestamp and date utility methods' => sub {
    my $date = Concierge::Users::Meta::current_date();
    ok($date, 'current_date returns a value');
    like($date, qr/^\d{4}-\d{2}-\d{2}$/, 'current_date returns YYYY-MM-DD format');

    my $ts = Concierge::Users::Meta::current_timestamp();
    ok($ts, 'current_timestamp returns a value');
    like($ts, qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, 'current_timestamp returns YYYY-MM-DD HH:MM:SS');

    my $archive_ts = Concierge::Users::Meta::archive_timestamp();
    ok($archive_ts, 'archive_timestamp returns a value');
    like($archive_ts, qr/^\d{8}_\d{6}$/, 'archive_timestamp returns YYYYMMDD_HHMMSS format');
};

# ==============================================================================
# Test Group 11: Backend config() Methods
# ==============================================================================
subtest 'Backend config() methods' => sub {
    # Test database backend config()
    my $db_dir = tempdir(CLEANUP => 1);
    my $db_result = Concierge::Users->setup({
        storage_dir => $db_dir, backend_class => 'Concierge::Users::SQLite',
        include_standard_fields => [],
    });
    my $db_users = Concierge::Users->new($db_result->{config_file});
    my $db_config = $db_users->{backend}->config();
    ok($db_config, 'Database backend config() returns data');
    ok($db_config->{storage_dir}, 'Database config has storage_dir');

    # Test file backend config()
    my $file_dir = tempdir(CLEANUP => 1);
    my $file_result = Concierge::Users->setup({
        storage_dir => $file_dir, backend_class => 'Concierge::Users::File',
        include_standard_fields => [],
    });
    my $file_users = Concierge::Users->new($file_result->{config_file});
    my $file_config = $file_users->{backend}->config();
    ok($file_config, 'File backend config() returns data');
    ok($file_config->{storage_dir}, 'File config has storage_dir');

    # Test YAML backend config()
    my $yaml_dir = tempdir(CLEANUP => 1);
    my $yaml_result = Concierge::Users->setup({
        storage_dir => $yaml_dir, backend_class => 'Concierge::Users::YAML',
        include_standard_fields => [],
    });
    my $yaml_users = Concierge::Users->new($yaml_result->{config_file});
    my $yaml_config = $yaml_users->{backend}->config();
    ok($yaml_config, 'YAML backend config() returns data');
    ok($yaml_config->{storage_dir}, 'YAML config has storage_dir');
};

# ==============================================================================
# Test Group 12: Class Array Methods
# ==============================================================================
subtest 'Class array access methods' => sub {
    my @core    = Concierge::Users::Meta::user_core_fields();
    my @standard = Concierge::Users::Meta::user_standard_fields();
    my @system  = Concierge::Users::Meta::user_system_fields();

    ok(scalar @core > 0, 'user_core_fields returns fields');
    ok((grep { $_ eq 'user_id'  } @core), 'user_id in core fields');
    ok((grep { $_ eq 'moniker'  } @core), 'moniker in core fields');

    ok(scalar @standard > 0, 'user_standard_fields returns fields');
    ok((grep { $_ eq 'email' }  @standard), 'email in standard fields');
    ok((grep { $_ eq 'phone' }  @standard), 'phone in standard fields');

    ok(scalar @system > 0, 'user_system_fields returns fields');
    ok((grep { $_ eq 'last_login_date' } @system), 'last_login_date in system fields');
    ok((grep { $_ eq 'created_date'    } @system), 'created_date in system fields');
    ok((grep { $_ eq 'last_mod_date'   } @system), 'last_mod_date in system fields');
    ok(!(grep { $_ eq 'last_login_date' } @standard), 'last_login_date not in standard fields');
};

# ==============================================================================
# Test Group 11: get_user_fields
# ==============================================================================
subtest 'get_user_fields' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);
    my $config = {
        storage_dir             => $storage_dir,
        backend_class           => 'Concierge::Users::SQLite',
        include_standard_fields => [qw/ email phone /],
    };
    my $result = Concierge::Users->setup($config);
    my $users  = Concierge::Users->new($result->{config_file});

    my $fields = $users->get_user_fields();

    ok($fields, 'get_user_fields returns a value');
    is(ref $fields, 'ARRAY', 'get_user_fields returns arrayref');
    ok((grep { $_ eq 'user_id' } @$fields), 'user_id in fields');
    ok((grep { $_ eq 'email'   } @$fields), 'email in fields');
    ok((grep { $_ eq 'phone'   } @$fields), 'phone in fields');
};

# ==============================================================================
# Test Group 12: show_config
# ==============================================================================
subtest 'show_config' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);
    my $config = {
        storage_dir             => $storage_dir,
        backend_class           => 'Concierge::Users::SQLite',
        include_standard_fields => [qw/ email /],
    };
    my $setup_result = Concierge::Users->setup($config);
    my $users = Concierge::Users->new($setup_result->{config_file});

    # Test 1: Success case
    my $result = $users->show_config();
    ok($result->{success}, 'show_config returns success');
    ok($result->{config_file}, 'show_config returns config_file path');
    like($result->{config}, qr/Configuration|Field Definitions/i, 'show_config returns YAML content');

    # Test 2: Error case - non-existent output_path
    my $err_result = $users->show_config(output_path => '/nonexistent/path/to/file.yaml');
    ok(!$err_result->{success}, 'show_config fails with non-existent yaml file');
    like($err_result->{message}, qr/not found/i, 'Error message mentions not found');

    # Test 3: Error case - called on non-backend object
    my $bare = bless {}, 'Concierge::Users';
    my $bare_result = $bare->show_config();
    ok(!$bare_result->{success}, 'show_config fails without backend');
    like($bare_result->{message}, qr/must be called on a Users instance/i, 'Error mentions instance requirement');
};

# ==============================================================================
# Test Group 13: show_default_config
# ==============================================================================
subtest 'show_default_config' => sub {
    # Capture stdout to avoid polluting test output
    my $output = '';
    {
        open(local *STDOUT, '>', \$output) or die "Cannot redirect STDOUT: $!";
        Concierge::Users::Meta->show_default_config();
    }
    # show_default_config reads from __DATA__ and prints it
    # Just verify it doesn't die and produces some output (or DATA was already consumed)
    ok(1, 'show_default_config does not die');
};

# ==============================================================================
# Test Group 14: init_field_meta with string-form include_standard_fields
# ==============================================================================
subtest 'init_field_meta with comma-separated string' => sub {
    my $config = {
        include_standard_fields => 'email, phone, first_name',
        app_fields => [],
    };

    my $field_meta = Concierge::Users::Meta::init_field_meta($config);

    ok($field_meta, 'init_field_meta returns data for string input');
    ok((grep { $_ eq 'email'      } @{$field_meta->{fields}}), 'email field included');
    ok((grep { $_ eq 'phone'      } @{$field_meta->{fields}}), 'phone field included');
    ok((grep { $_ eq 'first_name' } @{$field_meta->{fields}}), 'first_name field included');
    ok(!(grep { $_ eq 'last_name' } @{$field_meta->{fields}}), 'last_name excluded (not requested)');

    # Also test semicolon separator
    my $config2 = {
        include_standard_fields => 'email;phone',
        app_fields => [],
    };
    my $field_meta2 = Concierge::Users::Meta::init_field_meta($config2);
    ok((grep { $_ eq 'email' } @{$field_meta2->{fields}}), 'Semicolon-separated: email included');
    ok((grep { $_ eq 'phone' } @{$field_meta2->{fields}}), 'Semicolon-separated: phone included');
};

# ==============================================================================
# Test Group 15: init_field_meta non-standard field warning
# ==============================================================================
subtest 'init_field_meta non-standard field name warning' => sub {
    use Test2::Tools::Warnings qw/ warning /;

    my $config = {
        include_standard_fields => [qw/ email nosuchfield /],
        app_fields => [],
    };

    # carp generates a warning - verify it happens
    my $w = warning {
        Concierge::Users::Meta::init_field_meta($config);
    };

    like($w, qr/Non-standard field requested: nosuchfield/i,
        'Warning generated for unknown standard field name');

    # Only valid fields should be included
    my $field_meta = Concierge::Users::Meta::init_field_meta($config);
    ok((grep { $_ eq 'email'       } @{$field_meta->{fields}}), 'Valid field email included');
    ok(!(grep { $_ eq 'nosuchfield'} @{$field_meta->{fields}}), 'Unknown field excluded from fields list');
};

# ==============================================================================
# Test Group 16: labelize edge cases
# ==============================================================================
subtest 'labelize edge cases' => sub {
    # Normal case
    my $label1 = Concierge::Users::Meta::labelize('first_name');
    is($label1, 'First Name', 'Converts underscore to title case');

    my $label2 = Concierge::Users::Meta::labelize('user_id');
    is($label2, 'User Id', 'Converts user_id correctly');

    # Edge case: undef argument
    my $label3 = Concierge::Users::Meta::labelize(undef);
    ok(!defined $label3, 'Returns undef for undef input');

    # Edge case: empty string
    my $label4 = Concierge::Users::Meta::labelize('');
    ok(!defined $label4, 'Returns undef for empty string input');
};

# ==============================================================================
# Test Group 17: _yaml_scalar_value edge cases
# ==============================================================================
subtest '_yaml_scalar_value edge cases' => sub {
    # undef
    is(Concierge::Users::Meta::_yaml_scalar_value(undef),  'null', 'undef becomes null');

    # empty string
    is(Concierge::Users::Meta::_yaml_scalar_value(''),     '""',   'Empty string becomes ""');

    # integer
    is(Concierge::Users::Meta::_yaml_scalar_value(42),     '42',   'Integer passes through');

    # Simple word (no spaces)
    is(Concierge::Users::Meta::_yaml_scalar_value('hello'), 'hello', 'Simple word passes through');

    # String with spaces gets quoted
    is(Concierge::Users::Meta::_yaml_scalar_value('hello world'), '"hello world"',
        'String with spaces is quoted');

    # Negative integer
    is(Concierge::Users::Meta::_yaml_scalar_value(-5), '-5', 'Negative integer passes through');
};

# ==============================================================================
# Test Group 18: format_as property
# ==============================================================================
subtest 'format_as in field definitions and get_field_hints' => sub {
    my $storage_dir = tempdir(CLEANUP => 1);

    my $config = {
        storage_dir             => $storage_dir,
        backend_class           => 'Concierge::Users::SQLite',
        include_standard_fields => [qw/ email phone text_ok term_ends prefix suffix /],
        app_fields => [
            {
                field_name => 'widget_type',
                type       => 'enum',
                options    => ['*basic', 'pro'],
                format_as  => 'sel',          # app's own native token
            },
            {
                field_name => 'bio',
                type       => 'text',
                format_as  => 'textarea',     # app's own native token
            },
            {
                field_name => 'score',
                type       => 'integer',
                format_as  => 'number',       # Concierge convention
            },
            {
                field_name => 'no_format',    # deliberately no format_as
                type       => 'text',
            },
        ],
        field_overrides => [
            {
                field_name => 'email',
                format_as  => 't',            # override with app token
            },
        ],
    };

    my $result = Concierge::Users->setup($config);
    my $users  = Concierge::Users->new($result->{config_file});

    # --- Built-in convention values ---

    my $h = $users->get_field_hints('user_id');
    is($h->{format_as}, 'text', 'user_id format_as is text');

    $h = $users->get_field_hints('moniker');
    is($h->{format_as}, 'text', 'moniker format_as is text');

    $h = $users->get_field_hints('user_status');
    is($h->{format_as}, 'options', 'user_status (enum) format_as is options');

    $h = $users->get_field_hints('access_level');
    is($h->{format_as}, 'options', 'access_level (enum) format_as is options');

    $h = $users->get_field_hints('prefix');
    is($h->{format_as}, 'options', 'prefix (enum) format_as is options');

    $h = $users->get_field_hints('suffix');
    is($h->{format_as}, 'options', 'suffix (enum) format_as is options');

    $h = $users->get_field_hints('phone');
    is($h->{format_as}, 'text', 'phone format_as is text');

    $h = $users->get_field_hints('text_ok');
    is($h->{format_as}, 'boolean', 'text_ok format_as is boolean');

    $h = $users->get_field_hints('term_ends');
    is($h->{format_as}, 'date', 'term_ends format_as is date');

    $h = $users->get_field_hints('last_login_date');
    is($h->{format_as}, 'datetime', 'last_login_date format_as is datetime');

    $h = $users->get_field_hints('last_mod_date');
    is($h->{format_as}, 'datetime', 'last_mod_date format_as is datetime');

    $h = $users->get_field_hints('created_date');
    is($h->{format_as}, 'datetime', 'created_date format_as is datetime');

    # --- App-supplied format_as passes through unchanged ---

    $h = $users->get_field_hints('widget_type');
    is($h->{format_as}, 'sel', 'app enum field: custom token passes through');

    $h = $users->get_field_hints('bio');
    is($h->{format_as}, 'textarea', 'app text field: custom token passes through');

    $h = $users->get_field_hints('score');
    is($h->{format_as}, 'number', 'app integer field: convention value passes through');

    # --- Missing format_as returns undef ---

    $h = $users->get_field_hints('no_format');
    ok(!defined $h->{format_as}, 'app field with no format_as returns undef');

    # --- field_overrides format_as passes through ---

    $h = $users->get_field_hints('email');
    is($h->{format_as}, 't', 'field_overrides format_as passes through unchanged');
};

done_testing();

