#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Exception;
use lib 'lib';
use File::Temp qw(tempdir);
use File::Path qw(remove_tree);

use DBI;
use File::Spec;

use Concierge::Sessions;
use Concierge::Sessions::SQLite;
use Concierge::Sessions::File;

# Create temporary directory for test storage
my $temp_dir = tempdir(CLEANUP => 1);

note("Testing Concierge::Sessions manager functionality");

# ===================================================================
# Test 1-3: Constructor with different backends
# ===================================================================

subtest 'Constructor with database backend' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    ok($manager, 'Manager object created');
    isa_ok($manager, ['Concierge::Sessions']);
};

subtest 'Constructor with file backend' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::File',
        storage_dir => $temp_dir,
    );

    ok($manager, 'Manager object created');
    isa_ok($manager, ['Concierge::Sessions']);
};

subtest 'Constructor without backend_class fails' => sub {
    like(
        dies { Concierge::Sessions->new(storage_dir => $temp_dir) },
        qr/requires a 'backend_class' class name/,
        'Dies without backend_class'
    );
};

subtest 'Constructor with invalid backend_class' => sub {
    like(
        dies { Concierge::Sessions->new(backend_class => 'Concierge::Sessions::InvalidBackend', storage_dir => $temp_dir) },
        qr/Cannot load Sessions backend/,
        'Dies with invalid backend_class'
    );
};

# ===================================================================
# Test 4-8: new_session() method
# ===================================================================

subtest 'new_session() with valid user_id' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $result = $manager->new_session(user_id => 'test_user_001');

    ok($result, 'new_session returns a result');
    ref_ok($result, 'HASH', 'Result is a hashref');

    ok($result->{success}, 'Session creation successful');
    isa_ok($result->{session}, ['Concierge::Sessions::Session']);

    my $session = $result->{session};

    ok($session->created_at(), 'created_at timestamp set via accessor');
    ok($session->expires_at(), 'expires_at timestamp set via accessor');
    is($session->status()->{state}, 'active', 'Initial state is active');
    is($session->is_dirty(), 0, 'Initial dirty flag is 0 via accessor');

    my $data_result = $session->get_data();
    ref_ok($data_result->{value}, 'HASH', 'Data is a hashref via accessor');
};

subtest 'new_session() without user_id fails' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $result = $manager->new_session();

    ok($result, 'Returns error result');
    is($result->{success}, 0, 'Creation failed without user_id');
    like($result->{message}, qr/user_id required/, 'Error message mentions user_id requirement');
};

subtest 'new_session() with custom timeout' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $result = $manager->new_session(
        user_id          => 'test_user_timeout',
        session_timeout  => 7200,  # 2 hours
    );

    ok($result->{success}, 'Session created with custom timeout');
    my $session = $result->{session};

    my $created = $session->created_at();
    my $expires = $session->expires_at();
    my $expected_expires = $created + 7200;

    is($expires, $expected_expires, 'Custom timeout applied correctly');
};

subtest 'new_session() with default timeout' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $result = $manager->new_session(user_id => 'test_user_default');

    ok($result->{success}, 'Session created with default timeout');
    my $session = $result->{session};

    my $created = $session->created_at();
    my $expires = $session->expires_at();
    my $expected_expires = $created + 3600;  # DEFAULT_SESSION_TIMEOUT

    is($expires, $expected_expires, 'Default timeout applied correctly');
};

subtest 'new_session() with initial data' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $initial_data = { foo => 'bar', count => 42 };

    my $result = $manager->new_session(
        user_id => 'test_user_with_data',
        data    => $initial_data,
    );

    ok($result->{success}, 'Session created with initial data');
    my $session = $result->{session};

    my $data_result = $session->get_data();
    is($data_result->{value}, $initial_data, 'Initial data stored correctly via accessor');
};

# ===================================================================
# Test 9-12: get_session() method
# ===================================================================

subtest 'get_session() with valid session_id' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    # Create a session first
    my $create_result = $manager->new_session(user_id => 'test_user_get');

    # Get the session_id via accessor
    my $session_id = $create_result->{session}->session_id();

    # Retrieve it
    my $get_result = $manager->get_session($session_id);

    ok($get_result->{success}, 'Session retrieved successfully');
    isa_ok($get_result->{session}, ['Concierge::Sessions::Session']);
};

