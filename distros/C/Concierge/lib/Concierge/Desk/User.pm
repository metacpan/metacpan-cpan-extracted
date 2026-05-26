package Concierge::Desk::User v0.8.0;
use v5.36;

our $VERSION = 'v0.8.0';

# ABSTRACT: User object enabled by Concierge

use File::Spec;
use File::Path qw/make_path/;

# === COMPONENT MODULES ===
use Concierge::Auth;
use Concierge::Sessions;
use Concierge::Users;

sub enable_user {
    my ($class, $user_id, $options) = @_;
    $options //= {};  # Default to empty hashref if not provided

    # $options = {
    #     session            => $session_obj,          # optional - for guest/logged-in
    #     user_data          => $user_data_hash,       # optional - for logged-in only
    #     user_key           => $external_key,         # optional - reuse existing or generate new
    #     _get_user_data     => $closure,              # optional - for logged-in users
    #     _update_user_data  => $closure,              # optional - for logged-in users
    # }

    my $self = bless {
        user_id  => $user_id,
        user_key => $options->{user_key} || scalar(Concierge::Auth->gen_random_string(13)),
    }, $class;

    # Store session reference and ID if provided
    if ($options->{session}) {
        $self->{session} = $options->{session};
        $self->{session_id} = $options->{session}->session_id();
    }

    # Store user_data snapshot in memory if provided (logged-in users)
    $self->{user_data} = $options->{user_data} if $options->{user_data};

    # Store closures for backend access (if logged-in user)
    $self->{_get_user_data} = $options->{_get_user_data} if $options->{_get_user_data};
    $self->{_update_user_data} = $options->{_update_user_data} if $options->{_update_user_data};

    # Determine user type (for status methods)
    $self->{is_visitor} = !$options->{session} && !$options->{user_data};
    $self->{is_guest} = $options->{session} && !$options->{user_data};
    $self->{is_logged_in} = $options->{session} && $options->{user_data};

    return $self;  # Return blessed object directly (not wrapped)
}

# =============================================================================
# IDENTITY & METADATA - Direct scalar returns
# =============================================================================

sub user_id ($self) {
    return $self->{user_id};
}

sub user_key ($self) {
    return $self->{user_key};
}

sub session_id ($self) {
    return $self->{session_id};  # undef if visitor/no session
}

# =============================================================================
# STATUS METHODS - Direct boolean returns
# =============================================================================

sub is_visitor ($self) {
    return $self->{is_visitor} ? 1 : 0;
}

sub is_guest ($self) {
    return $self->{is_guest} ? 1 : 0;
}

sub is_logged_in ($self) {
    return $self->{is_logged_in} ? 1 : 0;
}

# =============================================================================
# SESSION ACCESS - Returns session object
# =============================================================================

sub session ($self) {
    return $self->{session};  # undef if no session (visitor)
}

sub get_session_data ($self) {
    return undef unless $self->{session};
    my $result = $self->{session}->get_data();
    return $result->{value} // {};
}

sub update_session_data ($self, $updates) {
    return undef unless $self->{session};

    my $result = $self->{session}->get_data();
    my $current = $result->{value} // {};

    # Merge updates into current data
    for my $key (keys %$updates) {
        $current->{$key} = $updates->{$key};
    }

    $self->{session}->set_data($current);
    $self->{session}->save();

    return 1;
}

# =============================================================================
# USER DATA - Quick access from memory snapshot
# =============================================================================

sub moniker ($self) {
    return $self->{user_data}{moniker};
}

sub email ($self) {
    return $self->{user_data}{email};
}

sub user_status ($self) {
    return $self->{user_data}{user_status};
}

sub access_level ($self) {
    return $self->{user_data}{access_level};
}

sub get_user_field ($self, $field) {
    return $self->{user_data}{$field};
}

# =============================================================================
# USER DATA - Backend operations via closures
# =============================================================================

sub refresh_user_data ($self) {
    # Fetch fresh data from backend, update memory snapshot
    return undef unless $self->{_get_user_data};

    my $result = $self->{_get_user_data}->();
    return undef unless $result->{success};

    $self->{user_data} = $result->{user};
    return 1;
}

sub update_user_data ($self, $updates) {
    # Update backend AND memory snapshot
    return undef unless $self->{_update_user_data};

    my $result = $self->{_update_user_data}->($updates);
    return undef unless $result->{success};

    # Update memory snapshot with new values
    for my $field (keys %$updates) {
        $self->{user_data}{$field} = $updates->{$field};
    }

    return 1;
}

1;

__END__

=head1 NAME

Concierge::Desk::User - User object enabled by Concierge

