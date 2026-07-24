package Concierge::Sessions v0.11.3;
use v5.36;

# ABSTRACT: Session manager with flexible session information storage

use Carp qw/croak/;

use Concierge::Sessions::Session;

our $DEFAULT_SESSION_TIMEOUT	= 3600;

# Sessions manager
sub new {
    my ($class, %args) = @_;

    my $backend_class = delete $args{backend_class}
        or croak "Concierge::Sessions->new requires a 'backend_class' class name";

    eval "require $backend_class; 1"
        or croak "Cannot load Sessions backend $backend_class: $@";

    my $backend;
    eval {
        $backend = $backend_class->new(%args);
    };
    if ($@) {
        croak "Failed to initialize backend $backend_class: $@";
    }

    my $self = bless {
        storage => $backend,
    }, $class;

    return $self;
}

# Session object
sub new_session {
    my ($self, %args) = @_;

    unless ($args{user_id}) {
        return { success => 0, message => "user_id required to create a new session" };
    }

    $args{session_timeout}	||= $DEFAULT_SESSION_TIMEOUT;
	$args{storage}			= $self->{storage};

    my $session_result 		= Concierge::Sessions::Session->new( %args );

	return $session_result;
}

sub get_session {
    my ($self, $session_id) = @_;

    unless ($session_id) {
        return { success => 0, message => "Session ID required to retrieve a session" };
    }

    # Load session info from backend
    my $result = $self->{storage}->get_session_info($session_id);

    unless ($result->{success}) {
        return { success => 0, message => "get_session_info: " . $result->{message} };
    }

	my %ses_args		= $result->{info}->%*;
	$ses_args{storage}	= $self->{storage};

    # Instantiate Refreshed Session object
    my $session			= bless { %ses_args }, 'Concierge::Sessions::Session';

    return { success => 1, session => $session };
}

# Administrative methods - handled by backends

# delete sessions that have expired
sub cleanup_sessions {
    my ($self) = @_;
    return $self->{storage}->cleanup_sessions();
}

# delete session by session_id
sub delete_session {
    my ($self, $session_id) = @_;

    unless ($session_id) {
        return { success => 0, message => "Session ID required to delete a session" };
    }

    return $self->{storage}->delete_session($session_id);
}

# delete session by user_id
# sub delete_user_sessions {
sub delete_user_session {
    my ($self, $user_id) = @_;

    unless ($user_id) {
        return { success => 0, message => "user_id required to delete user sessions" };
    }

    return $self->{storage}->delete_user_session($user_id);
}


1;

__END__

=head1 NAME

Concierge::Sessions - Session manager with factory pattern and multiple backend support

=head1 VERSION

v0.11.3

=head1 SYNOPSIS

    use Concierge::Sessions;

    # Create session manager
    my $sessions = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir   => '/var/app/sessions',
    );

    # Create a new user session
    my $result = $sessions->new_session(
        user_id         => 'user123',
        session_timeout => 3600,         # 1 hour (optional, default: 3600)
        data            => {
            username    => 'alice',
            cart        => [],
            preferences => { theme => 'dark' },
        },
    );

    unless ($result->{success}) {
        return $result;
    }

    my $session = $result->{session};
    my $session_id = $session->session_id();

    # Retrieve an existing session
    my $retrieved = $sessions->get_session($session_id);

    if ($retrieved->{success}) {
        my $s = $retrieved->{session};
        # Use the session...
    }

    # Or, using the inverse pattern with an early return - useful when you
    # want to use the session unconfined by a conditional block:
    unless ($retrieved->{success}) {
        return $retrieved;
    }
    my $s = $retrieved->{session};
    # Use the session (unconfined by the conditional block)...

    # Delete a session
    $sessions->delete_session($session_id);

    # Delete all sessions for a user
    $sessions->delete_user_session('user123');

    # Clean up expired sessions
    my $cleanup = $sessions->cleanup_sessions();
    print "Removed $cleanup->{deleted_count} expired sessions\n";

=head1 DESCRIPTION

Concierge::Sessions is a session management system that provides a factory pattern
for creating and managing session objects. It supports multiple storage backends
and implements a service layer pattern with consistent return values.

The manager handles session lifecycle operations including creation, retrieval,
deletion, and cleanup. Individual session data operations are handled by the
Concierge::Sessions::Session objects returned by this manager.

