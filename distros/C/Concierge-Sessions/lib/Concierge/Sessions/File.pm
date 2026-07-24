package Concierge::Sessions::File v0.11.3;
use v5.36;

use parent 'Concierge::Sessions::Base';

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

    unless (chmod 0700, $self->{storage_dir}) {
        croak "Failed to set permissions on storage directory '$self->{storage_dir}': $!";
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

    my $session_id		= $self->generate_session_id();

    my $session_file	= File::Spec->catfile($self->{storage_dir}, $session_id);

    # Write over session file if it already exists (unlikely)
    my $fh;
	unless (open $fh, '>', $session_file) {
		return { success => 0, message => "Cannot create session file: $!" };
	}
	unless (chmod 0600, $session_file) {
		close $fh;
		return { success => 0, message => "Cannot set session file permissions: $!" };
	}

    # Build session_info structure
    my $now = time();

    # Handle session timeout: 'indefinite' or numeric value in seconds
    my $timeout = $args{session_timeout} || $self->{session_timeout};
    my $expiration;
    if (defined $timeout && $timeout eq 'indefinite') {
        $expiration = 'indefinite';
    } else {
        $expiration = $now + $timeout;
    }

    my $data	= $args{data} || {}; # for app data
    my $session_info = {
		session_id	     => $session_id,
		user_id         => $user_id,
        created_at      => $now,
        expires_at      => $expiration,
        last_updated    => $now,
        session_timeout => $timeout,
        status          => {
            state => 'active',
            dirty => 0,
        },
        data            => $data,
    };

    # Encode to JSON with pretty formatting and write with trailing newline
    my $json = JSON::PP->new->utf8->pretty->encode($session_info);
    unless (print $fh $json, "\n") {
        close $fh;
        return { success => 0, message => "Cannot write to session file: $!" };
    }

    unless (close $fh) {
        return { success => 0, message => "Cannot close session file: $!" };
    }

    return { success => 1, session_id => $session_id };
}

sub get_session_info {
    my ($self, $session_id) = @_;

    unless ($session_id) {
        return { success => 0, message => "Session ID required to retrieve session from File backend" };
    }

    my $session_file = File::Spec->catfile($self->{storage_dir}, $session_id);

    unless (-f $session_file) {
        return { success => 0, message => "Session file not found" };
    }

    my $fh;
    unless (open $fh, '<', $session_file) {
        return { success => 0, message => "Cannot read session file: $!" };
    }

    # Read entire file (pretty JSON spans multiple lines)
    local $/;
    my $json = <$fh>;
    unless (close $fh) {
        return { success => 0, message => "Error closing session file: $!" };
    }
    unless (defined $json) {
        close $fh;
        return { success => 0, message => "Session file is empty" };
    }

    # Decode JSON
    my $session_info;
    eval {
        $session_info = JSON::PP->new->utf8->decode($json);
    };
    if ($@) {
        return { success => 0, message => "Invalid JSON in session file: $@" };
    }

    unless ($session_info->{session_id} && $session_info->{created_at} && $session_info->{expires_at}) {
        return { success => 0, message => "Invalid session file: missing system status fields" };
    }

    # Check expiration (skip if indefinite)
    if ($session_info->{expires_at} ne 'indefinite' && time() > $session_info->{expires_at}) {
        return { success => 0, message => "Session expired" };
    }

    return {
        success => 1,
        message => "Session info retrieved",
        info => $session_info
    };
}

sub update_session {
    my ($self, $session_id, $updates) = @_;

    unless ($session_id) {
        return { success => 0, message => "Session ID required to update session in File backend" };
    }

    unless ($updates) {
        return { success => 1, message => "No updates specified for File backend session update" };
    }

    my $session_file = File::Spec->catfile($self->{storage_dir}, $session_id);
    my $fh;
    unless (open $fh, '+<', $session_file) {
        return { success => 0, message => "Cannot open or update session file: $!" };
    }

    # Read entire file (pretty JSON spans multiple lines)
    local $/;
    my $json = <$fh>;
    my $session_info;
    if ($json) {
		eval {
			$session_info = JSON::PP->new->utf8->decode($json);
		};
		if ($@) {
			return { success => 0, message => "Invalid JSON in session file: $@" };
		}
	}

    # Apply updates
    if (exists $updates->{data}) {
        $session_info->{data} = $updates->{data} || {};
    }

    if (exists $updates->{expires_at}) {
        $session_info->{expires_at} = $updates->{expires_at};
    }

    # Always update last_updated timestamp
    $session_info->{last_updated} = time();

    # Encode to JSON with pretty formatting and write to file with trailing newline
    my $new_json = JSON::PP->new->utf8->pretty->encode($session_info);
    $fh->truncate(0);
    seek $fh, 0, 0;
    unless (print $fh $new_json, "\n") {
        close $fh;
        return { success => 0, message => "Cannot write to session file: $!" };
    }

    unless (close $fh) {
        return { success => 0, message => "Cannot close session file: $!" };
    }

    return { success => 1 };
}

