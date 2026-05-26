#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Exception;
use lib 'lib';

# Test that all Concierge::Sessions modules can be loaded and have correct versions

# Load main module
use Concierge::Sessions;
use Concierge::Sessions::Session;
use Concierge::Sessions::Base;
use Concierge::Sessions::SQLite;
use Concierge::Sessions::File;

# Check version numbers
my $sessions_version = $Concierge::Sessions::VERSION;
ok($sessions_version, 'Concierge::Sessions has a version');

# Verify Concierge::Sessions methods
can_ok('Concierge::Sessions', qw(new new_session get_session delete_session delete_user_session cleanup_sessions));

# Verify Concierge::Sessions::Session methods
can_ok('Concierge::Sessions::Session', qw(new get_data set_data save));
can_ok('Concierge::Sessions::Session',
    qw(is_valid is_active is_expired is_dirty));
can_ok('Concierge::Sessions::Session',
    qw(session_id created_at expires_at last_updated status storage_backend));

# Backend interface methods for Base
can_ok('Concierge::Sessions::Base',
    qw(new create_session get_session_info update_session delete_session delete_user_session cleanup_sessions generate_session_id));

# Backend interface methods for SQLite
can_ok('Concierge::Sessions::SQLite',
    qw(new create_session get_session_info update_session delete_session delete_user_session cleanup_sessions));

# Backend interface methods for File
can_ok('Concierge::Sessions::File',
    qw(new create_session get_session_info update_session delete_session delete_user_session cleanup_sessions));

# Verify Base abstract stub methods die when called directly on Base object
my $base = Concierge::Sessions::Base->new();
like(dies { $base->create_session() }, qr/Subclass must implement create_session/, 'create_session stub dies');
like(dies { $base->get_session_info() }, qr/Subclass must implement get_session_info/, 'get_session_info stub dies');
like(dies { $base->update_session() }, qr/Subclass must implement update_session/, 'update_session stub dies');
like(dies { $base->delete_session() }, qr/Subclass must implement delete_session/, 'delete_session stub dies');
like(dies { $base->cleanup_sessions() }, qr/Subclass must implement cleanup_sessions/, 'cleanup_sessions stub dies');
like(dies { $base->delete_user_session() }, qr/Subclass must implement delete_user_session/, 'delete_user_session stub dies');

# Verify generate_session_id works directly
my $id = Concierge::Sessions::Base->generate_session_id();
ok($id, 'generate_session_id returns a value');
like($id, qr/^[a-f0-9]{40}$/, 'generate_session_id returns 40-char hex string');

done_testing;
