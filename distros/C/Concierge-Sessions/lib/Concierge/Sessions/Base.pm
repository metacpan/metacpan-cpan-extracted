package Concierge::Sessions::Base v0.11.1;
use v5.36;

use Crypt::PRNG qw(random_bytes);

sub new {
    my ($class, %args) = @_;
    return bless {}, $class;
}

# Define interface methods that must be implemented by subclasses
sub create_session { die "Subclass must implement create_session" }
sub get_session_info { die "Subclass must implement get_session_info" }
sub update_session { die "Subclass must implement update_session" }
sub delete_session { die "Subclass must implement delete_session" }
sub cleanup_sessions { die "Subclass must implement cleanup_sessions" }
sub delete_user_session { die "Subclass must implement delete_user_session" }

# Utilities
sub generate_session_id {
    return unpack('H*', random_bytes(20));
}

1;

__END__

=head1 NAME

Concierge::Sessions::Base - Base class for session storage backends

=head1 VERSION

v0.11.1

=head1 SYNOPSIS

    # This is a base class - do not use directly
    # Backend implementations inherit from this class:

    package Concierge::Sessions::MyBackend;
    use parent 'Concierge::Sessions::Base';

    sub create_session {
        my ($self, %args) = @_;
        # Implementation...
    }

    # Implement other required methods...

=head1 DESCRIPTION

Concierge::Sessions::Base is a base class that defines the interface for
session storage backends. Backend implementations (SQLite, File) inherit
from this class and must implement the defined methods.

This class also provides utility methods such as generate_session_id().

Users typically do not interact with this class directly - they use
Concierge::Sessions which manages backend objects internally.

=head1 REQUIRED METHODS

Backend implementations must implement the following methods:

=head2 create_session

Creates a new session in the backend storage.

    my $result = $backend->create_session(
        user_id         => 'user123',
        session_timeout => 3600,
        data            => \%session_data,
    );

Must return:

    {
        success => 1,
        session_id => 'hex-string',
    }

=head2 get_session_info

Retrieves session information from backend storage.

    my $result = $backend->get_session_info($session_id);

Must return:

    {
        success => 1,
        info => {
            session_id      => 'hex-string',
            user_id         => 'user123',
            session_timeout => 3600,
            data            => \%data,
            created_at      => $timestamp,
            expires_at      => $timestamp,
            last_updated    => $timestamp,
            status          => { state => 'active', dirty => 0 },
        },
    }

Or on error:

    {
        success => 0,
        message => "Error description",
    }

=head2 update_session

Updates session data and metadata in backend storage.

    my $result = $backend->update_session(
        $session_id,
        {
            data       => \%new_data,
            expires_at => $new_expiration,
        },
    );

Must return:

    {
        success => 1,
    }

Or on error:

    {
        success => 0,
        message => "Error description",
    }

=head2 delete_session

Deletes a session from backend storage.

    my $result = $backend->delete_session($session_id);

Must return:

    {
        success => 1,
        message => "Session deleted",
    }

=head2 cleanup_sessions

Removes all expired sessions from backend storage.

    my $result = $backend->cleanup_sessions();

Must return:

    {
        success => 1,
        deleted_count => 15,
    }

=head2 delete_user_session

Deletes all sessions for a specific user from backend storage.

    my $result = $backend->delete_user_session($user_id);

Must return:

    {
        success => 1,
        deleted_count => 3,
    }

=head1 UTILITY METHODS

=head2 generate_session_id

Generates a cryptographically secure random session ID.

    my $id = $backend->generate_session_id();

Returns: 40-character lowercase hex string (160 bits of entropy) generated
from a cryptographically secure PRNG via L<Crypt::PRNG>.

=head1 SEE ALSO

L<Concierge::Sessions::SQLite> - SQLite backend implementation

L<Concierge::Sessions::File> - File backend implementation

L<Concierge::Sessions> - Session manager

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

Artistic License 2.0

=cut