A backend is selected by passing its fully-qualified class name (e.g.
C<Concierge::Sessions::SQLite>) as C<backend_class>. Concierge::Sessions
performs no friendly-name guessing or default selection of its own -- the
named module is C<require>d dynamically inside C<new>, so a manager
configured for C<Concierge::Sessions::File> never loads
C<Concierge::Sessions::SQLite> at all. When used as a component of a
Concierge desk, resolving a friendly name (such as a config file's
C<sessions.backend> setting) to a fully-qualified class name is a
desk-build-time concern handled by L<Concierge::Desk::Setup> (see its
backend catalog, C<%SESSIONS_BACKENDS>), not by this module.

=head1 FEATURES

=over 4

=item * Application-controlled data storage - Store any serializable data structure in sessions

=item * In-memory performance - Fast access to state and configuration

=item * Optional persistence - Session tracks changes, saves when App tells it to

=item * Single-session enforcement - Enforces one active session per user

=item * Sliding window expiration - Sessions auto-extend when users are active

=item * Indefinite sessions - Application-wide sessions that never expire

=item * Multiple backends - Database/SQLite (production), File (testing/small user population)

=item * Modern Perl - v5.36+ with contemporary best practices

=item * Service layer pattern - Non-fatal errors with descriptive messages

=back

=head1 METHODS

All methods return hashrefs with the following structure:

    { success => 1, session => $session_object }  # For successful operations
    { success => 0, message => "Error description" }  # For failures

=head2 new

Creates a new session manager instance.

    my $sessions = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite', # Required: fully-qualified backend class
        storage_dir   => '/path/to/dir',                # Required: directory for session storage
    );

Parameters:

=over 4

=item * C<backend_class> - Required. Fully-qualified class name of the backend
                        to use, e.g. C<Concierge::Sessions::SQLite> or
                        C<Concierge::Sessions::File>.

=item * C<storage_dir> - Directory where session data will be stored. Required.
                      The directory will be created if it doesn't exist.

=back

Returns a blessed Concierge::Sessions object.

Dies if C<backend_class> is missing, if the named backend cannot be loaded, or
if the backend cannot be initialized. This is the one exception to the
C<< { success => 1|0, ... } >> hashref convention used elsewhere in this
module.

=head2 new_session

Creates a new session for the specified user.

    my $result = $sessions->new_session(
        user_id         => 'user123',              # Required
        session_timeout => 3600,                   # Optional: seconds or 'indefinite'
        data            => \%initial_data,         # Optional: hashref of session data
    );

Parameters:

=over 4

=item * C<user_id> - Required. Unique identifier for the user.
                   Creating a new session for a user who already has an active
                   session will cause the old session to be deleted.

=item * C<session_timeout> - Optional. Timeout in seconds, or the string 'indefinite'
                           for a session that never expires. Default: 3600 (1 hour).

=item * C<data> - Optional. Initial session data as a hashref. This can be any
                data structure that can be represented as JSON.

=back

Returns:

    {
        success => 1,
        session => $session_object,  # Concierge::Sessions::Session object
    }

Or on error:

    {
        success => 0,
        message => "Error description",
    }

=head2 get_session

Retrieves an existing session by session ID.

    my $result = $sessions->get_session($session_id);

Parameters:

=over 4

=item * C<session_id> - Required. The session ID returned when the session was created.

=back

Returns:

    {
        success => 1,
        session => $session_object,  # Concierge::Sessions::Session object
    }

Or on error:

    {
        success => 0,
        message => "Session not found or expired",
    }

Note: Expired sessions are filtered by the backend and cannot be retrieved.

=head2 delete_session

Deletes a session by session ID.

    my $result = $sessions->delete_session($session_id);

Parameters:

=over 4

=item * C<session_id> - Required. The session ID to delete.

=back

Returns:

    {
        success => 1,
        message => "Session deleted",
    }

If the session doesn't exist, the operation is still considered successful
(no error is returned).

=head2 delete_user_session

Deletes all sessions for a specific user.

    my $result = $sessions->delete_user_session($user_id);

Parameters:

=over 4

=item * C<user_id> - Required. The user ID whose sessions should be deleted.

=back

Returns:

    {
        success => 1,
        deleted_count => 3,  # Number of sessions deleted
    }

Useful for logging out a user from all devices/sessions.

=head2 cleanup_sessions

Removes all expired sessions from the backend storage.

    my $result = $sessions->cleanup_sessions();

Parameters:

None.

Returns:

    {
        success => 1,
        deleted_count => 15,  # Number of expired sessions removed
    }

Returns a count of 0 if no expired sessions were found.

