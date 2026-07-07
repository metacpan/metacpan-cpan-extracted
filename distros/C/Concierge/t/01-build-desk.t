#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd);

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
        base_dir => $desk_dir,
        auth     => { backend  => 'pwd' },
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
        base_dir => $desk_dir,
        auth     => { backend  => 'pwd' },
        sessions => { backend  => 'file' },
        users    => { backend  => 'database', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with file sessions backend succeeds';
    ok -f File::Spec->catfile($desk_dir, 'concierge.conf'), 'config file created';
};

subtest 'build_desk with yaml users backend' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => $desk_dir,
        auth     => { backend  => 'pwd' },
        sessions => { backend  => 'database' },
        users    => { backend  => 'yaml', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with yaml users backend succeeds';
    ok -f File::Spec->catfile($desk_dir, 'concierge.conf'), 'config file created';
};

subtest 'build_desk with file users backend' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => $desk_dir,
        auth     => { backend  => 'pwd' },
        sessions => { backend  => 'database' },
        users    => { backend  => 'file', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with file users backend succeeds';
};

subtest 'build_desk with separate storage directories' => sub {
    # Each component's own 'dir' setting controls its storage location;
    # an absolute dir is used as-is, independent of base_dir.
    my $base_dir     = tempdir(CLEANUP => 1);
    my $sessions_dir = File::Spec->catdir($base_dir, 'sessions');
    my $users_dir    = File::Spec->catdir($base_dir, 'users');

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => $base_dir,
        auth     => { backend => 'pwd' },
        sessions => { backend => 'database', dir => $sessions_dir },
        users    => { backend => 'database', dir => $users_dir, include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with separate dirs succeeds';
    ok -d $sessions_dir, 'sessions directory created';
    ok -d $users_dir,    'users directory created';
    is $result->{config}{sessions_dir}, $sessions_dir, 'sessions_dir in config';
    is $result->{config}{users_dir},    $users_dir,    'users_dir in config';
};

subtest 'build_desk resolves a relative component dir against base_dir' => sub {
    my $base_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => $base_dir,
        auth     => { backend => 'pwd' },
        sessions => { backend => 'database', dir => 'sessions' },
        users    => { backend => 'database', dir => 'users', include_standard_fields => [] },
    });

    my $expected_sessions_dir = File::Spec->catdir($base_dir, 'sessions');
    my $expected_users_dir    = File::Spec->catdir($base_dir, 'users');

    ok $result->{success}, 'build_desk with relative component dirs succeeds';
    ok -d $expected_sessions_dir, 'relative sessions dir created under base_dir';
    ok -d $expected_users_dir,    'relative users dir created under base_dir';
    is $result->{config}{sessions_dir}, $expected_sessions_dir,
        'relative sessions.dir resolved against base_dir';
    is $result->{config}{users_dir}, $expected_users_dir,
        'relative users.dir resolved against base_dir';
};

