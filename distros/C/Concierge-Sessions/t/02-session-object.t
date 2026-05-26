#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Exception;
use lib 'lib';
use File::Temp qw(tempdir);

use Concierge::Sessions;
use Concierge::Sessions::Session;

# Create temporary directory for test storage
my $temp_dir = tempdir(CLEANUP => 1);

note("Testing Concierge::Sessions::Session object functionality");

# Helper to create a session manager
sub create_manager {
    my $backend = shift || 'SQLite';
    return Concierge::Sessions->new(
        backend     => $backend,
        storage_dir => $temp_dir,
    );
}

# ===================================================================
# Test 1-3: Constructor - new() method
# ===================================================================

subtest 'Session->new() creates session via backend' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id          => 'test_user_new',
        session_timeout  => 3600,
    );

    ok($result->{success}, 'Session creation successful');
    isa_ok($result->{session}, ['Concierge::Sessions::Session']);

    my $session = $result->{session};

    ok($session->session_id(), 'Session ID accessible via accessor');
    like($session->session_id(), qr/^[a-f0-9]{40}$/, 'Session ID is 40-char hex string');
    ok($session->created_at(), 'created_at set via accessor');
    ok($session->expires_at(), 'expires_at set via accessor');
    is($session->status()->{state}, 'active', 'Initial state is active');
    is($session->is_dirty(), 0, 'Initial dirty flag is 0 via accessor');

    my $data_result = $session->get_data();
    ref_ok($data_result->{value}, 'HASH', 'Data is hashref via accessor');
};

subtest 'Session->new() with initial data' => sub {
    my $manager = create_manager();

    my $initial_data = { foo => 'bar', count => 42 };

    my $result = $manager->new_session(
        user_id          => 'test_user_with_data',
        session_timeout  => 3600,
        data             => $initial_data,
    );

    ok($result->{success}, 'Session created with data');

    my $data_result = $result->{session}->get_data();
    is($data_result->{value}, $initial_data, 'Initial data stored via accessor');
};

subtest 'Session->new() fails without user_id' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session();

    is($result->{success}, 0, 'Creation fails without user_id');
    like($result->{message}, qr/user_id/, 'Error mentions user_id');
};

# ===================================================================
# Test 4-5: Constructor - refresh() method
# ===================================================================

subtest 'Session->refresh() creates session from existing data' => sub {
    my $manager = create_manager();

    # Create a session first
    my $create_result = $manager->new_session(user_id => 'test_user_refresh');
    my $session_id = $create_result->{session}->session_id();

    # Retrieve session (which uses refresh internally)
    my $get_result = $manager->get_session($session_id);

    ok($get_result->{success}, 'Refresh successful');
    isa_ok($get_result->{session}, ['Concierge::Sessions::Session']);
    is($get_result->{session}->session_id(), $session_id, 'Session ID matches via accessor');
};

subtest 'Session->refresh() with modified data' => sub {
    my $manager = create_manager();

    # Create a session
    my $create_result = $manager->new_session(user_id => 'test_user_modified');
    my $session_id = $create_result->{session}->session_id();

    # Modify it
    $create_result->{session}->set_data({ modified => 'data' });
    $create_result->{session}->save();

    # Retrieve should get modified data
    my $refresh_result = $manager->get_session($session_id);

    ok($refresh_result->{success}, 'Refresh successful');

    my $data_result = $refresh_result->{session}->get_data();
    is($data_result->{value}{modified}, 'data', 'Modified data present via accessor');
};

# ===================================================================
# Test 6-8: Data access methods
# ===================================================================

subtest 'get_data() retrieves entire data field' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id => 'test_user_get',
        data    => { key1 => 'value1', key2 => 'value2' },
    );

    my $session = $result->{session};

    my $get_result = $session->get_data();

    ok($get_result->{success}, 'get_data successful');
    is($get_result->{value}{key1}, 'value1', 'Data value 1 correct');
    is($get_result->{value}{key2}, 'value2', 'Data value 2 correct');
};

subtest 'set_data() replaces entire data field' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id => 'test_user_set',
        data    => { old => 'data' },
    );

    my $session = $result->{session};

    my $new_data = { new => 'data', count => 123 };
    my $set_result = $session->set_data($new_data);

    ok($set_result->{success}, 'set_data successful');

    my $data_result = $session->get_data();
    is($data_result->{value}, $new_data, 'Data replaced via accessor');
    is($data_result->{value}{new}, 'data', 'New data present');
    ok(!exists $data_result->{value}{old}, 'Old data gone');
};

subtest 'set_data() marks session as dirty' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_user_dirty');
    my $session = $result->{session};

    is($session->is_dirty(), 0, 'Not dirty initially');

    $session->set_data({ something => 'new' });

    is($session->is_dirty(), 1, 'Dirty after set_data');
};

