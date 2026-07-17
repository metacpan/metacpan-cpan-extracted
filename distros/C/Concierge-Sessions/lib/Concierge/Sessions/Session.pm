package Concierge::Sessions::Session v0.11.2;
use v5.36;

# ABSTRACT: Individual session objects created by Concierge::Sessions

use Time::HiRes qw(time);
use Carp qw(croak);

sub new {
    my ($class, %args) = @_;

    my $backend	= $args{storage};

	my $create_result = $backend->create_session( %args );
    unless ($create_result->{success}) {
        return { success => 0, message => "new_session failure: " . $create_result->{message} };
    }

    # Retrieve the full created session info with timestamps, etc.
    my $get_result = $backend->get_session_info( $create_result->{session_id} );
    unless ($get_result->{success}) {
        return { success => 0, message => "new_session info failure: " . $get_result->{message} };
    }

    # Create Session object
    my $self = bless {
        $get_result->{info}->%*,
        storage => $backend,
    }, __PACKAGE__;

    return { success => 1, session => $self };
}

# Data access methods - work with entire data field
sub get_data {
    my ($self) = @_;

    # Return entire data field
    my $value = $self->{data};

    return { success => 1, value => $value };
}

sub set_data {
    my ($self, $value) = @_;

    # $value replaces entire data field
    $self->{data} 			= $value;

    # Only changed in memory, not in storage
    $self->{status}{dirty}	= 1;

    return { success => 1 };
}

# Persistence method for app data, timestamped
sub save {
    my ($self) = @_;

    # Check if dirty
    my $dirty = $self->{status}{dirty} || 0;

    unless ($dirty) {
        return { success => 1 };  # Fine if not dirty
    }

    # Calculate new expiration time (sliding window extension)
    my $timeout = $self->{session_timeout};
    my $new_expires_at;
    if (defined $timeout && $timeout eq 'indefinite') {
        $new_expires_at = 'indefinite';
    } else {
        $new_expires_at = time() + $timeout;
    }

    # Update internal expires_at
    $self->{expires_at} = $new_expires_at;

    # Save session data changes and new expiration time
    my $result = $self->{storage}->update_session(
        $self->{session_id},
        {
            data => $self->{data},
            expires_at => $new_expires_at,
        }
    );

    unless ($result->{success}) {
        return { success => 0, message => "save: " . $result->{message} };
    }

    # Clear dirty flag
    $self->{status}{dirty} = 0;

    return { success => 1 };
}

# Read-only Status booleans
sub is_valid {
      my ($self) = @_;
      return ($self->is_active() && !$self->is_expired()) ? 1 : 0;
  }


sub is_active {
    my ($self) = @_;
    my $state	= $self->{status}{state} || '';
    return $state eq 'active' ? 1 : 0;
}

sub is_expired {
    my ($self) = @_;
	# Indefinite sessions never expire
    return 0 if $self->{expires_at} eq 'indefinite';
    return (time() > $self->{expires_at}) ? 1 : 0;
}

sub is_dirty {
    my ($self) = @_;
    return $self->{status}{dirty} || 0;
}

# Read-only system info
sub session_id {
    my ($self) = @_;
    return $self->{session_id};
}

sub storage_backend {
    my ($self) = @_;
    return ref($self->{storage});
}

sub created_at {
    my ($self) = @_;
    $self->{created_at};
}

sub expires_at {
    my ($self) = @_;
    $self->{expires_at};
}

sub last_updated {
    my ($self) = @_;
    return $self->{last_updated};
}

sub status {
    my ($self) = @_;
    return $self->{status} || { state => 'active', dirty => 0 };
}

1;

__END__

=head1 NAME

Concierge::Sessions::Session - Individual session objects for data access and persistence

=head1 VERSION

v0.11.2

=head1 SYNOPSIS

Session objects are created by Concierge::Sessions factory methods:

    use Concierge::Sessions;

    my $sessions = Concierge::Sessions->new(
        backend     => 'database',
        storage_dir => '/var/app/sessions',
    );

    # Create a new session
    my $result = $sessions->new_session(
        user_id => 'user123',
        data    => { cart => [], preferences => {} },
    );

    my $session = $result->{session};

    # Read session data
    my $data_result = $session->get_data();
    my $data = $data_result->{value};

    # Modify session data
    $data->{cart} = ['item1', 'item2'];
    $data->{preferences}{theme} = 'dark';

    # Write modified data back (marks session as dirty)
    $session->set_data($data);

    # Check if session needs saving
    if ($session->is_dirty()) {
        $session->save();  # Persists to backend and extends timeout
    }

    # Check session status
    if ($session->is_valid()) {
        # Session is active and not expired
    }

    # Access session metadata
    my $id      = $session->session_id();
    my $created = $session->created_at();
    my $expires = $session->expires_at();

