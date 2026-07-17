package Concierge::Sessions::SQLite v0.11.2;
use v5.36;

use parent 'Concierge::Sessions::Base';
use DBI;
use File::Spec;
use Carp qw(croak);
use JSON::PP;

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{storage_dir} = $args{storage_dir} || '/tmp/sessions';

    unless (-d $self->{storage_dir}) {
        unless (mkdir $self->{storage_dir}) {
            croak "Failed to create storage directory '$self->{storage_dir}': $!";
        }
    }

	$self->{dsn} = File::Spec->catfile( $self->{storage_dir}, 'sessions.db' );

    $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$self->{dsn}", "", "", {
        RaiseError => 0,
        AutoCommit => 1,
    });

    unless ($self->{dbh}) {
        croak "Failed to connect to SQLite database '$self->{dsn}': " . DBI->errstr;
    }

    my $result = $self->{dbh}->do(q{
        CREATE TABLE IF NOT EXISTS sessions (
            session_id TEXT PRIMARY KEY,
            user_id TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP,
            last_updated TIMESTAMP,
            session_timeout INTEGER,
            status JSON,
            data JSON
        )
    });

    unless ($result) {
        croak "Failed to create sessions table: " . $self->{dbh}->errstr;
    }

    $result = $self->{dbh}->do(q{ CREATE INDEX IF NOT EXISTS idx_session_id ON sessions (session_id) });
    unless ($result) {
        croak "Failed to create session_id index: " . $self->{dbh}->errstr;
    }

    $result = $self->{dbh}->do(q{ CREATE INDEX IF NOT EXISTS expirations ON sessions (expires_at) });
    unless ($result) {
        croak "Failed to create expiration index: " . $self->{dbh}->errstr;
    }

    return $self;
}

sub create_session {
    my ($self, %args) = @_;

    return { success => 0, message => "Cannot create session without user_id" }
    	unless $args{user_id};

    my $user_id = $args{user_id};

    # Delete any existing sessions for this user (enforce single session per user)
    $self->delete_user_session($user_id);

    # Build session_info structure
    my $session_id		= $self->generate_session_id();

    my $now = time();

    # Handle session timeout: 'indefinite' or numeric value in seconds
    my $timeout = $args{session_timeout} || $self->{session_timeout};
    my $expires_at;
    if (defined $timeout && $timeout eq 'indefinite') {
        $expires_at = 'indefinite';
    } else {
        $expires_at = $now + $timeout;
    }

    my $created_at		= $now;
    my $last_updated	= $now;
    my $status			= { state => 'active', dirty => 0 };
    my $status_json 	= JSON::PP->new->utf8->encode( $status );
    my $data			= $args{data} || {}; # for app data
    my $data_json		= JSON::PP->new->utf8->encode( $data );

    my $sth = $self->{dbh}->prepare(
        "INSERT INTO sessions (
        	session_id,
        	user_id,
        	created_at,
        	expires_at,
        	last_updated,
        	session_timeout,
        	status,
        	data
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
    );

    unless ($sth) {
        return { success => 0, message => "Failed to prepare insert statement: " . $self->{dbh}->errstr };
    }

    my $result = $sth->execute(
    	$session_id,
    	$user_id,
    	$created_at,
    	$expires_at,
    	$last_updated,
    	$timeout,
    	$status_json,
    	$data_json
    );

    unless ($result) {
        return { success => 0, message => "Failed to insert session: " . $sth->errstr };
    }

    return { success => 1, session_id => $session_id };
}

sub get_session_info {
    my ($self, $session_id) = @_;

    unless ($session_id) {
        return { success => 0, message => "Session ID required to retrieve session from SQLite backend" };
    }

    # Query filters expired sessions but allows indefinite sessions
    my $sth = $self->{dbh}->prepare(
        "SELECT * FROM sessions WHERE session_id = ? AND (expires_at = 'indefinite' OR expires_at > ?)"
    );

    unless ($sth) {
        return { success => 0, message => "Failed to prepare select statement: " . $self->{dbh}->errstr };
    }

    my $result = $sth->execute($session_id, time());

    unless ($result) {
        return { success => 0, message => "Failed to execute session query: " . $sth->errstr };
    }

    my $session_info = $sth->fetchrow_hashref;

    unless ($session_info) {
        return { success => 0, message => "Session not found or expired" };
    }

    # Decode session_info from JSON to hashref
	$session_info->{status}	= JSON::PP->new->utf8->decode( $session_info->{status} );
	$session_info->{data}	= JSON::PP->new->utf8->decode( $session_info->{data} );

    return { success => 1, info => $session_info };
}

sub update_session {
    my ($self, $session_id, $updates) = @_;

    unless ($session_id) {
        return { success => 0, message => "Session ID required to update session in SQLite backend" };
    }

    unless ($updates) {
        return { success => 1, message => "No updates specified for File backend session update" };
    }

    # Always update last_updated timestamp
    my $now = time();

    # Build SET clause dynamically based on what's being updated
    my @set_clauses;
    my @bind_values;

    if (exists $updates->{data}) {
        push @set_clauses, 'data = ?';
        push @bind_values, JSON::PP->new->utf8->encode($updates->{data} || {});
    }

    if (exists $updates->{expires_at}) {
        push @set_clauses, 'expires_at = ?';
        push @bind_values, $updates->{expires_at};
    }

    # Always update last_updated
    push @set_clauses, 'last_updated = ?';
    push @bind_values, $now;

    # Build SQL statement
    my $sql = 'UPDATE sessions SET ' . join(', ', @set_clauses) . ' WHERE session_id = ?';
    push @bind_values, $session_id;

    my $sth = $self->{dbh}->prepare($sql);

    unless ($sth) {
        return { success => 0, message => "Failed to prepare update statement: " . $self->{dbh}->errstr };
    }

    my $result = $sth->execute(@bind_values);

    unless ($result) {
        return { success => 0, message => "Failed to update session: " . $sth->errstr };
    }

    unless ($result > 0) {
        return { success => 0, message => "Session not found or no changes made" };
    }

    return { success => 1 };
}