subtest 'build_desk with custom auth filename' => sub {
    # auth.file is a filename only (not a path); it resolves under
    # auth.dir (or base_dir if dir is not given).
    my $base_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => $base_dir,
        auth     => { backend => 'pwd', file => 'passwords.pwd' },
        sessions => { backend => 'database' },
        users    => { backend => 'database', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with custom auth filename succeeds';
    is $result->{config}{auth_args}{file},
        File::Spec->catfile($base_dir, 'passwords.pwd'),
        'custom auth filename resolved under base_dir';
};

subtest 'build_desk with custom auth.dir (absolute)' => sub {
    # auth.dir lets the auth store live anywhere, independent of
    # base_dir -- same pattern as sessions.dir/users.dir. An absolute
    # dir is used as-is.
    my $base_dir = tempdir(CLEANUP => 1);
    my $auth_dir = File::Spec->catdir(tempdir(CLEANUP => 1), 'secure-auth');

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => $base_dir,
        auth     => { backend => 'pwd', dir => $auth_dir },
        sessions => { backend => 'database' },
        users    => { backend => 'database', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with custom auth.dir succeeds';
    ok -d $auth_dir, 'auth_dir created';
    ok !-f File::Spec->catfile($base_dir, 'auth.pwd'), 'auth.pwd does NOT land in base_dir';
    is $result->{config}{auth_dir}, $auth_dir, 'auth_dir recorded in config';
    is $result->{config}{auth_args}{file},
        File::Spec->catfile($auth_dir, 'auth.pwd'),
        'default auth filename resolved under custom auth_dir, outside base_dir';
};

subtest 'build_desk resolves a relative auth.dir against base_dir' => sub {
    my $base_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => $base_dir,
        auth     => { backend => 'pwd', dir => 'secure-auth' },
        sessions => { backend => 'database' },
        users    => { backend => 'database', include_standard_fields => [] },
    });

    my $expected_auth_dir = File::Spec->catdir($base_dir, 'secure-auth');

    ok $result->{success}, 'build_desk with relative auth.dir succeeds';
    ok -d $expected_auth_dir, 'relative auth.dir created under base_dir';
    is $result->{config}{auth_dir}, $expected_auth_dir,
        'relative auth.dir resolved against base_dir';
    is $result->{config}{auth_args}{file},
        File::Spec->catfile($expected_auth_dir, 'auth.pwd'),
        'auth filename resolved under the relative auth.dir';
};

subtest 'build_desk normalizes base_dir "." consistently for the auth file' => sub {
    # Regression test: an explicit auth.file relative to '.' used to
    # land outside the normalized './desk' directory once base_dir
    # '.'/'./ ' was rewritten. Location is now controlled solely by
    # auth.dir (falling back to the *normalized* base_dir), so the
    # auth file always ends up alongside sessions/users storage.
    my $orig_cwd = getcwd();
    my $temp_dir = tempdir(CLEANUP => 1);
    chdir $temp_dir or die "Cannot chdir to $temp_dir: $!";

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => '.',
        auth     => { backend => 'pwd' },
        sessions => { backend => 'database' },
        users    => { backend => 'database', include_standard_fields => [] },
    });

    ok $result->{success}, 'build_desk with base_dir "." succeeds';
    is $result->{desk}, './desk', 'base_dir normalized to ./desk';
    is $result->{config}{auth_args}{file}, File::Spec->catfile('./desk', 'auth.pwd'),
        'auth file path lands inside the normalized ./desk directory';
    ok -f File::Spec->catfile($temp_dir, 'desk', 'auth.pwd'),
        'auth.pwd physically exists under ./desk, not the app root';

    chdir $orig_cwd or die "Cannot chdir back to $orig_cwd: $!";
};

subtest 'build_desk with field configuration' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => $desk_dir,
        auth     => { backend  => 'pwd' },
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

    # Missing base_dir
    my $r2 = Concierge::Desk::Setup::build_desk({});
    ok !$r2->{success}, 'fails when base_dir missing';
    like $r2->{message}, qr/base_dir/i, 'error mentions base_dir';

    # Missing base_dir, other keys present
    my $r3 = Concierge::Desk::Setup::build_desk({ sessions => { backend => 'database' } });
    ok !$r3->{success}, 'fails when base_dir missing even if other keys are present';
};