=head1 DESCRIPTION

Session objects represent individual user sessions and provide methods for
data access, persistence, and status checking. They are created by the
Concierge::Sessions factory and returned in the result hashref.

Session objects implement an explicit persistence model with dirty flag tracking.
Changes made via set_data() are only in memory until save() is called.

=head1 METHODS

=head2 Data Access Methods

=head3 get_data

Retrieves the entire session data field.

    my $result = $session->get_data();
    my $data = $result->{value};

Parameters:

None.

Returns:

    {
        success => 1,
        value => $data_hashref,  # Entire session data structure
    }

The data field can contain any data structure that can be represented as JSON:
scalars, arrays, hashes, and nested combinations thereof.

=head3 set_data

Replaces the entire session data field with new data.

    my $result = $session->set_data(\%new_data);

Parameters:

=over 4

=item * C<\%new_data> - Hashref containing the new session data. This completely
                     replaces the existing data field.

=back

Returns:

    {
        success => 1,
    }

This method:

=over 4

=item * Replaces the entire data field (not a merge)

=item * Marks the session as dirty (unsaved changes exist)

=item * Does NOT persist to backend (call save() for that)

=back

Example:

    my $data = $session->get_data()->{value};
    $data->{username} = 'alice';
    $data->{items} = [1, 2, 3];
    $session->set_data($data);  # Data replaced, session now dirty
    $session->save();            # Persist to backend

=head3 save

Persists dirty session data to the backend storage.

    my $result = $session->save();

Parameters:

None.

Returns:

    {
        success => 1,
    }

Or on error:

    {
        success => 0,
        message => "Error description",
    }

This method:

=over 4

=item * Is a no-op if the session is not dirty (returns success immediately)

=item * Writes the entire data field to backend storage

=item * Updates the last_updated timestamp

=item * Extends the session expiration (sliding window)

=item * Clears the dirty flag on success

=back

The save() method also implements sliding window expiration. Each save() extends
the session timeout from the current time, keeping active sessions alive.

For indefinite sessions (session_timeout set to 'indefinite'), save() still
persists data but does not modify expiration (session never expires).

=head2 Status Check Methods

=head3 is_valid

Returns true if the session is both active and not expired.

    my $valid = $session->is_valid();

This is a convenience method that combines is_active() and is_expired():

    return ($session->is_active() && !$session->is_expired()) ? 1 : 0;

Returns: 1 if valid, 0 if invalid.

Use this to check if a session can be used before accessing its data.

=head3 is_active

Returns true if the session state is 'active'.

    my $active = $session->is_active();

Returns: 1 if active, 0 if inactive.

Currently, all sessions are created in the 'active' state and there is no
API to change the state to inactive. This method is provided for future
extensibility.

=head3 is_expired

Returns true if the session has passed its expiration time.

    my $expired = $session->is_expired();

Returns: 1 if expired, 0 if not expired.

For indefinite sessions (session_timeout set to 'indefinite'), this method
always returns 0 (never expires).

Example:

    if ($session->is_expired()) {
        # Session has expired, user must re-authenticate
    } else {
        # Session is still valid
    }

=head3 is_dirty

Returns true if the session has unsaved changes.

    my $dirty = $session->is_dirty();

Returns: 1 if dirty (unsaved changes), 0 if clean.

A session becomes dirty when set_data() is called. The dirty flag is cleared
when save() successfully persists the changes.

Use this to optimize performance - only save when there are actual changes:

    $session->set_data($new_data);
    if ($session->is_dirty()) {
        $session->save();
    }

=head2 Accessor Methods

=head3 session_id

Returns the unique session identifier.

    my $id = $session->session_id();

Returns: 40-character lowercase hex string (cryptographically random).

This ID is generated when the session is created and remains constant for
the life of the session. Use it to retrieve the session later via
Concierge::Sessions->get_session($id).

=head3 created_at

Returns the session creation timestamp.

    my $created = $session->created_at();

Returns: Numeric timestamp (seconds since epoch, with fractional seconds).

This timestamp is set when the session is created and never changes.

=head3 expires_at

Returns the session expiration timestamp.

    my $expires = $session->expires_at();

Returns: Numeric timestamp (seconds since epoch), or the string 'indefinite'
for sessions that never expire.