subtest 'get_session() without session_id fails' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $result = $manager->get_session();

    is($result->{success}, 0, 'Get fails without session_id');
    like($result->{message}, qr/Session ID required/, 'Error message mentions session_id requirement');
};

subtest 'get_session() with non-existent session_id' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $result = $manager->get_session('non-existent-session-id');

    is($result->{success}, 0, 'Get fails for non-existent session');
    like($result->{message}, qr/get_session_info/, 'Error from backend propagated');
};

subtest 'get_session() with expired session' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    # Create a session with 1 second timeout
    my $create_result = $manager->new_session(
        user_id          => 'test_user_expired',
        session_timeout  => 600,
    );

    my $session_id = $create_result->{session}->session_id();

    # Wait for session to expire
    # sleep(2);
    # Force-expire via direct DB update (no sleep needed)
    my $db_file = File::Spec->catfile($temp_dir, 'sessions.db');
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", { RaiseError => 1 });
    $dbh->do("UPDATE sessions SET expires_at = ? WHERE session_id = ?",
        undef, time() - 3600, $session_id);
    $dbh->disconnect;

    # Try to retrieve it - backend filters expired sessions
    my $get_result = $manager->get_session($session_id);

    # Backend automatically filters expired sessions
    is($get_result->{success}, 0, 'Expired session cannot be retrieved (filtered by backend)');
    like($get_result->{message}, qr/(not found|expired)/i, 'Error indicates session not found or expired');
};

subtest 'delete_session() with valid session_id' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    # Create a session first
    my $create_result = $manager->new_session(user_id => 'test_user_delete');
    my $session_id = $create_result->{session}->session_id();

    # Delete it
    my $delete_result = $manager->delete_session($session_id);

    ok($delete_result->{success}, 'Session deleted successfully');

    # Verify it's gone
    my $get_result = $manager->get_session($session_id);
    is($get_result->{success}, 0, 'Session no longer retrievable after deletion');
};

subtest 'delete_session() without session_id fails' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $result = $manager->delete_session();

    is($result->{success}, 0, 'Delete fails without session_id');
    like($result->{message}, qr/Session ID required/, 'Error message mentions session_id requirement');
};

subtest 'delete_session() with non-existent session_id' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $result = $manager->delete_session('non-existent-session-id');

    # Different backends handle this differently
    # SQLite returns success even if session doesn't exist
    ok(exists $result->{success}, 'Returns a result');
};

# ===================================================================
# Test 16-17: cleanup_sessions() method
# ===================================================================

subtest 'cleanup_sessions() with expired sessions' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    # Create active session
    $manager->new_session(
        user_id          => 'active_user',
        session_timeout  => 3600,
    );

    # Create expired session
    $manager->new_session(
        user_id          => 'expired_user',
        session_timeout  => 0,
    );

    my $cleanup_result = $manager->cleanup_sessions();

    ok($cleanup_result->{success}, 'Cleanup completed');
    ok(exists $cleanup_result->{deleted_count}, 'Returns deleted_count');
};

subtest 'cleanup_sessions() with no expired sessions' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    # Create only active sessions
    $manager->new_session(user_id => 'user1', session_timeout => 3600);
    $manager->new_session(user_id => 'user2', session_timeout => 3600);

    my $cleanup_result = $manager->cleanup_sessions();

    ok($cleanup_result->{success}, 'Cleanup completed');
    is($cleanup_result->{deleted_count} || 0, 0, 'No sessions deleted');
};

# ===================================================================
# Test 18-19: File backend tests
# ===================================================================

subtest 'Manager with File backend - basic operations' => sub {
    my $file_dir = "$temp_dir/file_sessions";

    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::File',
        storage_dir => $file_dir,
    );

    # Create session
    my $create_result = $manager->new_session(user_id => 'file_test_user');
    ok($create_result->{success}, 'Session created with File backend');

    my $session_id = $create_result->{session}->session_id();

    # Retrieve session
    my $get_result = $manager->get_session($session_id);
    ok($get_result->{success}, 'Session retrieved with File backend');

    # Delete session
    my $delete_result = $manager->delete_session($session_id);
    ok($delete_result->{success}, 'Session deleted with File backend');
};