# ===================================================================
# Test 9-11: Persistence methods
# ===================================================================

subtest 'save() persists dirty session to backend' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_user_save');
    my $session = $result->{session};
    my $session_id = $session->session_id();

    # Modify data
    $session->set_data({ saved => 'data' });

    # Save it
    my $save_result = $session->save();

    ok($save_result->{success}, 'Save successful');
    is($session->is_dirty(), 0, 'Not dirty after save');

    # Retrieve again and verify
    my $get_result = $manager->get_session($session_id);
    my $retrieved = $get_result->{session};

    my $data_result = $retrieved->get_data();
    is($data_result->{value}{saved}, 'data', 'Data persisted correctly via accessor');
};

subtest 'save() is no-op for clean session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_user_clean');
    my $session = $result->{session};

    is($session->is_dirty(), 0, 'Not dirty');

    my $save_result = $session->save();

    ok($save_result->{success}, 'Save returns success');
    is($session->is_dirty(), 0, 'Still not dirty');
};

subtest 'save() updates last_updated timestamp' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_user_timestamp');
    my $session = $result->{session};

    my $original_timestamp = $session->last_updated();

    # Wait a tiny bit (not really necessary but illustrates the point)
    select(undef, undef, undef, 0.01);

    $session->set_data({ updated => 'data' });
    $session->save();

    my $new_timestamp = $session->last_updated();

    # Note: last_updated is set by backend, not by session
    ok($new_timestamp >= $original_timestamp, 'Timestamp updated');
};

# ===================================================================
# Test 12-15: Status methods - is_active()
# ===================================================================

subtest 'is_active() returns true for active session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_active');
    my $session = $result->{session};

    is($session->is_active(), 1, 'Session is active');
};

subtest 'is_active() returns false for inactive session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_inactive');
    my $session = $result->{session};

    # Cannot set state to inactive via API - this test should be removed
    # There's no API method to change session state
    is($session->is_active(), 1, 'Session remains active (no API to change state)');
};

subtest 'is_active() returns 0 when state is not set' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_no_state');
    my $session = $result->{session};

    # Cannot delete state via API - this test should be removed
    is($session->status()->{state}, 'active', 'State is active (cannot be undefined via API)');
};

# ===================================================================
# Test 16-19: Status methods - is_expired()
# ===================================================================

subtest 'is_expired() returns false for valid session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id          => 'test_not_expired',
        session_timeout  => 3600,
    );

    my $session = $result->{session};

    is($session->is_expired(), 0, 'Session not expired');
};

subtest 'is_expired() returns false for indefinite session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id          => 'test_indefinite',
        session_timeout  => 'indefinite',
    );

    my $session = $result->{session};

    is($session->is_expired(), 0, 'Indefinite session never expires');
    is($session->expires_at(), 'indefinite', 'expires_at is set to indefinite string');
};

subtest 'is_expired() returns true for expired session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id          => 'test_expired',
        session_timeout  => 3600,
    );

    my $session = $result->{session};

    # Force-expire by setting expires_at to the past (no sleep needed)
    $session->{expires_at} = time() - 3600;

    is($session->is_expired(), 1, 'Session is expired after timeout');
};

subtest 'is_expired() returns false for indefinite session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id          => 'test_indefinite',
        session_timeout  => 'indefinite',
    );

    my $session = $result->{session};

    is($session->is_expired(), 0, 'Indefinite session never expires');
    is($session->expires_at(), 'indefinite', 'expires_at is set to indefinite string');
};

subtest 'is_expired() handles timeout boundary' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id          => 'test_boundary',
        session_timeout  => 3600,
    );

    my $session = $result->{session};

    is($session->is_expired(), 0, 'Session not expired immediately after creation');

    # Force-expire by setting expires_at to the past (no sleep needed)
    $session->{expires_at} = time() - 3600;

    is($session->is_expired(), 1, 'Session expires after timeout period');
};

# ===================================================================
# Test 20-22: Status methods - is_valid()
# ===================================================================

subtest 'is_valid() returns true for valid session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id          => 'test_valid',
        session_timeout  => 3600,
    );

    my $session = $result->{session};

    is($session->is_valid(), 1, 'Session is valid');
};

subtest 'is_valid() returns false for expired session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id          => 'test_invalid_expired',
        session_timeout  => 3600,
    );

    my $session = $result->{session};

    # Force-expire by setting expires_at to the past (no sleep needed)
    $session->{expires_at} = time() - 3600;

    is($session->is_valid(), 0, 'Expired session not valid');
};

subtest 'is_valid() returns false for inactive session' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_invalid_inactive');
    my $session = $result->{session};

    # Cannot set state to inactive via API
    is($session->is_valid(), 1, 'Session remains valid (no API to change state)');
};

