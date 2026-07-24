#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use lib 'lib';
use File::Temp qw(tempdir);
use File::Spec;
use DBI;

use Concierge::Sessions;

# Create temporary directory for test storage
my $temp_dir = tempdir(CLEANUP => 1);

note("Testing end-to-end session workflows");

# ===================================================================
# Test 1-3: Complete user session lifecycle
# ===================================================================

subtest 'Complete session lifecycle: create, modify, save, retrieve, delete' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    # User logs in - create session
    my $create_result = $manager->new_session(
        user_id         => 'user_lifecycle',
        session_timeout => 3600,
        data            => { login_count => 1, last_page => '/home' },
    );

    ok($create_result->{success}, 'Session created');
    my $session = $create_result->{session};
    my $session_id = $session->session_id();

    # User browses - modify session data
    $session->set_data({ login_count => 1, last_page => '/dashboard', preferences => { theme => 'dark' } });
    is($session->is_dirty(), 1, 'Session marked dirty');

    # Save session
    my $save_result = $session->save();
    ok($save_result->{success}, 'Session saved');
    is($session->is_dirty(), 0, 'Session clean after save');

    # User navigates away and comes back - retrieve session
    my $get_result = $manager->get_session($session_id);
    ok($get_result->{success}, 'Session retrieved');
    my $retrieved = $get_result->{session};

    my $data_result = $retrieved->get_data();
    is($data_result->{value}{last_page}, '/dashboard', 'Data persisted via accessor');
    is($data_result->{value}{preferences}{theme}, 'dark', 'Nested data preserved via accessor');

    # User logs out - delete session
    my $delete_result = $manager->delete_session($session_id);
    ok($delete_result->{success}, 'Session deleted');

    # Verify deletion
    my $verify_result = $manager->get_session($session_id);
    is($verify_result->{success}, 0, 'Session no longer exists');
};

# ===================================================================
# Test 4-5: Single session per user enforcement
# ===================================================================

subtest 'New session replaces existing session for same user' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $user_id = 'single_session_user';

    # Create first session
    my $session1 = $manager->new_session(
        user_id         => $user_id,
        session_timeout => 3600,
        data            => { device => 'desktop', ip => '192.168.1.100' },
    );

    ok($session1->{success}, 'First session created');
    my $session1_id = $session1->{session}->session_id();

    # Create second session for same user
    my $session2 = $manager->new_session(
        user_id         => $user_id,
        session_timeout => 3600,
        data            => { device => 'mobile', ip => '192.168.1.200' },
    );

    ok($session2->{success}, 'Second session created');

    # First session should be deleted
    my $check1 = $manager->get_session($session1_id);
    is($check1->{success}, 0, 'First session was deleted');

    # Second session should exist
    my $check2 = $manager->get_session($session2->{session}->session_id());
    is($check2->{success}, 1, 'Second session exists');

    my $data_result = $check2->{session}->get_data();
    is($data_result->{value}{device}, 'mobile', 'New session data correct via accessor');
};

subtest 'Each login gets fresh session, previous invalidated' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $user_id = 'login_test_user';

    # First login
    my $login1 = $manager->new_session(user_id => $user_id);
    ok($login1->{success}, 'First login successful');
    my $login1_id = $login1->{session}->session_id();

    # Simulate user activity
    $login1->{session}->set_data({ page_views => 5 });

    # Second login (different device/browser)
    my $login2 = $manager->new_session(user_id => $user_id);
    ok($login2->{success}, 'Second login successful');

    # First session is invalidated
    my $check1 = $manager->get_session($login1_id);
    is($check1->{success}, 0, 'Old session invalidated');

    # Only new session exists
    my $data_result = $login2->{session}->get_data();
    is($data_result->{value}, {}, 'New session starts fresh');
};

# ===================================================================
# Test 6-8: Session data persistence and recovery
# ===================================================================

subtest 'Data persists across save/retrieve cycle' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $session = $manager->new_session(user_id => 'persistence_test');

    # Set complex data
    my $complex_data = {
        user_profile => {
            name     => 'Alice',
            email    => 'alice@example.com',
            settings => { notifications => 1, language => 'en' },
        },
        activity_log => [
            { action => 'login', time => time() },
            { action => 'view_page', time => time() },
        ],
    };

    $session->{session}->set_data($complex_data);
    $session->{session}->save();

    # Retrieve and verify
    my $retrieved = $manager->get_session($session->{session}->session_id());

    my $data_result = $retrieved->{session}->get_data();
    is($data_result->{value}{user_profile}{name}, 'Alice', 'Nested hash preserved via accessor');
    is($data_result->{value}{activity_log}[0]{action}, 'login', 'Nested array preserved via accessor');
};

