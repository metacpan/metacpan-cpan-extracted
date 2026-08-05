package Concierge::Desk::User v0.13.0;
use v5.36;

our $VERSION = 'v0.13.0';

# ABSTRACT: User object enabled by Concierge

use File::Spec;
use File::Path qw/make_path/;

# === COMPONENT MODULES ===
use Concierge::Auth::Generators qw(gen_random_string);
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
    #     _verify_password   => $closure,              # optional - for logged-in users
    #     _reset_password    => $closure,              # optional - for logged-in users
    #     _logout            => $closure,              # optional - for guest/logged-in (any user with a session)
    #     _session_valid     => $closure,              # optional - for guest/logged-in (any user with a session)
    # }

    my $self = bless {
        user_id  => $user_id,
        user_key => $options->{user_key} || scalar(gen_random_string(13)),
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
    $self->{_verify_password} = $options->{_verify_password} if $options->{_verify_password};
    $self->{_reset_password} = $options->{_reset_password} if $options->{_reset_password};
    $self->{_logout} = $options->{_logout} if $options->{_logout};
    $self->{_session_valid} = $options->{_session_valid} if $options->{_session_valid};

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

# Internal: is this object's session still live on the backend right now?
# Deliberately a fresh backend check via the _session_valid closure, not a
# check of cached in-memory state -- a *different* Concierge::Desk::User
# instance for the same identity (e.g. from a second restore_user() call)
# can still hold a populated (but now stale) session field after this
# object's own logout() ran, and cached session status wouldn't catch that.
sub _session_ok ($self) {
    return 0 unless $self->{_session_valid};
    my $result = $self->{_session_valid}->();
    return $result->{success} ? 1 : 0;
}

sub get_session_data ($self) {
    return undef unless $self->{session};
    return undef unless $self->_session_ok;
    my $result = $self->{session}->get_data();
    return $result->{value} // {};
}

sub update_session_data ($self, $updates) {
    return undef unless $self->{session};
    return undef unless $self->_session_ok;

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
    return undef unless $self->_session_ok;

    my $result = $self->{_get_user_data}->();
    return undef unless $result->{success};

    $self->{user_data} = $result->{user};
    return 1;
}

sub update_user_data ($self, $updates) {
    # Update backend AND memory snapshot
    return undef unless $self->{_update_user_data};
    return undef unless $self->_session_ok;

    my $result = $self->{_update_user_data}->($updates);
    return undef unless $result->{success};

    # Update memory snapshot with new values
    for my $field (keys %$updates) {
        $self->{user_data}{$field} = $updates->{$field};
    }

    return 1;
}

# =============================================================================
# PASSWORD & LOGOUT - Mirror operations via closures
# =============================================================================

sub verify_password ($self, $password) {
    return undef unless $self->{_verify_password};
    return undef unless $self->_session_ok;

    my $result = $self->{_verify_password}->($password);
    return $result->{success} ? 1 : 0;
}

sub reset_password ($self, $new_password) {
    return undef unless $self->{_reset_password};
    return undef unless $self->_session_ok;

    my $result = $self->{_reset_password}->($new_password);
    return $result->{success} ? 1 : undef;
}

sub logout ($self) {
    return undef unless $self->{_logout};

    my $result = $self->{_logout}->();
    return undef unless $result->{success};

    # Concierge has already done the real work (session deleted, user_key
    # mapping removed). Clean up this object in place so any reference to
    # it the application is still holding degrades to visitor-equivalent
    # status rather than silently retaining backend-write capability or
    # reporting stale identity/session state. user_id and user_key are
    # left intact -- they're inert identity strings, not capabilities.
    delete $self->{$_} for qw(
        _get_user_data _update_user_data
        _verify_password _reset_password _logout _session_valid
        session session_id user_data
    );
    $self->{is_logged_in} = 0;
    $self->{is_guest}     = 0;
    $self->{is_visitor}   = 1;

    return 1;
}

1;

__END__

=head1 NAME

Concierge::Desk::User - User object enabled by Concierge

=head1 VERSION

v0.13.0

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

    # Password & logout (logged-in users; logout also works for guests)
    $user->verify_password('secret123');            # 1, 0, or undef
    $user->reset_password('newsecret456');           # 1 or undef
    $user->logout;                                   # 1 or undef

=head1 DESCRIPTION

Concierge::Desk::User represents a user operating an instance of the application.
Objects are created by Concierge's lifecycle methods (C<admit_visitor>,
C<checkin_guest>, C<login_user>) and returned to the application.

The available methods depend on the user's participation level:

=over 4

=item B<Visitor> -- identity and status methods only

=item B<Guest> -- adds session access, including C<logout>

=item B<Logged-in> -- adds user data access, backend read/write, and
password operations (C<verify_password>, C<reset_password>)

=back

Logged-in user objects hold a snapshot of user data in memory. The
C<refresh_user_data> and C<update_user_data> methods synchronize with the
backend storage via closures provided at construction time. The user object
does not need to know about or contact the concierge to access its backends.
C<verify_password>, C<reset_password>, and C<logout> follow the same
closure-based pattern -- see L</Password & Logout> below for which
participation levels each applies to and why.

A successful C<logout> degrades a guest or logged-in object to
visitor-equivalent status in place -- see L</logout> for exactly what
gets cleared. Participation level is therefore not necessarily fixed
for the lifetime of a C<$user> object; it can only ever move toward
visitor, never the other way.

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

=item C<_verify_password> -- closure for checking a password via Auth

=item C<_reset_password> -- closure for setting a new password via Auth

=item C<_logout> -- closure for deleting the user's session

=item C<_session_valid> -- closure for checking the session is still live

=back