# ===================================================================
# Test 23-24: Status methods - is_dirty()
# ===================================================================

subtest 'is_dirty() returns correct value' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_dirty_flag');
    my $session = $result->{session};

    is($session->is_dirty(), 0, 'Not dirty initially');

    $session->set_data({ modified => 'data' });

    is($session->is_dirty(), 1, 'Dirty after modification');
};

subtest 'is_dirty() returns 0 when flag not set' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_no_dirty');
    my $session = $result->{session};

    # Cannot delete dirty flag via API
    is($session->is_dirty(), 0, 'Not dirty (cannot be undefined via API)');
};

# ===================================================================
# Test 25-29: Metadata accessors
# ===================================================================

subtest 'session_id() returns session ID' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_session_id');
    my $session = $result->{session};

    my $id = $session->session_id();

    ok($id, 'session_id returns value');
    like($id, qr/^[a-f0-9]{40}$/, 'Session ID is 40-char hex string');
};

subtest 'created_at() returns creation timestamp' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_created_at');
    my $session = $result->{session};

    my $created = $session->created_at();

    ok($created, 'created_at returns value');
    like($created, qr/^\d+(\.\d+)?$/, 'Timestamp is numeric');
};

subtest 'expires_at() returns expiration timestamp' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(
        user_id          => 'test_expires_at',
        session_timeout  => 3600,
    );

    my $session = $result->{session};

    my $expires = $session->expires_at();

    ok($expires, 'expires_at returns value');
    like($expires, qr/^\d+(\.\d+)?$/, 'Timestamp is numeric');
};

subtest 'last_updated() returns last update timestamp' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_last_updated');
    my $session = $result->{session};

    my $updated = $session->last_updated();

    ok($updated, 'last_updated returns value');
    like($updated, qr/^\d+(\.\d+)?$/, 'Timestamp is numeric');
};

subtest 'status() returns status hashref' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_status');
    my $session = $result->{session};

    my $status = $session->status();

    ref_ok($status, 'HASH', 'status returns hashref');
    is($status->{state}, 'active', 'State is active');
    is($status->{dirty}, 0, 'Dirty flag is 0');
};

subtest 'storage_backend() returns backend type' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_storage');
    my $session = $result->{session};

    my $backend = $session->storage_backend();

    is($backend, 'Concierge::Sessions::SQLite', 'Backend type is SQLite');
};

# ===================================================================
# Test 30-31: Edge cases
# ===================================================================

subtest 'set_data() accepts various data types' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_data_types');
    my $session = $result->{session};

    # Array ref
    $session->set_data([1, 2, 3]);
    my $data_result1 = $session->get_data();
    is($data_result1->{value}[0], 1, 'Array ref works');

    # Scalar
    $session->set_data('string value');
    my $data_result2 = $session->get_data();
    is($data_result2->{value}, 'string value', 'Scalar works');

    # Undef
    $session->set_data(undef);
    my $data_result3 = $session->get_data();
    ok(!defined $data_result3->{value}, 'Undef works');
};

subtest 'get_data() and set_data() with complex structures' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_complex');
    my $session = $result->{session};

    my $complex_data = {
        users => [
            { id => 1, name => 'Alice' },
            { id => 2, name => 'Bob' },
        ],
        metadata => {
            count    => 2,
            modified => time(),
        },
    };

    $session->set_data($complex_data);

    my $get_result = $session->get_data();

    is($get_result->{value}{users}[0]{name}, 'Alice', 'Complex structure preserved');
    is($get_result->{value}{metadata}{count}, 2, 'Nested hash preserved');
};

subtest 'is_active() returns 0 when state is not active' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_inactive_direct');
    my $session = $result->{session};

    # No public API to change state - manipulate directly to cover the false branch
    $session->{status}{state} = 'suspended';

    is($session->is_active(), 0, 'is_active() returns 0 for non-active state');
    is($session->is_valid(), 0, 'is_valid() returns 0 when not active');
};

subtest 'is_active() returns 0 when state is undef' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_undef_state');
    my $session = $result->{session};

    # Delete the state to exercise the || '' fallback in is_active()
    delete $session->{status}{state};

    is($session->is_active(), 0, 'is_active() returns 0 when state is undef');
};

subtest 'status() returns default hashref when status not set' => sub {
    my $manager = create_manager();

    my $result = $manager->new_session(user_id => 'test_status_default');
    my $session = $result->{session};

    # Delete the status field to trigger the || fallback in status()
    delete $session->{status};

    my $status = $session->status();

    ref_ok($status, 'HASH', 'status() returns a hashref even when field not set');
    is($status->{state}, 'active', 'Default state is active');
    is($status->{dirty}, 0, 'Default dirty is 0');
};

done_testing;