subtest 'Session survives multiple save cycles' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $session = $manager->new_session(user_id => 'multi_save_test');
    my $session_id = $session->{session}->session_id();

    # First save
    $session->{session}->set_data({ step => 1 });
    $session->{session}->save();

    # Retrieve, modify, save again
    my $retrieved = $manager->get_session($session_id);
    $retrieved->{session}->set_data({ step => 2 });
    $retrieved->{session}->save();

    # Retrieve again and verify
    my $final = $manager->get_session($session_id);

    my $data_result = $final->{session}->get_data();
    is($data_result->{value}{step}, 2, 'Data from multiple saves persists via accessor');
};

subtest 'Unsaved changes are lost on retrieval' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $session = $manager->new_session(user_id => 'unsaved_test');
    my $session_id = $session->{session}->session_id();

    # Modify but don't save
    $session->{session}->set_data({ modified => 'data' });
    is($session->{session}->is_dirty(), 1, 'Session is dirty');

    # Retrieve fresh from backend
    my $retrieved = $manager->get_session($session_id);

    # Changes should not be present
    my $data_result = $retrieved->{session}->get_data();
    ok(!exists $data_result->{value}{modified}, 'Unsaved changes not in retrieved session');
};

# ===================================================================
# Test 9-10: File backend integration
# ===================================================================

subtest 'Complete workflow with File backend' => sub {
    my $file_dir = "$temp_dir/file_backend_test";

    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::File',
        storage_dir => $file_dir,
    );

    my $session = $manager->new_session(
        user_id => 'file_backend_user',
        data    => { backend => 'file' },
    );

    ok($session->{success}, 'Session created with File backend');

    my $session_id = $session->{session}->session_id();

    # Modify and save
    $session->{session}->set_data({ backend => 'file', updated => 1 });
    $session->{session}->save();

    # Retrieve
    my $retrieved = $manager->get_session($session_id);

    my $data_result = $retrieved->{session}->get_data();
    is($data_result->{value}{updated}, 1, 'File backend persistence works via accessor');
};

subtest 'Switching between backends for same user' => sub {
    my $sqlite_dir = $temp_dir;
    my $file_dir = "$temp_dir/switch_test";

    # Create session with SQLite
    my $sqlite_mgr = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $sqlite_dir,
    );

    my $sqlite_session = $sqlite_mgr->new_session(user_id => 'switch_user');
    my $sqlite_id = $sqlite_session->{session}->session_id();

    $sqlite_session->{session}->set_data({ backend => 'sqlite' });
    $sqlite_session->{session}->save();

    # Create different session with File backend
    my $file_mgr = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::File',
        storage_dir => $file_dir,
    );

    my $file_session = $file_mgr->new_session(user_id => 'switch_user');
    my $file_id = $file_session->{session}->session_id();

    $file_session->{session}->set_data({ backend => 'file' });
    $file_session->{session}->save();

    # Verify both exist independently
    my $sqlite_retrieved = $sqlite_mgr->get_session($sqlite_id);
    my $file_retrieved = $file_mgr->get_session($file_id);

    my $sqlite_data = $sqlite_retrieved->{session}->get_data();
    my $file_data = $file_retrieved->{session}->get_data();

    is($sqlite_data->{value}{backend}, 'sqlite', 'SQLite session intact via accessor');
    is($file_data->{value}{backend}, 'file', 'File session intact via accessor');
};

# ===================================================================
# Test 11-12: Session status management
# ===================================================================

subtest 'Session status updates correctly through lifecycle' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $session = $manager->new_session(user_id => 'status_test');

    is($session->{session}->is_active(), 1, 'New session is active');
    is($session->{session}->is_dirty(), 0, 'New session is clean');
    is($session->{session}->is_valid(), 1, 'New session is valid');

    # Modify data
    $session->{session}->set_data({ test => 'data' });
    is($session->{session}->is_dirty(), 1, 'Dirty after modification');

    # Save
    $session->{session}->save();
    is($session->{session}->is_dirty(), 0, 'Clean after save');
    is($session->{session}->is_active(), 1, 'Still active');
};

subtest 'Application-wide session with indefinite timeout' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    # Create an application-wide session that never expires
    my $app_session = $manager->new_session(
        user_id         => 'application_main',
        session_timeout => 'indefinite',
        data            => {
            app_name     => 'MyApp',
            started_at   => time(),
            status       => 'running',
            user_count   => 0,
            subsystems   => {
                database => 'connected',
                cache    => 'ready',
                email    => 'idle',
            },
        },
    );

    ok($app_session->{success}, 'App session created with indefinite timeout');

    my $session = $app_session->{session};
    my $session_id = $session->session_id();

    # Verify it never expires
    is($session->is_expired(), 0, 'App session never expires');
    is($session->expires_at(), 'indefinite', 'expires_at is indefinite');

    # Update app state
    my $data_result = $session->get_data();
    my $app_data = $data_result->{value};

    $app_data->{user_count} = 5;
    $app_data->{subsystems}{email} = 'sending';
    $session->set_data($app_data);
    $session->save();

    # Retrieve and verify persistence
    my $retrieved = $manager->get_session($session_id);
    ok($retrieved->{success}, 'App session retrieved');

    my $retrieved_data = $retrieved->{session}->get_data();
    is($retrieved_data->{value}{user_count}, 5, 'App state persisted');
    is($retrieved_data->{value}{subsystems}{email}, 'sending', 'Nested app state persisted');
    is($retrieved->{session}->is_expired(), 0, 'Retrieved session still never expires');
};