This method should be called periodically (e.g., by the app deploying
Concierge::Sessions, via cron, etc.) to clean up
expired sessions and reclaim storage space.

=head1 BACKENDS

Concierge::Sessions supports multiple storage backends, selected via
C<backend_class>:

=head2 Concierge::Sessions::SQLite

The recommended backend for production use. Uses SQLite for storage.

    my $sessions = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir   => '/var/app/sessions',
    );

Features:

=over 4

=item * High performance (4,000-5,000 operations per second)

=item * ACID-compliant storage

=item * Automatic filtering of expired sessions during retrieval

=item * Single-session enforcement at database level

=back

Requires: L<DBI> and L<DBD::SQLite>

=head2 Concierge::Sessions::File

Simple file-based backend using JSON format. Useful for testing and development.

    my $sessions = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::File',
        storage_dir   => '/tmp/sessions',
    );

Features:

=over 4

=item * Human-readable JSON files

=item * Simple debugging (view session data directly)

=item * No database dependencies

=item * Lower performance (~1,000 operations per second)

=back

The File backend stores each session as a separate JSON file named after
the session ID.

=head1 RETURN VALUES

All methods return hashrefs with consistent structure:

Successful operations:

    # For new_session and get_session
    {
        success => 1,
        session => $session_object,
    }

    # For delete_session
    {
        success => 1,
        message => "Session deleted",
    }

    # For delete_user_session and cleanup_sessions
    {
        success => 1,
        deleted_count => 5,
    }

Failed operations:

    {
        success => 0,
        message => "Description of what went wrong",
    }

Always check C<$result->{success}> before accessing other fields.

=head1 EXAMPLES

=head2 Basic Session Lifecycle

    use Concierge::Sessions;

    my $sessions = Concierge::Sessions->new(
        backend_class => 'Concierge::Sessions::SQLite',
        storage_dir   => '/var/app/sessions',
    );

    # Create session
    my $result = $sessions->new_session(
        user_id => 'user123',
        data    => { cart => [] },
    );

    my $session = $result->{session};

    # Retrieve session later
    my $retrieved = $sessions->get_session($session->session_id());
    if ($retrieved->{success}) {
        my $data = $retrieved->{session}->get_data()->{value};
        # Use session data...
    }

    # Delete session
    $sessions->delete_session($session->session_id());

=head2 Application-Wide Indefinite Session

    my $app_session = $sessions->new_session(
        user_id         => 'application_state',
        session_timeout => 'indefinite',
        data            => {
            metrics    => { requests_processed => 0 },
            subsystems => { database => 'connected' },
        },
    )->{session};

    # This session never expires
    # Use it for application-wide state tracking

=head2 Logout from All Devices

    # Delete all sessions for a user
    my $result = $sessions->delete_user_session('user123');
    print "Logged out from $result->{deleted_count} devices\n";

=head2 Periodic Cleanup

    # Run this periodically (e.g., from cron)
    my $cleanup = $sessions->cleanup_sessions();
    print "Cleaned up $cleanup->{deleted_count} expired sessions\n";

=head1 SINGLE-SESSION ENFORCEMENT

The system enforces one active session per user. When you create a new session
for a user who already has an active session, the old session is automatically
deleted.

    my $session1 = $sessions->new_session(user_id => 'user123')->{session};
    my $id1 = $session1->session_id();

    # Create another session for same user
    my $session2 = $sessions->new_session(user_id => 'user123')->{session};

    # $session1 has been deleted
    my $check = $sessions->get_session($id1);
    # $check->{success} is false - session no longer exists

This enforcement is implemented at the backend level for consistency
and to ensure database integrity.

=head1 SLIDING WINDOW EXPIRATION

Sessions automatically extend when you call save() on the session object:

    my $session = $sessions->new_session(
        user_id         => 'user123',
        session_timeout => 3600,  # 1 hour
    )->{session};

    # User is active - extend the session
    $session->save();  # Session now expires 1 hour from now

This "sliding window" approach keeps active users logged in while allowing
inactive sessions to expire naturally.

=head1 SEE ALSO

L<Concierge::Sessions::Session> - Session object methods for data access

L<Concierge::Sessions::SQLite> - SQLite backend implementation

L<Concierge::Sessions::File> - File backend implementation

L<Concierge::Desk::Setup> - resolves friendly backend names (e.g.
C<'database'>) to fully-qualified classes at desk-build time

L<DBI> - Database interface

L<JSON::PP> - JSON handling

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

Artistic License 2.0

=cut
