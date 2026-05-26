#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;
use File::Temp qw(tempdir);
use File::Spec;

use Concierge::Desk::Setup;

# Create temporary directory for testing
my $test_dir = tempdir(CLEANUP => 1);

subtest 'build_quick_desk basic functionality' => sub {
    my $result = Concierge::Desk::Setup::build_quick_desk(
        $test_dir,
        ['custom_field1', 'custom_field2'],  # app_fields
    );

    ok $result->{success}, 'build_quick_desk succeeds';
    ok -d $test_dir, 'desk directory exists';
    ok -f File::Spec->catfile($test_dir, 'auth.pwd'), 'auth file created';
    ok -f File::Spec->catfile($test_dir, 'concierge.conf'), 'concierge.conf created';
    ok -f File::Spec->catfile($test_dir, 'users-config.json'), 'users-config.json created';
};

subtest 'build_quick_desk validates required parameters' => sub {
    my $temp_dir = tempdir(CLEANUP => 1);

    # Missing desk_location
    my $result = Concierge::Desk::Setup::build_quick_desk(
        undef,
    );
    ok !$result->{success}, 'fails without desk_location';
    like $result->{message}, qr/desk_location/i, 'error mentions desk_location';

};

subtest 'build_quick_desk with minimal configuration' => sub {
    my $temp_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_quick_desk(
        $temp_dir,
    );

    ok $result->{success}, 'build_quick_desk succeeds with minimal config';
    ok -f File::Spec->catfile($temp_dir, 'concierge.conf'), 'config created';
};

subtest 'build_quick_desk creates directory structure' => sub {
    my $temp_dir = tempdir(CLEANUP => 1);
    my $desk_dir = File::Spec->catdir($temp_dir, 'new_desk');

    my $result = Concierge::Desk::Setup::build_quick_desk(
        $desk_dir,
    );

    ok $result->{success}, 'build_quick_desk creates missing directory';
    ok -d $desk_dir, 'new desk directory created';
};


# ==============================================================================
# build_desk - advanced setup
# ==============================================================================

subtest 'build_desk basic database backend' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        storage  => { base_dir => $desk_dir },
        sessions => { backend  => 'database' },
        users    => { backend  => 'database', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with database backend succeeds';
    like $result->{message}, qr/Concierge desk built/i, 'success message';
    is $result->{desk}, $desk_dir, 'desk path returned';
    ok $result->{config}, 'config hashref returned';
    ok -f File::Spec->catfile($desk_dir, 'concierge.conf'), 'concierge.conf created';
    ok -f File::Spec->catfile($desk_dir, 'auth.pwd'), 'auth.pwd created';
};

subtest 'build_desk with file sessions backend' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        storage  => { base_dir => $desk_dir },
        sessions => { backend  => 'file' },
        users    => { backend  => 'database', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with file sessions backend succeeds';
    ok -f File::Spec->catfile($desk_dir, 'concierge.conf'), 'config file created';
};

subtest 'build_desk with yaml users backend' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        storage  => { base_dir => $desk_dir },
        sessions => { backend  => 'database' },
        users    => { backend  => 'yaml', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with yaml users backend succeeds';
    ok -f File::Spec->catfile($desk_dir, 'concierge.conf'), 'config file created';
};

subtest 'build_desk with file users backend' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        storage  => { base_dir => $desk_dir },
        sessions => { backend  => 'database' },
        users    => { backend  => 'file', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with file users backend succeeds';
};