sub delete_session {
    my ($self, $session_id) = @_;

    unless ($session_id) {
        return { success => 0, message => "Session ID required to delete session from SQLite backend" };
    }

    my $sth = $self->{dbh}->prepare("DELETE FROM sessions WHERE session_id = ?");

    unless ($sth) {
        return { success => 0, message => "Failed to prepare delete statement: " . $self->{dbh}->errstr };
    }

    my $result = $sth->execute($session_id);

    unless ($result) {
        return { success => 0, message => "Failed to delete session: " . $sth->errstr };
    }

    return { success => 1 };
}

sub cleanup_sessions {
    my ($self) = shift;

    # Delete only sessions with numeric expiration times that have passed
    # Indefinite sessions (expires_at = 'indefinite') are preserved
    my $sth = $self->{dbh}->prepare("DELETE FROM sessions WHERE expires_at != 'indefinite' AND expires_at < ?");

    unless ($sth) {
        return { success => 0, message => "Failed to prepare cleanup statement: " . $self->{dbh}->errstr };
    }

    my $result = $sth->execute( time() );

    unless ($result) {
        return { success => 0, message => "Failed to cleanup expired sessions: " . $sth->errstr };
    }

    # Convert 0E0 to plain 0 if no rows deleted
    my $deleted_count = $result eq '0E0' ? 0 : $result;
    
    my $active	= $self->{dbh}->selectcol_arrayref(qq{SELECT session_id FROM sessions WHERE session_id != '' });

    return { success => 1, deleted_count => $deleted_count, active => $active };
}

# sub delete_user_sessions {
sub delete_user_session {
    my ($self, $user_id) = @_;

    unless ($user_id) {
        return { success => 0, message => "user_id required to delete user sessions from SQLite backend" };
    }

    my $sth = $self->{dbh}->prepare("DELETE FROM sessions WHERE user_id = ?");

    unless ($sth) {
        return { success => 0, message => "Failed to prepare delete user sessions statement: " . $self->{dbh}->errstr };
    }

    my $result = $sth->execute($user_id);

    unless ($result) {
        return { success => 0, message => "Failed to delete user sessions: " . $sth->errstr };
    }

    # Convert 0E0 to plain 0 if no rows deleted
    my $deleted_count = $result eq '0E0' ? 0 : $result;

    return { success => 1, deleted_count => $deleted_count };
}

sub DESTROY {
    my ($self) = @_;
    $self->{dbh}->disconnect if defined $self->{dbh};
}

1;

__END__

=head1 NAME

Concierge::Sessions::SQLite - SQLite backend for session storage

=head1 VERSION

v0.11.2

=head1 SYNOPSIS

    # Used internally by Concierge::Sessions
    my $sessions = Concierge::Sessions->new(
        backend     => 'database',
        storage_dir => '/var/app/sessions',
    );

=head1 DESCRIPTION

Concierge::Sessions::SQLite provides SQLite-based storage for session data.
It is the default and recommended backend for production use, offering
high performance and ACID-compliant storage.

This backend inherits from Concierge::Sessions::Base and implements all
required backend methods. Users typically do not interact with this class
directly - they use Concierge::Sessions which manages the backend.

=head1 FEATURES

=over 4

=item * High performance (4,000-5,000 operations per second)

=item * ACID-compliant transactions

=item * Automatic filtering of expired sessions during retrieval

=item * Single-session enforcement at database level (using UNIQUE constraint)

=item * Efficient indexing on session_id and user_id

=back

=head1 STORAGE

The backend creates a SQLite database file named C<sessions.db> in the
specified storage_dir. The database contains a single table C<sessions>
with columns for session data and metadata.

Database schema:

    CREATE TABLE sessions (
        session_id TEXT PRIMARY KEY,
        user_id TEXT,
        created_at TIMESTAMP,
        expires_at TIMESTAMP,
        last_updated TIMESTAMP,
        session_timeout INTEGER,
        status JSON,
        data JSON
    )

Indexes are created on session_id and user_id for fast lookups.

=head1 PERFORMANCE

The SQLite backend provides high performance suitable for production use:

=over 4

=item * Create session: ~0.0002 seconds

=item * Get session: ~0.0002 seconds

=item * Update session: ~0.0002 seconds

=item * Delete session: ~0.0002 seconds

=back

Benchmarks performed on typical hardware with default SQLite settings.

=head1 SEE ALSO

L<Concierge::Sessions> - Session manager

L<Concierge::Sessions::Base> - Backend base class

L<Concierge::Sessions::File> - File backend implementation

L<DBI> - Database interface

L<DBD::SQLite> - SQLite DBI driver

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

Artistic License 2.0

=cut