=head1 VERSION

v0.8.0

=head1 SYNOPSIS

    # User objects are created by Concierge lifecycle methods,
    # not directly by applications.

    my $login = $concierge->login_user({
        user_id  => 'alice',
        password => 'secret123',
    });
    my $user = $login->{user};

    # Identity
    say $user->user_id;       # "alice"
    say $user->user_key;      # random token
    say $user->session_id;    # random hex string

    # Status
    say $user->is_logged_in;  # 1
    say $user->is_guest;      # 0
    say $user->is_visitor;    # 0

    # User data (from memory snapshot)
    say $user->moniker;
    say $user->email;
    say $user->get_user_field('role');

    # Update user data (writes to backend and memory)
    $user->update_user_data({ theme => 'dark' });

    # Refresh from backend
    $user->refresh_user_data;

    # Session data (get, merge-update, save in one call)
    my $data = $user->get_session_data;
    $user->update_session_data({ last_page => '/dashboard' });

    # Raw session access when needed
    my $session = $user->session;

=head1 DESCRIPTION

Concierge::Desk::User represents a user operating an instance of the application.
Objects are created by Concierge's lifecycle methods (C<admit_visitor>,
C<checkin_guest>, C<login_user>) and returned to the application.

The available methods depend on the user's participation level:

=over 4

=item B<Visitor> -- identity and status methods only

=item B<Guest> -- adds session access

=item B<Logged-in> -- adds user data access, backend read/write

=back

Logged-in user objects hold a snapshot of user data in memory. The
C<refresh_user_data> and C<update_user_data> methods synchronize with the
backend storage via closures provided at construction time. The user object
does not need to know about or contact the concierge to access its backends.

=head1 CONSTRUCTOR

=head2 enable_user

    my $user = Concierge::Desk::User->enable_user($user_id, \%options);

Called internally by Concierge. Applications should not call this directly.

C<%options> may include:

=over 4

=item C<session> -- a L<Concierge::Sessions::Session> object

=item C<user_data> -- hashref of user data fields

=item C<user_key> -- reuse an existing key (otherwise one is generated)

=item C<_get_user_data> -- closure for reading from the Users backend

=item C<_update_user_data> -- closure for writing to the Users backend

=back

=head1 METHODS

=head2 Identity

=head3 user_id

    my $id = $user->user_id;

Returns the user's identifier string.

=head3 user_key

    my $key = $user->user_key;

Returns the user's key token. For visitors and guests, this is the same
as the generated user_id. For logged-in users, it is a separate random
token.

=head3 session_id

    my $sid = $user->session_id;

Returns the session ID, or C<undef> if the user has no session (visitors).

=head2 Status

=head3 is_visitor

Returns 1 if the user is a visitor (no session, no user data).

=head3 is_guest

Returns 1 if the user is a guest (has session, no user data).

=head3 is_logged_in

Returns 1 if the user is logged in (has session and user data).

=head2 Session Access

=head3 session

    my $session = $user->session;

Returns the L<Concierge::Sessions::Session> object, or C<undef> for
visitors. The session object provides C<get_data>, C<set_data>, C<save>,
and status methods.

=head3 get_session_data

    my $data = $user->get_session_data;

Returns the user's session data as a hashref, or an empty hashref if
no data has been stored. Returns C<undef> for visitors (no session).

=head3 update_session_data

    $user->update_session_data({ cart => \@items, last_page => '/shop' });

Merges C<%updates> into the existing session data and saves to persistent
storage. Existing keys not present in C<%updates> are preserved. Returns
1 on success, C<undef> if the user has no session (visitors).

=head2 User Data -- Memory Snapshot

These methods read from the in-memory data snapshot loaded at login time.
They return C<undef> for visitors and guests.

=head3 moniker

=head3 email

=head3 user_status

=head3 access_level

=head3 get_user_field

    my $value = $user->get_user_field('role');

Returns the value of any field in the user data snapshot.

=head2 User Data -- Backend Operations

These methods require a logged-in user (backend closures must be present).
They return C<undef> if called on a visitor or guest.

=head3 refresh_user_data

    $user->refresh_user_data;

Fetches fresh data from the Users backend and replaces the in-memory
snapshot. Returns 1 on success, C<undef> on failure.

=head3 update_user_data

    $user->update_user_data({ theme => 'dark', role => 'editor' });

Writes C<%updates> to the Users backend and merges them into the
in-memory snapshot. Returns 1 on success, C<undef> on failure.

=head1 SEE ALSO

L<Concierge> -- creates User objects via lifecycle methods

L<Concierge::Sessions::Session> -- session object API

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