subtest 'File backend cleanup' => sub {
    my $file_dir = "$temp_dir/file_cleanup";

    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::File',
        storage_dir => $file_dir,
    );

    # Create active and expired sessions
    $manager->new_session(user_id => 'active', session_timeout => 3600);
    $manager->new_session(user_id => 'expired', session_timeout => 0);

    my $cleanup_result = $manager->cleanup_sessions();

    ok($cleanup_result->{success}, 'File cleanup completed');
    ok(exists $cleanup_result->{deleted_count}, 'Returns deleted_count');
};

# ===================================================================
# delete_user_session() manager-level tests
# ===================================================================

subtest 'delete_user_session() without user_id fails' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $result = $manager->delete_user_session();

    is($result->{success}, 0, 'delete_user_session fails without user_id');
    like($result->{message}, qr/user_id required/, 'Error message mentions user_id');
};

subtest 'delete_user_session() with valid user_id' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    $manager->new_session(user_id => 'user_del_by_uid');
    my $result = $manager->delete_user_session('user_del_by_uid');

    ok($result->{success}, 'delete_user_session succeeds');
    ok(exists $result->{deleted_count}, 'Returns deleted_count');
    is($result->{deleted_count}, 1, 'One session deleted');
};

subtest 'delete_user_session() for user with no sessions returns deleted_count 0' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    # User has no sessions - exercises 0E0 → 0 conversion in SQLite backend
    my $result = $manager->delete_user_session('user_with_no_sessions_xyz');

    ok($result->{success}, 'delete_user_session succeeds even for user with no sessions');
    is($result->{deleted_count}, 0, 'deleted_count is 0 for user with no sessions');
};

# ===================================================================
# SQLite backend direct error-path tests
# ===================================================================

subtest 'SQLite create_session without user_id' => sub {
    my $backend = Concierge::Sessions::SQLite->new(storage_dir => $temp_dir);

    my $result = $backend->create_session(session_timeout => 3600);

    is($result->{success}, 0, 'create_session fails without user_id');
    like($result->{message}, qr/Cannot create session without user_id/, 'Error message explains requirement');
};

subtest 'SQLite get_session_info without session_id' => sub {
    my $backend = Concierge::Sessions::SQLite->new(storage_dir => $temp_dir);

    my $result = $backend->get_session_info(undef);

    is($result->{success}, 0, 'get_session_info fails without session_id');
    like($result->{message}, qr/Session ID required/, 'Error message mentions session_id');
};

subtest 'SQLite update_session without session_id' => sub {
    my $backend = Concierge::Sessions::SQLite->new(storage_dir => $temp_dir);

    my $result = $backend->update_session(undef, { data => {} });

    is($result->{success}, 0, 'update_session fails without session_id');
    like($result->{message}, qr/Session ID required/, 'Error message mentions session_id');
};

subtest 'SQLite update_session without updates returns success' => sub {
    my $backend = Concierge::Sessions::SQLite->new(storage_dir => $temp_dir);
    my $create_result = $backend->create_session(
        user_id         => 'sqlite_update_noop_user',
        session_timeout => 3600,
    );

    my $result = $backend->update_session($create_result->{session_id}, undef);

    ok($result->{success}, 'update_session with no updates returns success');
};

subtest 'SQLite delete_user_session without user_id' => sub {
    my $backend = Concierge::Sessions::SQLite->new(storage_dir => $temp_dir);

    my $result = $backend->delete_user_session(undef);

    is($result->{success}, 0, 'delete_user_session fails without user_id');
    like($result->{message}, qr/user_id required/, 'Error message mentions user_id');
};

# ===================================================================
# File backend direct error-path tests
# ===================================================================

subtest 'File backend create_session without user_id' => sub {
    my $file_dir = "$temp_dir/file_create_err";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);

    my $result = $backend->create_session(session_timeout => 3600);

    is($result->{success}, 0, 'File create_session fails without user_id');
    like($result->{message}, qr/Cannot create session without user_id/, 'Error message explains requirement');
};

subtest 'File backend delete_session for non-existent file returns success' => sub {
    my $file_dir = "$temp_dir/file_del_nonexist";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);

    my $result = $backend->delete_session('session-id-that-does-not-exist');

    ok($result->{success}, 'File delete_session returns success for non-existent session');
};