C<_get_user_data>, C<_update_user_data>, C<_verify_password>, and
C<_reset_password> are only ever provided for logged-in users -- they
require an Auth-backed identity and/or a Users-backend record that
guests and visitors don't have. C<_logout> and C<_session_valid> are
provided for any user holding a session (guest or logged-in), since
both only require a C<session_id>, not an identity.

C<_session_valid> backs a fresh, per-call check against the Sessions
backend (not a check of any cached in-memory field) used internally by
every method that reads or writes session data, user data, or a
password -- see L</Password & Logout> and L</Session Access> below. It
exists because a session can become invalid out from under a C<$user>
object through no fault of that object's own C<logout> (e.g. expiry, or
a I<different> C<Concierge::Desk::User> instance for the same identity
logging out first); relying on cached status would miss that.

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

For ordinary session-data reads and writes, prefer
C<get_session_data>/C<update_session_data> below rather than calling
C<get_data>/C<set_data> directly: those are all-or-nothing (C<set_data>
replaces the entire data hashref), while the user object's methods merge
individual keys and call C<save> for you -- which, as a side effect,
extends the session's expiration via its sliding-window renewal. Reach
for the raw session object only when its status methods, or a deliberate
full replace, are actually needed.

=head3 get_session_data

    my $data = $user->get_session_data;

Returns the user's session data as a hashref, or an empty hashref if
no data has been stored. Returns C<undef> for visitors (no session), or
if the session is no longer valid on the backend (e.g. expired, or
logged out via a different C<$user> object instance for the same
identity).

=head3 update_session_data

    $user->update_session_data({ cart => \@items, last_page => '/shop' });

Merges C<%updates> into the existing session data and saves to persistent
storage, which as a side effect also extends the session's expiration
(sliding-window renewal). Existing keys not present in C<%updates> are
preserved. Returns 1 on success, C<undef> if the user has no session
(visitors) or the session is no longer valid on the backend.

=head2 User Data -- Memory Snapshot

These methods read from the in-memory data snapshot loaded at login time.
They return C<undef> for visitors and guests.

=head3 moniker, email, user_status, access_level

Direct accessors for the corresponding fields in the user data snapshot.

=head3 get_user_field

    my $value = $user->get_user_field('role');

Returns the value of any field in the user data snapshot.

=head2 User Data -- Backend Operations

These methods require a logged-in user (backend closures must be present)
with a currently valid session. They return C<undef> if called on a
visitor or guest, or if the session has since become invalid (expired,
or logged out via a different C<$user> object instance for the same
identity) -- even though the closures themselves are still present.

=head3 refresh_user_data

    $user->refresh_user_data;

Fetches fresh data from the Users backend and replaces the in-memory
snapshot. Returns 1 on success, C<undef> on failure or if the session
is no longer valid.

=head3 update_user_data

    $user->update_user_data({ theme => 'dark', role => 'editor' });

Writes C<%updates> to the Users backend and merges them into the
in-memory snapshot. Returns 1 on success, C<undef> on failure or if the
session is no longer valid.

=head2 Password & Logout

These methods mirror L<Concierge>'s own C<verify_password>,
C<reset_password>, and C<logout_user>, bound at construction time so the
user object doesn't need a C<user_id> or C<session_id> argument, or any
contact with the concierge, to use them. They return a plain scalar
rather than the C<< { success => ... } >> hashref the Concierge-level
methods return -- a deliberate simplification at this convenience layer.

C<verify_password> and C<reset_password> require a logged-in user (an
Auth-backed identity) I<with a currently valid session>; they return
C<undef> for guests and visitors, and also for a logged-in object whose
session has since become invalid (see C<_session_valid> under
L</enable_user> above), even though the object's closures are still in
place. C<logout> only requires a session, so it works for guests as
well as logged-in users; it returns C<undef> only for visitors, who
have no session to log out of.

This session requirement is deliberately I<not> shared by the
corresponding L<Concierge> methods that these mirrors wrap
(C<< $concierge->verify_password($user_id, ...) >>,
C<< $concierge->reset_password($user_id, ...) >>): those remain
identity-scoped and work with no session at all, which real flows
depend on (password-reset-by-email, admin-initiated resets, and
similar). The session check belongs only at this convenience layer,
where the object represents an interactive login and a missing or
invalidated session means it no longer should.

=head3 verify_password

    my $ok = $user->verify_password($password);

Checks C<$password> against the logged-in user's stored credential.
Returns C<1> if correct, C<0> if incorrect, or C<undef> if not
applicable (guest, visitor, or session no longer valid).

=head3 reset_password

    $user->reset_password($new_password);

Sets a new password for the logged-in user. Returns C<1> on success,
C<undef> on failure or if not applicable (guest, visitor, or session no
longer valid).

=head3 logout

    $user->logout;

Deletes the user's session (and the concierge's user_key mapping for
it). Works for guests as well as logged-in users. Returns C<1> on
success, C<undef> on failure or if not applicable (visitor, no session).

On success, also cleans up this object in place: all backend closures
(C<_get_user_data>, C<_update_user_data>, C<_verify_password>,
C<_reset_password>, C<_logout>, C<_session_valid>) and the
C<session>/C<session_id>/C<user_data> fields are cleared, and status
flips so C<is_logged_in>
and C<is_guest> become false and C<is_visitor> becomes true. A C<$user>
reference held past C<logout> therefore degrades to visitor-equivalent
status rather than retaining stale session data or backend-write
capability -- every other method's existing "return C<undef> if not
applicable" guards then apply naturally, with no special-casing needed.
C<user_id> and C<user_key> are left untouched; they're inert identity
strings, not capabilities, and the concierge's own C<user_keys> mapping
entry for this session is already gone by this point regardless.

=head1 SEE ALSO

L<Concierge> -- creates User objects via lifecycle methods

L<Concierge::Sessions::Session> -- session object API

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