sub delete_session {
    my ($self, $session_id) = @_;

    unless ($session_id) {
        return { success => 0, message => "Session ID required to delete session from File backend" };
    }

    my $session_file = File::Spec->catfile($self->{storage_dir}, $session_id);

    unless (-f $session_file) {
        return { success => 1, message => "Session file not found to delete" };
    }

    unless (unlink $session_file) {
        return { success => 0, message => "Cannot delete session file: $!" };
    }

    return { success => 1 };
}

sub cleanup_sessions {
    my ($self) = @_;

    my $dh;
    unless (opendir($dh, $self->{storage_dir})) {
        return { success => 0, message => "Cannot open sessions directory: $!" };
    }

    my $deleted_count	= 0;
    my $active			= [];
    while (my $file = readdir($dh)) {
        next if $file =~ /^\.\.?$/;  # Skip . and ..
        # Skip any files in the dir with suffixes, which session files don't have
        next if $file =~ /\.\w{1,6}$/;
		# Session files are named after session_ids, so this works:
        my $get_result = $self->get_session_info($file);
        if ($get_result->{success}) {
        	push $active->@* => $file;
        }
        else {
            # Session is either expired or invalid, delete the file
            my $delete_result = $self->delete_session($file);
            if ($delete_result->{success}) {
                $deleted_count++;
            }
        }
    }

    unless (closedir $dh) {
        return { success => 0, message => "Error closing sessions directory: $!" };
    }

    return { success => 1, deleted_count => $deleted_count, active => $active };
}

sub delete_user_session {
    my ($self, $user_id) = @_;

    unless ($user_id) {
        return { success => 0, message => "user_id required to delete user sessions from File backend" };
    }

    opendir(my $dh, $self->{storage_dir}) or return {
        success => 0,
        message => "Cannot open sessions directory: $!"
    };

    my $deleted_count = 0;

    while (my $file = readdir($dh)) {
        next if $file =~ /^\.\.?$/;  # Skip . and ..
        next if $file =~ /\.\w{1,6}$/;  # Skip files with extensions (not session files)

        my $session_file = File::Spec->catfile($self->{storage_dir}, $file);

        # Read and parse to check user_id
        open my $fh, '<', $session_file or next;
        local $/;
        my $json = <$fh>;
        close $fh;

        next unless defined $json;

        my $session_info;
        eval {
            $session_info = JSON::PP->new->utf8->decode($json);
        };
        next if $@;  # Skip invalid files

        # Delete if user_id matches
        if ($session_info->{user_id} eq $user_id) {
            if (unlink $session_file) {
                $deleted_count++;
            }
        }
    }

    closedir($dh);

    return { success => 1, deleted_count => $deleted_count };
}

sub DESTROY {
    my ($self) = @_;
}

1;

__END__

=head1 NAME

Concierge::Sessions::File - File backend for session storage

=head1 VERSION

v0.11.3

=head1 SYNOPSIS

    # Used internally by Concierge::Sessions
    my $sessions = Concierge::Sessions->new(
        backend     => 'file',
        storage_dir => '/tmp/sessions',
    );

=head1 DESCRIPTION

Concierge::Sessions::File provides file-based storage for session data.
Each session is stored as a separate JSON file named after the session ID.
This backend is useful for testing, development, and debugging.

This backend inherits from Concierge::Sessions::Base and implements all
required backend methods. Users typically do not interact with this class
directly - they use Concierge::Sessions which manages the backend.

=head1 FEATURES

=over 4

=item * Human-readable JSON format for easy debugging

=item * Simple file system operations

=item * No database dependencies

=item * Suitable for testing and development

=item * Lower performance than SQLite (~1,000 ops/sec vs 4,000-5,000)

=back

=head1 STORAGE

Each session is stored as a separate JSON file in the storage_dir:

    /path/to/storage_dir/
        - 3a7f2b9c01e84d5f6a0b1c2d3e4f5a6b7c8d9e0f
        - 9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c
        - ...

File names are the session_id (no extension).

File contents:

    {
        "session_id": "3a7f2b9c01e84d5f6a0b1c2d3e4f5a6b7c8d9e0f",
        "user_id": "user123",
        "created_at": 1737526800.12345,
        "expires_at": 1737530400.12345,
        "last_updated": 1737526800.12345,
        "session_timeout": 3600,
        "status": { "state": "active", "dirty": 0 },
        "data": { "cart": [], "preferences": {} }
    }

=head1 PERFORMANCE

The File backend provides moderate performance suitable for testing:

=over 4

=item * Create session: ~0.001 seconds

=item * Get session: ~0.001 seconds

=item * Update session: ~0.001 seconds

=item * Delete session: ~0.001 seconds

=back

Performance depends on file system speed and can vary significantly between
systems. For production use, consider the SQLite backend.

=head1 USAGE

This backend is ideal for:

=over 4

=item * Development and testing

=item * Debugging (view session data directly in text editor)

=item * Environments without database support

=item * Learning and experimentation

=back

For production deployments, use the SQLite backend for better performance
and reliability.

=head1 SEE ALSO

L<Concierge::Sessions> - Session manager

L<Concierge::Sessions::Base> - Backend base class

L<Concierge::Sessions::SQLite> - SQLite backend implementation

L<JSON::PP> - JSON encoding/decoding

L<File::Spec> - File path operations

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

Artistic License 2.0

=cut