The expiration time is extended each time save() is called (sliding window).

For indefinite sessions, returns the literal string 'indefinite'.

=head3 last_updated

Returns the timestamp of the last save() operation.

    my $updated = $session->last_updated();

Returns: Numeric timestamp (seconds since epoch, with fractional seconds),
or undef if the session has never been saved.

This timestamp is updated each time save() persists data to the backend.

=head3 storage_backend

Returns the backend class name.

    my $backend = $session->storage_backend();

Returns: String such as 'Concierge::Sessions::SQLite' or
'Concierge::Sessions::File'.

Useful for debugging or when you need to know which backend is storing
the session data.

=head3 status

Returns the session status hashref.

    my $status = $session->status();
    # Returns: { state => 'active', dirty => 0 }

Returns: Hashref with keys:

=over 4

=item * C<state> - Session state ('active' or other values)

=item * C<dirty> - Dirty flag (1 if unsaved changes, 0 if clean)

=back

This provides direct access to the internal status structure. For most use
cases, the is_active(), is_dirty(), and is_expired() methods are more
convenient.

=head1 EXPLICIT PERSISTENCE

Session objects use an explicit persistence model. Changes are NOT automatically
saved:

    # 1. Get current data
    my $data = $session->get_data()->{value};

    # 2. Modify the data
    $data->{cart} = ['item1', 'item2'];

    # 3. Write back (changes are in-memory only)
    $session->set_data($data);

    # 4. Session is now dirty (unsaved changes)
    $session->is_dirty();  # Returns 1

    # 5. Persist to backend (also extends timeout)
    $session->save();

    # 6. Session is now clean
    $session->is_dirty();  # Returns 0

If you don't call save(), the changes are lost when the session object goes
out of scope. No automatic saving happens on scope exit.

The save() method is optimized - it's a no-op if the session is not dirty,
so it's safe to call multiple times:

    $session->save();  # Not dirty, returns immediately
    $session->set_data($new_data);
    $session->save();  # Actually saves

=head1 SLIDING WINDOW EXPIRATION

Each call to save() extends the session timeout, creating a "sliding window"
expiration:

    # Session created with 1 hour timeout
    my $session = $sessions->new_session(
        user_id         => 'user123',
        session_timeout => 3600,
    )->{session};

    # Session expires at: time + 3600

    # User is active after 30 minutes
    sleep 1800;
    $session->save();

    # Session now expires at: current_time + 3600

This keeps active users logged in indefinitely, while inactive sessions
expire naturally after the timeout period.

For indefinite sessions (session_timeout set to 'indefinite'), save() still
persists data but does not change expiration (the session never expires).

=head1 OPAQUE DATA STORAGE

The session data field is opaque - the application controls the structure
and content. Concierge::Sessions simply stores and retrieves whatever data
you provide, without interpretation.

    # Store any data structure
    $session->set_data({
        user_id     => 'user123',
        cart        => [\%items],
        preferences => {
            theme    => 'dark',
            language => 'en',
        },
        nested => {
            deeply => {
                data => [1, 2, 3],
            },
        },
    });

There are no key-value operations or JSON path queries. Use get_data() to
retrieve the entire data structure, modify it as needed, then set_data()
to replace it.

This design gives applications complete control over their session data
structure without any constraints from the session management system.

=head1 EXAMPLES

=head2 Basic Data Access

    my $session = $sessions->new_session(
        user_id => 'user123',
        data    => { cart => [] },
    )->{session};

    # Add item to cart
    my $data = $session->get_data()->{value};
    push @{$data->{cart}}, 'item1';
    $session->set_data($data);
    $session->save();

=head2 Conditional Save

    # Only save if data changed
    my $data = $session->get_data()->{value};
    $data->{last_access} = time();

    $session->set_data($data);
    if ($session->is_dirty()) {
        $session->save();
    }

=head2 Session Validation

    sub require_valid_session {
        my ($session) = @_;

        unless ($session && $session->is_valid()) {
            die "Invalid or expired session";
        }

        return $session;
    }

=head2 Tracking Session Age

    my $session = $sessions->new_session(
        user_id => 'user123',
    )->{session};

    my $created = $session->created_at();
    my $age = time() - $created;

    if ($age > 7200) {  # 2 hours
        # Force user to re-authenticate
    }

=head1 SEE ALSO

L<Concierge::Sessions> - Factory for creating session objects

L<Concierge::Sessions::SQLite> - SQLite backend implementation

L<Concierge::Sessions::File> - File backend implementation

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

Artistic License 2.0

=cut