subtest 'File backend get_session_info without session_id' => sub {
    my $file_dir = "$temp_dir/file_info_err";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);

    my $result = $backend->get_session_info(undef);

    is($result->{success}, 0, 'File get_session_info fails without session_id');
    like($result->{message}, qr/Session ID required/, 'Error message mentions session_id');
};

subtest 'File backend update_session without session_id' => sub {
    my $file_dir = "$temp_dir/file_upd_err";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);

    my $result = $backend->update_session(undef, { data => {} });

    is($result->{success}, 0, 'File update_session fails without session_id');
    like($result->{message}, qr/Session ID required/, 'Error message mentions session_id');
};

subtest 'File backend update_session without updates returns success' => sub {
    my $file_dir = "$temp_dir/file_upd_noop";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);
    my $create_result = $backend->create_session(
        user_id         => 'file_update_noop_user',
        session_timeout => 3600,
    );

    my $result = $backend->update_session($create_result->{session_id}, undef);

    ok($result->{success}, 'File update_session with no updates returns success');
};

subtest 'File backend delete_user_session without user_id' => sub {
    my $file_dir = "$temp_dir/file_del_uid_err";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);

    my $result = $backend->delete_user_session(undef);

    is($result->{success}, 0, 'File delete_user_session fails without user_id');
    like($result->{message}, qr/user_id required/, 'Error message mentions user_id');
};

# ===================================================================
# File backend: edge cases in get_session_info and update_session
# ===================================================================

subtest 'File get_session_info with invalid JSON content' => sub {
    my $file_dir = "$temp_dir/file_bad_json";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);

    # Create a file with invalid JSON content using a known session ID
    my $fake_id = 'aabbccdd' x 5;  # 40-char hex-like string
    my $session_file = File::Spec->catfile($file_dir, $fake_id);
    open my $fh, '>', $session_file or die "Cannot create test file: $!";
    print $fh "{ this is not valid json }";
    close $fh;

    my $result = $backend->get_session_info($fake_id);

    is($result->{success}, 0, 'get_session_info fails for invalid JSON');
    like($result->{message}, qr/Invalid JSON/, 'Error message mentions Invalid JSON');
};

subtest 'File get_session_info with missing required fields (none present)' => sub {
    my $file_dir = "$temp_dir/file_missing_fields";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);

    # Valid JSON but missing session_id, created_at, expires_at
    my $fake_id = 'bbccddee' x 5;  # 40-char hex-like string
    my $session_file = File::Spec->catfile($file_dir, $fake_id);
    open my $fh, '>', $session_file or die "Cannot create test file: $!";
    print $fh '{"user_id":"test","data":{}}';
    close $fh;

    my $result = $backend->get_session_info($fake_id);

    is($result->{success}, 0, 'get_session_info fails for file missing all system fields');
    like($result->{message}, qr/missing system status fields/, 'Error message mentions missing fields');
};

subtest 'File get_session_info with missing expires_at field' => sub {
    my $file_dir = "$temp_dir/file_missing_expiry";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);

    # JSON with session_id and created_at but no expires_at
    my $fake_id = 'ddeeff00' x 5;
    my $session_file = File::Spec->catfile($file_dir, $fake_id);
    open my $fh, '>', $session_file or die "Cannot create test file: $!";
    print $fh '{"session_id":"test","created_at":1234567890,"data":{}}';
    close $fh;

    my $result = $backend->get_session_info($fake_id);

    is($result->{success}, 0, 'get_session_info fails with missing expires_at');
    like($result->{message}, qr/missing system status fields/, 'Error message mentions missing fields');
};

subtest 'File update_session with invalid JSON content in file' => sub {
    my $file_dir = "$temp_dir/file_upd_bad_json";
    my $backend = Concierge::Sessions::File->new(storage_dir => $file_dir);

    # Create a file with invalid JSON
    my $fake_id = 'ccddee11' x 5;
    my $session_file = File::Spec->catfile($file_dir, $fake_id);
    open my $fh, '>', $session_file or die "Cannot create test file: $!";
    print $fh "{ this is not valid json }";
    close $fh;

    my $result = $backend->update_session($fake_id, { data => { key => 'val' } });

    is($result->{success}, 0, 'update_session fails for file with invalid JSON');
    like($result->{message}, qr/Invalid JSON/, 'Error message mentions Invalid JSON');
};

done_testing;