subtest 'build_desk with separate storage directories' => sub {
    my $base_dir     = tempdir(CLEANUP => 1);
    my $sessions_dir = File::Spec->catdir($base_dir, 'sessions');
    my $users_dir    = File::Spec->catdir($base_dir, 'users');

    my $result = Concierge::Desk::Setup::build_desk({
        storage  => {
            base_dir     => $base_dir,
            sessions_dir => $sessions_dir,
            users_dir    => $users_dir,
        },
        sessions => { backend => 'database' },
        users    => { backend => 'database', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with separate dirs succeeds';
    ok -d $sessions_dir, 'sessions directory created';
    ok -d $users_dir,    'users directory created';
    is $result->{config}{sessions_dir}, $sessions_dir, 'sessions_dir in config';
    is $result->{config}{users_dir},    $users_dir,    'users_dir in config';
};

subtest 'build_desk with custom auth file path' => sub {
    my $base_dir = tempdir(CLEANUP => 1);
    my $auth_file = File::Spec->catfile($base_dir, 'passwords.pwd');

    my $result = Concierge::Desk::Setup::build_desk({
        storage  => { base_dir => $base_dir },
        auth     => { file => $auth_file },
        sessions => { backend => 'database' },
        users    => { backend => 'database', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with custom auth file succeeds';
    is $result->{config}{auth_file}, $auth_file, 'custom auth_file in config';
};

subtest 'build_desk with field configuration' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        storage  => { base_dir => $desk_dir },
        sessions => { backend  => 'database' },
        users    => {
            backend                 => 'database',
            include_standard_fields => [qw/ email phone first_name last_name /],
            app_fields              => ['department', 'badge_name'],
            field_overrides         => [
                { field_name => 'email', required => 1 },
            ],
        },
    });

    ok $result->{success}, 'build_desk with field config succeeds';

    # Verify desk can be opened and has correct fields
    use Concierge;
    my $desk = Concierge->open_desk($desk_dir);
    ok $desk->{success}, 'can open the built desk';

    my $users = $desk->{concierge}->users;
    my $fields = $users->get_user_fields();
    ok scalar(grep { $_ eq 'email'       } @$fields), 'email field present';
    ok scalar(grep { $_ eq 'department'  } @$fields), 'app field department present';
    ok scalar(grep { $_ eq 'badge_name'  } @$fields), 'app field badge_name present';
    ok !scalar(grep { $_ eq 'organization' } @$fields), 'organization not included';
};

subtest 'build_desk error cases' => sub {
    # Not a hashref
    my $r1 = Concierge::Desk::Setup::build_desk('not a hash');
    ok !$r1->{success}, 'fails when config is not a hashref';
    like $r1->{message}, qr/hash reference/i, 'error mentions hash reference';

    # Missing storage.base_dir
    my $r2 = Concierge::Desk::Setup::build_desk({});
    ok !$r2->{success}, 'fails when storage.base_dir missing';
    like $r2->{message}, qr/storage\.base_dir/i, 'error mentions storage.base_dir';

    # Missing storage entirely
    my $r3 = Concierge::Desk::Setup::build_desk({ sessions => { backend => 'database' } });
    ok !$r3->{success}, 'fails when storage key missing';
};

subtest 'build_desk can be opened' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk({
        storage  => { base_dir => $desk_dir },
        sessions => { backend  => 'database' },
        users    => {
            backend                 => 'database',
            include_standard_fields => [qw/ email /],
        },
    });
    ok $build->{success}, 'desk built';

    use Concierge;
    my $desk = Concierge->open_desk($desk_dir);
    ok $desk->{success}, 'desk built with build_desk can be opened';
    isa_ok $desk->{concierge}, ['Concierge'], 'returns Concierge object';
};

# ==============================================================================
# validate_setup_config
# ==============================================================================

subtest 'validate_setup_config accepts valid configuration' => sub {
    my $config = {
        storage  => { base_dir => '/some/path' },
        auth     => { file     => '/some/path/auth.pwd' },
        sessions => { backend  => 'database' },
        users    => { backend  => 'database' },
    };

    my $result = Concierge::Desk::Setup::validate_setup_config($config);
    ok $result->{success}, 'valid config passes validation';
    ok !$result->{errors}, 'no errors for valid config';
};

subtest 'validate_setup_config with file backends' => sub {
    my $config = {
        storage  => { base_dir => '/some/path' },
        auth     => { file     => '/some/path/auth.pwd' },
        sessions => { backend  => 'file' },
        users    => { backend  => 'yaml' },
    };
    my $result = Concierge::Desk::Setup::validate_setup_config($config);
    ok $result->{success}, 'file/yaml backends pass validation';
};

subtest 'validate_setup_config detects missing required fields' => sub {
    # Empty config - all required fields missing
    my $r1 = Concierge::Desk::Setup::validate_setup_config({});
    ok !$r1->{success}, 'fails with empty config';
    ok $r1->{errors},   'has errors array';
    ok scalar(@{$r1->{errors}}) >= 4, 'at least 4 errors for empty config';

    # Missing storage.base_dir only
    my $r2 = Concierge::Desk::Setup::validate_setup_config({
        storage  => {},
        auth     => { file    => '/path/auth.pwd' },
        sessions => { backend => 'database' },
        users    => { backend => 'database' },
    });
    ok !$r2->{success}, 'fails when storage.base_dir missing';
    like $r2->{errors}[0], qr/storage\.base_dir/i, 'error mentions storage.base_dir';

    # Missing auth.file only
    my $r3 = Concierge::Desk::Setup::validate_setup_config({
        storage  => { base_dir => '/path' },
        sessions => { backend  => 'database' },
        users    => { backend  => 'database' },
    });
    ok !$r3->{success}, 'fails when auth.file missing';

    # Missing sessions.backend only
    my $r4 = Concierge::Desk::Setup::validate_setup_config({
        storage  => { base_dir => '/path' },
        auth     => { file     => '/path/auth.pwd' },
        users    => { backend  => 'database' },
    });
    ok !$r4->{success}, 'fails when sessions.backend missing';

    # Missing users.backend only
    my $r5 = Concierge::Desk::Setup::validate_setup_config({
        storage  => { base_dir => '/path' },
        auth     => { file     => '/path/auth.pwd' },
        sessions => { backend  => 'database' },
    });
    ok !$r5->{success}, 'fails when users.backend missing';
};

subtest 'validate_setup_config rejects invalid backend values' => sub {
    # Invalid sessions backend
    my $r1 = Concierge::Desk::Setup::validate_setup_config({
        storage  => { base_dir => '/path' },
        auth     => { file     => '/path/auth.pwd' },
        sessions => { backend  => 'redis' },
        users    => { backend  => 'database' },
    });
    ok !$r1->{success}, 'fails with invalid sessions backend';
    like $r1->{errors}[0], qr/sessions\.backend/i, 'error mentions sessions.backend';

    # Invalid users backend
    my $r2 = Concierge::Desk::Setup::validate_setup_config({
        storage  => { base_dir => '/path' },
        auth     => { file     => '/path/auth.pwd' },
        sessions => { backend  => 'database' },
        users    => { backend  => 'oracle' },
    });
    ok !$r2->{success}, 'fails with invalid users backend';
    like $r2->{errors}[0], qr/users\.backend/i, 'error mentions users.backend';

    # Both backends invalid - should have 2 errors
    my $r3 = Concierge::Desk::Setup::validate_setup_config({
        storage  => { base_dir => '/path' },
        auth     => { file     => '/path/auth.pwd' },
        sessions => { backend  => 'bad' },
        users    => { backend  => 'also_bad' },
    });
    ok !$r3->{success}, 'fails with both backends invalid';
    ok scalar(@{$r3->{errors}}) >= 2, 'has at least 2 errors';
};

done_testing;