subtest 'build_desk can be opened' => sub {
    my $desk_dir = tempdir(CLEANUP => 1);

    my $build = Concierge::Desk::Setup::build_desk({
        base_dir => $desk_dir,
        auth     => { backend  => 'pwd' },
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
        base_dir => '/some/path',
        auth     => { backend  => 'pwd', file => '/some/path/auth.pwd' },
        sessions => { backend  => 'database' },
        users    => { backend  => 'database' },
    };

    my $result = Concierge::Desk::Setup::validate_setup_config($config);
    ok $result->{success}, 'valid config passes validation';
    ok !$result->{errors}, 'no errors for valid config';
};

subtest 'validate_setup_config with file backends' => sub {
    my $config = {
        base_dir => '/some/path',
        auth     => { backend  => 'pwd', file => '/some/path/auth.pwd' },
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

    # Missing base_dir only
    my $r2 = Concierge::Desk::Setup::validate_setup_config({
        auth     => { backend => 'pwd', file => '/path/auth.pwd' },
        sessions => { backend => 'database' },
        users    => { backend => 'database' },
    });
    ok !$r2->{success}, 'fails when base_dir missing';
    like $r2->{errors}[0], qr/base_dir/i, 'error mentions base_dir';

    # Missing auth.backend only
    my $r3 = Concierge::Desk::Setup::validate_setup_config({
        base_dir => '/path',
        sessions => { backend  => 'database' },
        users    => { backend  => 'database' },
    });
    ok !$r3->{success}, 'fails when auth.backend missing';
    like $r3->{errors}[0], qr/auth\.backend/i, 'error mentions auth.backend';

    # auth.backend given but unknown
    my $r3b = Concierge::Desk::Setup::validate_setup_config({
        base_dir => '/path',
        auth     => { backend  => 'nosuchbackend' },
        sessions => { backend  => 'database' },
        users    => { backend  => 'database' },
    });
    ok !$r3b->{success}, 'fails when auth.backend is unknown';
    like $r3b->{errors}[0], qr/Invalid auth\.backend/i, 'error mentions invalid auth.backend';

    # auth.backend known; auth.file omitted -- now optional since it
    # resolves to a computed default (default_file), so this is valid
    my $r3c = Concierge::Desk::Setup::validate_setup_config({
        base_dir => '/path',
        auth     => { backend  => 'pwd' },
        sessions => { backend  => 'database' },
        users    => { backend  => 'database' },
    });
    ok $r3c->{success}, 'auth.file is optional for pwd backend (has a default)';

    # Missing sessions.backend only
    my $r4 = Concierge::Desk::Setup::validate_setup_config({
        base_dir => '/path',
        auth     => { backend  => 'pwd', file => '/path/auth.pwd' },
        users    => { backend  => 'database' },
    });
    ok !$r4->{success}, 'fails when sessions.backend missing';

    # Missing users.backend only
    my $r5 = Concierge::Desk::Setup::validate_setup_config({
        base_dir => '/path',
        auth     => { backend  => 'pwd', file => '/path/auth.pwd' },
        sessions => { backend  => 'database' },
    });
    ok !$r5->{success}, 'fails when users.backend missing';
};

subtest 'validate_setup_config rejects invalid backend values' => sub {
    # Invalid sessions backend
    my $r1 = Concierge::Desk::Setup::validate_setup_config({
        base_dir => '/path',
        auth     => { backend  => 'pwd', file => '/path/auth.pwd' },
        sessions => { backend  => 'redis' },
        users    => { backend  => 'database' },
    });
    ok !$r1->{success}, 'fails with invalid sessions backend';
    like $r1->{errors}[0], qr/sessions\.backend/i, 'error mentions sessions.backend';

    # Invalid users backend
    my $r2 = Concierge::Desk::Setup::validate_setup_config({
        base_dir => '/path',
        auth     => { backend  => 'pwd', file => '/path/auth.pwd' },
        sessions => { backend  => 'database' },
        users    => { backend  => 'oracle' },
    });
    ok !$r2->{success}, 'fails with invalid users backend';
    like $r2->{errors}[0], qr/users\.backend/i, 'error mentions users.backend';

    # Both backends invalid - should have 2 errors
    my $r3 = Concierge::Desk::Setup::validate_setup_config({
        base_dir => '/path',
        auth     => { backend  => 'pwd', file => '/path/auth.pwd' },
        sessions => { backend  => 'bad' },
        users    => { backend  => 'also_bad' },
    });
    ok !$r3->{success}, 'fails with both backends invalid';
    ok scalar(@{$r3->{errors}}) >= 2, 'has at least 2 errors';
};

done_testing;