subtest 'Session expiration detection' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $session = $manager->new_session(
        user_id         => 'expire_test',
        session_timeout => 3600,
    );

    my $session_id = $session->{session}->session_id();

    # Verify session is initially valid
    is($session->{session}->is_valid(), 1, 'Session is valid initially');

    # Force-expire via direct DB update (no sleep needed)
    my $db_file = File::Spec->catfile($temp_dir, 'sessions.db');
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", { RaiseError => 1 });
    $dbh->do("UPDATE sessions SET expires_at = ? WHERE session_id = ?",
        undef, time() - 3600, $session_id);
    $dbh->disconnect;

    # Backend filters expired sessions - retrieval fails
    my $retrieved = $manager->get_session($session_id);

    is($retrieved->{success}, 0, 'Backend filters expired sessions');
    like($retrieved->{message}, qr/(not found|expired)/i, 'Error indicates expiration');
};

subtest 'Session extends when saved (sliding window)' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $timeout = 3600;
    my $session = $manager->new_session(
        user_id         => 'extension_test',
        session_timeout => $timeout,
        data            => { counter => 0 },
    );

    my $session_id = $session->{session}->session_id();

    # Record the original expiration time
    my $original_expires = $session->{session}->expires_at();

    # Force the DB expiration to be close to now (simulates time passing)
    # Set expires_at to 5 seconds from now -- session would expire soon
    my $db_file = File::Spec->catfile($temp_dir, 'sessions.db');
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", { RaiseError => 1 });
    $dbh->do("UPDATE sessions SET expires_at = ? WHERE session_id = ?",
        undef, time() + 5, $session_id);
    $dbh->disconnect;

    # Save session (should extend expiration via sliding window)
    $session->{session}->set_data({ counter => 1 });
    $session->{session}->save();

    # Verify the expiration was extended: new expires_at should be ~now + timeout
    my $retrieved = $manager->get_session($session_id);
    is($retrieved->{success}, 1, 'Session retrievable after save()');

    my $new_expires = $retrieved->{session}->expires_at();
    ok($new_expires > time() + $timeout - 10, 'save() extended expiration via sliding window');

    my $data_result = $retrieved->{session}->get_data();
    is($data_result->{value}{counter}, 1, 'Extended session has correct data');
};

subtest 'Graceful handling of invalid operations' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    # Try to get non-existent session
    my $result = $manager->get_session('non-existent-id');
    is($result->{success}, 0, 'Gracefully handles non-existent session');

    # Try to delete non-existent session
    my $delete_result = $manager->delete_session('another-non-existent');
    ok(exists $delete_result->{success}, 'Returns result for delete of non-existent');

    # Try to create session without user_id
    my $create_result = $manager->new_session();
    is($create_result->{success}, 0, 'Gracefully handles missing user_id');
    like($create_result->{message}, qr/user_id required/, 'Helpful error message');
};

# ===================================================================
# Test 14: Data type handling
# ===================================================================

subtest 'Session handles various data types correctly' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $session = $manager->new_session(user_id => 'datatype_test');

    # Store different types
    $session->{session}->set_data({
        string   => 'hello',
        number   => 42,
        float    => 3.14,
        arrayref => [1, 2, 3],
        hashref  => { nested => 'value' },
        mixed    => {
            items => [
                { id => 1, name => 'item1' },
                { id => 2, name => 'item2' },
            ],
            count => 2,
        },
    });

    $session->{session}->save();

    # Retrieve and verify types
    my $retrieved = $manager->get_session($session->{session}->session_id());

    my $data_result = $retrieved->{session}->get_data();

    is($data_result->{value}{string}, 'hello', 'String preserved via accessor');
    is($data_result->{value}{number}, 42, 'Number preserved via accessor');
    is($data_result->{value}{float}, 3.14, 'Float preserved via accessor');
    is($data_result->{value}{arrayref}[0], 1, 'Array preserved via accessor');
    is($data_result->{value}{hashref}{nested}, 'value', 'Hash preserved via accessor');
    is($data_result->{value}{mixed}{items}[0]{name}, 'item1', 'Complex structure preserved via accessor');
};

# ===================================================================
# Test 15: Performance optimization - no-op saves
# ===================================================================

subtest 'Multiple saves of clean session are no-ops' => sub {
    my $manager = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir => $temp_dir,
    );

    my $session = $manager->new_session(user_id => 'noop_test');

    # Save without modifications
    my $result1 = $session->{session}->save();
    my $result2 = $session->{session}->save();
    my $result3 = $session->{session}->save();

    ok($result1->{success}, 'First save succeeds');
    ok($result2->{success}, 'Second save (no-op) succeeds');
    ok($result3->{success}, 'Third save (no-op) succeeds');
};

done_testing;
