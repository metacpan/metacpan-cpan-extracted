package Concierge v0.9.0;
use v5.36;

our $VERSION = 'v0.9.0';

# ABSTRACT: Service layer orchestrator for authentication, sessions, and user data

use Carp qw<carp croak>;
use JSON::PP qw< encode_json decode_json >;
use File::Spec;
use Params::Filter qw< make_filter >;

# === COMPONENT MODULES ===
use Concierge::Auth;
use Concierge::Sessions;
use Concierge::Users;
use Concierge::Desk::User;

# === PARAMETER FILTERS ===
# Shared filters for secure data segregation

# Auth filter - ONLY credentials (user_id + password)
our $auth_data_filter = make_filter(
    [qw(user_id password)],                   # required credentials
    [],                                        # accepted - nothing else
    [],                                        # excluded - not needed
);

# User data filter - everything EXCEPT credentials
# Handles both minimal input (user_id, moniker) and
# rich input (user_id, moniker, email, phone, bio, etc.)
our $user_data_filter = make_filter(
    [qw(user_id moniker)],                    # required minimum
    ['*'],                                    # accept ALL other fields, except:
    [qw(password confirm_password)],          # excluded - security boundary
);

# Session data filter - for populating session with initial data
# Accepts user_id (required for new_session) plus any session fields
# Excludes credentials (never stored in session data)
our $session_data_filter = make_filter(
    [qw(user_id)],                            # required for new_session
    ['*'],                                    # accept all other fields, except:
    [qw(password confirm_password)],          # excluded - security boundary
);

# User update filter - for updating existing user records
# No required fields (user_id passed separately as parameter)
# Excludes user_id (identity field), password (use reset_password instead)
our $user_update_filter = make_filter(
    [],                                       # no required fields
    ['*'],                                    # accept all fields, except:
    [qw(user_id password confirm_password)],  # excluded - never in updates
);

sub new_concierge {
    my ($class) = @_;
	bless {}, $class;
}

# =============================================================================
# DESK MANAGEMENT - Opening existing desks
# =============================================================================

sub open_desk ($class, $desk_location) {
	croak "Desk not found: *$desk_location*" unless -d $desk_location;
	my $concierge	= Concierge->new_concierge(); 	# minimal object
	$concierge->{desk_location} = $desk_location;

	# Instantiate the concierge from config stored in Concierge's config file
    my $concierge_conf_file	= File::Spec->catfile($desk_location, 'concierge.conf');

    # Read entire file (pretty JSON spans multiple lines)
    my ($fh,$json,$concierge_config);
    {
    	local $/;
    	open $fh, "<", $concierge_conf_file
    		and
    	$json = <$fh>
    		and
    	close $fh
    		or return { success => 0, message => "Error closing session file: $!" };
    }
    unless (defined $json) {
        return { success => 0, message => "Config file is empty" };
    }
    eval {
        $concierge_config = decode_json($json);
    };
    if ($@) {
        return { success => 0, message => "Invalid JSON in config file: $@" };
    }

	# Instantiate sessions manager from $concierge_config
	$concierge->{sessions}	= Concierge::Sessions->new(
		storage_dir => $concierge_config->{sessions_dir} || $concierge_config->{storage_dir},
		backend		=> $concierge_config->{sessions_backend} || '',
	);

	# Load user_keys mapping from file (or initialize empty for new desk)
	my $user_keys_file = File::Spec->catfile($desk_location, 'user_keys.json');
	if (-e $user_keys_file) {
		local $/;
		my $user_keys_fh;
		open $user_keys_fh, "<", $user_keys_file
			or return { success => 0, message => "Cannot read user_keys file: $!" };
		my $user_keys_json = <$user_keys_fh>;
		close $user_keys_fh;
		$concierge->{user_keys} = decode_json($user_keys_json);
	} else {
		$concierge->{user_keys} = {};  # New desk or first run
	}

	# Cleanup expired sessions and synchronize user_keys mapping
	my $cleanup_result = $concierge->{sessions}->cleanup_sessions();
	# Returns: { success => 1, deleted_count => N, active => [session_ids...] }

	if ($cleanup_result->{success} && $cleanup_result->{active}) {
		# Create lookup hash of active session_ids
		my %active_sessions = map { $_ => 1 } @{$cleanup_result->{active}};

		# Remove user_keys entries for deleted sessions
		my $cleaned = 0;
		for my $key (keys %{$concierge->{user_keys}}) {
			my $session_id = $concierge->{user_keys}{$key}{session_id};
			unless ($active_sessions{$session_id}) {
				delete $concierge->{user_keys}{$key};
				$cleaned++;
			}
		}

		# Save cleaned mapping if any were removed
		if ($cleaned > 0) {
			$concierge->save_user_keys();
		}
	}
	
	# Instantiate users and auth from $concierge_config
	$concierge->{users}	= Concierge::Users->new( $concierge_config->{users_config_file} );

	unless ($concierge_config->{auth_backend}) {
		return { success => 0, message =>
			"This desk must be built again to work with v0.5+ of Concierge::Auth, "
			. "now shipping with Concierge v0.9+. Building the desk with the same "
			. "original configuration will archive existing user data, but delete "
			. "session and any credential storage, and will automatically install "
			. "the default built-in ID-password authentication system. See the "
			. "POD for how to use an alternative approach to user authentication."
		};
	}

	my $auth;
	eval {
		$auth = Concierge::Auth->new(
			backend	=> $concierge_config->{auth_backend},
			%{ $concierge_config->{auth_args} || {} },
		);
	};
	return { success => 0, message => "Failed to initialize auth backend: $@" } if $@;
	$concierge->{auth} = $auth;

	return { success => 1, message => 'Welcome!', concierge => $concierge };
}

sub sessions {
	$_[0]->{sessions};
}
sub users {
	$_[0]->{users};
}
sub auth {
	$_[0]->{auth};
}

# =============================================================================
# CONCIERGE STATE MANAGEMENT
# =============================================================================

# Save user_keys mapping to persistent storage
sub save_user_keys ($self) {
    my $user_keys_file = File::Spec->catfile($self->{desk_location}, 'user_keys.json');

#    my $json = encode_json($self->{user_keys});
	my $json = JSON::PP->new->utf8->pretty->encode( $self->{user_keys} );
    open my $fh, ">", $user_keys_file
        or return { success => 0, message => "Cannot write user_keys file: $!" };
    print $fh $json;
    close $fh
        or return { success => 0, message => "Error closing user_keys file: $!" };

    return { success => 1 };
}


# =============================================================================
# USER MANAGEMENT AND AUTHENTICATION
# =============================================================================

# Add user: register in Users, set password in Auth
sub add_user ($self, $user_input) {
    # Single input hashref handles both minimal and rich input:
    # Minimal: { user_id => '...', moniker => '...', password => '...' }
    # Rich:    { user_id => '...', moniker => '...', email => '...',
    #            phone => '...', bio => '...', password => '...' }

    return { success => 0, message => 'user_input must be a hash reference' }
        unless ref $user_input eq 'HASH';

    # Filter for Users - gets everything EXCEPT password
    my $user_data = $user_data_filter->($user_input);
    return { success => 0, message => 'Missing required fields: user_id and moniker' }
        unless $user_data;

    # Filter for Auth - gets ONLY user_id and password
    my $auth_data = $auth_data_filter->($user_input);
    return { success => 0, message => 'Missing required field: password' }
        unless $auth_data;

    my $user_id = $auth_data->{user_id};

    # Step 1: Register user in Users component (password automatically excluded)
    my $register_result = $self->users->register_user($user_data);
    unless ($register_result->{success}) {
        return { success => 0, message => $register_result->{message} };
    }

    # Step 2: Set password in Auth component
    my $enroll = $self->auth->enroll($user_id, $auth_data->{password});
    my ($pwd_ok, $pwd_msg) = ($enroll->{success}, $enroll->{message});
    unless ($pwd_ok) {
        # Rollback: delete the user record since password failed
        $self->users->delete_user($user_id);
        return { success => 0, message => $pwd_msg || 'Failed to set password' };
    }

    return {
        success => 1,
        message => "User '$user_id' added successfully",
        user_id => $user_id,
    };
}

# Remove user: delete from all components (Auth, Users, Sessions, concierge mapping)
sub remove_user ($self, $user_id) {
    # Removes user from all Concierge components
    # Attempts all deletions with graceful handling
    # Application should handle higher-level cleanup (files, assets) before calling this

    return { success => 0, message => 'user_id is required' }
        unless defined $user_id && length($user_id);

    my @deleted_from;
    my @warnings;

    # Step 1: Delete from Users component
    my $users_result = $self->users->delete_user($user_id);
    if ($users_result->{success}) {
        push @deleted_from, 'Users';
    } else {
        push @warnings, "Users: $users_result->{message}";
    }

    # Step 2: Delete from Auth component
    my $revoked = $self->auth->revoke($user_id);
    my ($auth_ok, $auth_msg) = ($revoked->{success}, $revoked->{message});
    if ($auth_ok) {
        push @deleted_from, 'Auth';
    } else {
        push @warnings, "Auth: " . ($auth_msg || 'deletion failed');
    }

    # Step 3: Find and delete session (if user has active session)
    my $session_id;
    my $user_key_to_delete;

    # Search user_keys mapping for this user_id
    for my $key (keys %{$self->{user_keys}}) {
        if ($self->{user_keys}{$key}{user_id} eq $user_id) {
            $session_id = $self->{user_keys}{$key}{session_id};
            $user_key_to_delete = $key;
            last;
        }
    }

    # Delete session if found
    if ($session_id) {
        my $session_result = $self->sessions->delete_session($session_id);
        if ($session_result->{success}) {
            push @deleted_from, 'Sessions';
        } else {
            push @warnings, "Sessions: $session_result->{message}";
        }
    }

    # Step 4: Remove from concierge user_keys mapping
    if ($user_key_to_delete) {
        delete $self->{user_keys}{$user_key_to_delete};
        my $save_result = $self->save_user_keys();
        if ($save_result->{success}) {
            push @deleted_from, 'concierge mapping';
        } else {
            push @warnings, "Concierge mapping: failed to save";
        }
    }

    # Build response
    my $message = scalar(@deleted_from)
        ? "User '$user_id' removed from: " . join(', ', @deleted_from)
        : "User '$user_id' not found in any component";

    return {
        success => 1,
        message => $message,
        user_id => $user_id,
        deleted_from => \@deleted_from,
        (@warnings ? (warnings => \@warnings) : ()),
    };
}

# Verify user: check if user exists in both Auth and Users components
sub verify_user ($self, $user_id) {
    # Verifies user exists and checks for data consistency
    # User is considered verified only if present in BOTH components

    return { success => 0, message => 'user_id is required' }
        unless defined $user_id && length($user_id);

    # Check Auth component (password file)
    my $auth_exists = $self->auth->is_id_known($user_id)->{known};

    # Check Users component (user data store)
    my $user_result = $self->users->get_user($user_id);
    my $users_exists = $user_result->{success};

    # User is verified if in BOTH components
    my $verified = $auth_exists && $users_exists;

    my $response = {
        success => 1,
        verified => $verified,
        exists_in_auth => $auth_exists,
        exists_in_users => $users_exists,
    };

    # Add user_status if available
    if ($users_exists && exists $user_result->{user}{user_status}) {
        $response->{user_status} = $user_result->{user}{user_status};
    }

    # Warn if inconsistent (exists in one but not both)
    if ($auth_exists != $users_exists) {
        $response->{warning} = 'User exists in only one component - data inconsistency detected';
    }

    return $response;
}

# Update user data: modify user record in Users component
sub update_user_data ($self, $user_id, $update_data) {
    return { success => 0, message => 'user_id is required' }
        unless defined $user_id && length($user_id);

    return { success => 0, message => 'update_data must be a hash reference' }
        unless ref $update_data eq 'HASH';

    # Filter update data (excludes user_id, password, confirm_password)
    my $filtered_updates = $user_update_filter->($update_data);
    return { success => 0, message => 'No valid fields to update' }
        unless $filtered_updates && keys %$filtered_updates;

    # Update user in Users component
    my $update_result = $self->users->update_user($user_id, $filtered_updates);
    unless ($update_result->{success}) {
        return { success => 0, message => $update_result->{message} };
    }

    return {
        success => 1,
        message => "User '$user_id' updated successfully",
        user_id => $user_id,
    };
}

# Get user data: retrieve user profile from Users component
sub get_user_data ($self, $user_id, @fields) {
    # Retrieves user profile data fields
    # If @fields specified, returns only those fields
    # Otherwise returns all user data

    return { success => 0, message => 'user_id is required' }
        unless defined $user_id && length($user_id);

    # Get user from Users component
    my $user_result = $self->users->get_user($user_id);
    return { success => 0, message => $user_result->{message} || 'User not found' }
        unless $user_result->{success};

    my $user_data = $user_result->{user};

    # If specific fields requested, return only those that exist
    if (@fields) {
        my %selected;
        for my $field (@fields) {
            $selected{$field} = $user_data->{$field} if exists $user_data->{$field};
        }
        return { success => 1, user => \%selected };
    }

    # Otherwise return all data
    return { success => 1, user => $user_data };
}

# List users: retrieve list of user_ids, optionally with full data
sub list_users ($self, $filter='', $options={}) {
    # Returns user_ids by default
    # With include_data => 1: fetches full user records
    # With fields => [...]: returns only specified fields per user

    # Get user_ids from Users component
    my $list_result = $self->users->list_users($filter);
    return { success => 0, message => $list_result->{message} || 'Failed to list users' }
        unless $list_result->{success};

    my $user_ids = $list_result->{user_ids} // [];

    # If only IDs requested, return them with count
    unless ($options->{include_data}) {
        return {
            success => 1,
            user_ids => $user_ids,
            count => scalar(@$user_ids),
        };
    }

    # Fetch full data for each user
    my %users;  # Hash indexed by user_id for easy lookup
    my @fields = $options->{fields} ? $options->{fields}->@* : ();

    for my $user_id (@$user_ids) {
        my $data = $self->get_user_data($user_id, @fields);
        $users{$user_id} = $data->{user} if $data->{success};
    }

    return {
        success => 1,
        user_ids => $user_ids,  # Preserve order
        users => \%users,       # Hash for easy lookup
        count => scalar(keys %users),
    };
}

# Build closures that give a User object backend access to its data store
# Called by any Concierge method that creates a logged-in User object
sub _make_user_closures ($self, $user_id) {
    my $get_user_data = sub (@fields) {
        my $result = $self->users->get_user($user_id);
        return $result unless $result->{success};

        if (@fields) {
            my %selected = map { $_ => $result->{user}{$_} }
                           grep { exists $result->{user}{$_} }
                           @fields;
            return { success => 1, user => \%selected };
        }
        return $result;
    };

    my $update_user_data = sub ($updates) {
        return $self->users->update_user($user_id, $updates);
    };

    return ($get_user_data, $update_user_data);
}

# Admit visitor: assign user_key only (no session, no user data)
sub admit_visitor ($self) {
	my $visitor_id = $self->auth->gen_random_string(13)
		or return { success => 0, message => "Couldn't generate visitor ID" };

	# Create user object for visitor (no session, no user_data, no backend access)
	my $user = Concierge::Desk::User->enable_user($visitor_id, {
		user_key => $visitor_id,  # Use visitor_id as user_key
	});

	return {
		success    => 1,
		user       => $user,
		is_visitor => 1,
	};
}

# Checkin guest: assign a session with no user data backend or authentication
sub checkin_guest ($self, $session_opts={}) {
	my $guest_id = $self->auth->gen_random_string(13)
		or return { success => 0, message => "Couldn't generate guest ID" };

	# Shorter timeout for anonymous
	my $timeout = $session_opts->{timeout}
		// $self->{config}{anonymous_timeout}
        // 1800;  # 30 minutes default

	# Create session using Sessions manager
	my $result = $self->sessions->new_session(
		user_id => $guest_id,
		session_timeout => $timeout,
	);
	return { success => 0, message => $result->{message} }
		unless $result->{success};

	my $session = $result->{session};
	my $session_id = $session->session_id();

	# Create user object for guest (no user_data, no backend closures)
	my $user = Concierge::Desk::User->enable_user($guest_id, {
		session  => $session,
		user_key => $guest_id,  # Use guest_id as user_key for simplicity
	});

	# Store user_key mapping
	$self->{user_keys}{$user->user_key()} = {
		user_id    => $guest_id,
		session_id => $session_id,
	};
	$self->save_user_keys();

	return {
		success  => 1,
		user     => $user,
		is_guest => 1,
	};
}

sub login_guest($self, $user_input, $guest_user_key) {
    # Convert guest to logged-in user, transferring session data (shopping cart, etc.)
    # $user_input: hashref with user_id, moniker, password (and optional email, etc.)
    # This creates a new user account and transfers the guest's session data to it.

    # Step 1: Lookup guest's session_id from user_key mapping
    my $guest_mapping = $self->{user_keys}{$guest_user_key};
    return { success => 0, message => 'Guest user_key not found' }
        unless $guest_mapping;

    my $guest_session_id = $guest_mapping->{session_id};

    # Step 2: Get guest session and extract its data
    my $session_result = $self->sessions->get_session($guest_session_id);
    return { success => 0, message => 'Guest session not found' }
        unless $session_result->{success};

    my $guest_session = $session_result->{session};
    my $guest_data_result = $guest_session->get_data();
    my $guest_data = $guest_data_result->{value} || {};

    # Step 3: Create the new user account (Auth + Users)
    my $add_result = $self->add_user($user_input);
    return $add_result unless $add_result->{success};

    # Step 4: Log in the newly created user (authenticate, create session, get User object)
    my $auth_data = $auth_data_filter->($user_input);
    my $login_result = $self->login_user({
        user_id  => $auth_data->{user_id},
        password => $auth_data->{password},
    });
    return $login_result unless $login_result->{success};

    my $user = $login_result->{user};

    # Step 5: Transfer guest session data to new user's session
    if (%$guest_data) {
        my $new_session = $user->session();
        if ($new_session) {
            $new_session->set_data($guest_data);
            $new_session->save();
        }
    }

    # Step 6: Delete guest session
    $self->sessions->delete_session($guest_session_id);

    # Step 7: Remove guest user_key mapping
    delete $self->{user_keys}{$guest_user_key};
    $self->save_user_keys();

    return {
        success => 1,
        message => 'Guest converted to logged-in user',
        user    => $user,
    };
}

# Restore user: reconstruct User object from a user_key (e.g., from a cookie)
sub restore_user ($self, $user_key) {
    return { success => 0, message => 'user_key is required' }
        unless defined $user_key && length($user_key);

    # Step 1: Lookup user_key in mapping
    my $mapping = $self->{user_keys}{$user_key};
    return { success => 0, message => 'user_key not found' }
        unless $mapping;

    my $user_id    = $mapping->{user_id};
    my $session_id = $mapping->{session_id};

    # Step 2: Retrieve session (validates it still exists and hasn't expired)
    my $session_result = $self->sessions->get_session($session_id);
    unless ($session_result->{success}) {
        # Session gone or expired -- clean up stale mapping
        delete $self->{user_keys}{$user_key};
        $self->save_user_keys();
        return { success => 0, message => 'Session expired' };
    }

    my $session = $session_result->{session};

    # Step 3: Determine user type -- logged-in or guest
    my $user_result = $self->users->get_user($user_id);

    if ($user_result->{success}) {
        # Logged-in user: rebuild with user data and backend closures
        my ($get, $update) = $self->_make_user_closures($user_id);
        my $user = Concierge::Desk::User->enable_user($user_id, {
            session           => $session,
            user_data         => $user_result->{user},
            user_key          => $user_key,
            _get_user_data    => $get,
            _update_user_data => $update,
        });

        return {
            success => 1,
            message => 'User restored',
            user    => $user,
        };
    }
    else {
        # Guest: session only, no user data
        my $user = Concierge::Desk::User->enable_user($user_id, {
            session  => $session,
            user_key => $user_key,
        });

        return {
            success  => 1,
            message  => 'Guest restored',
            user     => $user,
            is_guest => 1,
        };
    }
}

# Login user: authenticate, create session, assign user_key and store external_key mapping
sub login_user ($self, $credentials, $session_opts={}) {
    # Step 0: Get credentials
    my $auth_data = $auth_data_filter->($credentials);
    return { success => 0, message => 'Missing user_id or password' }
        unless $auth_data;

    my $user_id = $auth_data->{user_id};
    my $password = $auth_data->{password};

    # Step 1: Get user from database
    my $user_result = $self->users->get_user($user_id);
    return { success => 0, message => 'User not found' }
        unless $user_result->{success};

    # Step 2: Authenticate with ID & password
    my $authed = $self->auth->authenticate($user_id, $password);
    my ($auth_ok, $auth_msg) = ($authed->{success}, $authed->{message});
    return { success => 0, message => $auth_msg || 'Authentication failed' }
        unless $auth_ok;

    # Step 3: Create session
    my $session_result = $self->sessions->new_session(
        user_id         => $user_id,
        %{ $session_opts || {} },
    );
    return { success => 0, message => $session_result->{message} || 'Failed to create session' }
        unless $session_result->{success};

    my $session = $session_result->{session};
    my $session_id = $session->session_id();

    # Create user object for logged-in user
    my ($get, $update) = $self->_make_user_closures($user_id);
    my $user = Concierge::Desk::User->enable_user($user_id, {
        session           => $session,
        user_data         => $user_result->{user},
        _get_user_data    => $get,
        _update_user_data => $update,
    });

    # Store user_key mapping
    $self->{user_keys}{$user->user_key()} = {
        user_id    => $user_id,
        session_id => $session_id,
    };
    $self->save_user_keys();

    return {
        success => 1,
        message => 'Login successful',
        user    => $user,
    };
}

# Verify password: check if password is correct for user
sub verify_password ($self, $user_id, $password) {
    # Verifies if provided password is correct for the user
    # Usually not needed - if user has valid session/user_key, they're already authenticated
    # Use cases: sensitive operations requiring re-authentication, admin verification, etc.
    # Most password resets don't need this - session authentication is sufficient

    # Minimal validation - application controls when this is called
    return { success => 0, message => 'user_id is required' }
        unless defined $user_id && length($user_id);

    return { success => 0, message => 'password is required' }
        unless defined $password && length($password);

    # Check password via Auth component
    my $authed = $self->auth->authenticate($user_id, $password);
    my ($pwd_ok, $pwd_msg) = ($authed->{success}, $authed->{message});

    return {
        success => $pwd_ok ? 1 : 0,
        message => $pwd_msg || ($pwd_ok ? 'Password verified' : 'Invalid password'),
        user_id => $user_id,
    };
}

# Reset password: set user's new password
sub reset_password ($self, $user_id, $new_password) {
    # Changes user password using Auth component
    # Application is responsible for verifying user identity and old password if needed

    return { success => 0, message => 'user_id is required' }
        unless defined $user_id && length($user_id);

    return { success => 0, message => 'new_password is required' }
        unless defined $new_password && length($new_password);

    # Reset existing password using Auth's change_credentials
    # Pass through Auth's messages (Auth provides detailed error messages)
    my $changed = $self->auth->change_credentials($user_id, $new_password);
    my ($reset_ok, $reset_msg) = ($changed->{success}, $changed->{message});

    return {
        success => $reset_ok ? 1 : 0,
        message => $reset_msg || ($reset_ok ? 'Password reset successful' : 'Password reset failed'),
        user_id => $user_id,
    };
}

# Logout user: delete session and remove from concierge mapping
sub logout_user ($self, $session_id) {
    # Logs out user by deleting their session
    # Removes from concierge user_keys mapping

    return { success => 0, message => 'No session provided for logout' }
        unless defined $session_id && length($session_id);

    # Step 1: Verify session exists
    my $session_check = $self->sessions->get_session($session_id);
    unless ($session_check->{success}) {
        return { success => 0, message => 'Session not found for logout' };
    }

    # Step 2: Find user_key for this session (to remove from mapping)
    my $user_key_to_delete;
    my $user_id;

    for my $key (keys %{$self->{user_keys}}) {
        if ($self->{user_keys}{$key}{session_id} eq $session_id) {
            $user_key_to_delete = $key;
            $user_id = $self->{user_keys}{$key}{user_id};
            last;
        }
    }

    # Step 3: Delete session from Sessions component
    my $delete_result = $self->sessions->delete_session($session_id);
    unless ($delete_result->{success}) {
        return { success => 0, message => $delete_result->{message} || 'Failed to delete session' };
    }

    # Step 4: Remove from concierge user_keys mapping
    if ($user_key_to_delete) {
        delete $self->{user_keys}{$user_key_to_delete};
        my $save_result = $self->save_user_keys();
        unless ($save_result->{success}) {
            return { success => 0, message => 'Session deleted but failed to update mapping' };
        }
    }

    return {
        success => 1,
        message => 'Logout successful',
        session_id => $session_id,
        ($user_id ? (user_id => $user_id) : ()),
    };
}


1;

__END__

=head1 NAME

Concierge - Service layer orchestrator for authentication, sessions, and user data

=head1 VERSION

v0.9.0

=head1 SYNOPSIS

    use Concierge;

    # Open an existing desk (created by Concierge::Desk::Setup)
    my $desk = Concierge->open_desk('./desk');
    my $concierge = $desk->{concierge};

    # Register a user
    $concierge->add_user({
        user_id  => 'alice',
        moniker  => 'Alice',
        email    => 'alice@example.com',
        password => 'secret123',
    });

    # Log in -- returns a Concierge::Desk::User object
    my $login = $concierge->login_user({
        user_id  => 'alice',
        password => 'secret123',
    });
    my $user = $login->{user};

    # User object provides direct access
    say $user->moniker;         # "Alice"
    say $user->session_id;      # random hex string
    say $user->is_logged_in;    # 1

    # Restore user from a cookie on next request
    my $restore = $concierge->restore_user($user->user_key);
    my $same_user = $restore->{user};

    # Log out
    $concierge->logout_user($user->session_id);

=head1 DESCRIPTION

Concierge coordinates three component modules behind a single API:

=over 4

=item * B<Concierge::Auth> -- password authentication (Argon2)

=item * B<Concierge::Sessions> -- session management (SQLite or file backends)

=item * B<Concierge::Users> -- user data storage (SQLite, YAML, or CSV/TSV backends)

=back

Applications interact only with Concierge and the L<Concierge::Desk::User> objects
it returns. The component modules are never exposed directly.

=head2 What the Suite Provides

Concierge handles orchestration -- coordinating components, managing the
user_key mapping, and returning consistent structured results. The
capabilities of the suite live in the three components:

B<Authentication> (L<Concierge::Auth>): Argon2id password hashing and
verification; no plaintext credentials are ever written to disk. Also
provides random token, UUID, word-passphrase, and hex-ID generators. The
component is substitutable: any replacement implementing the same method
contract (C<authenticate>, C<enroll>, C<change_credentials>, etc. -- see
L<Concierge::Auth::Base>) can replace it for LDAP, OAuth, or any other
scheme.

B<Sessions> (L<Concierge::Sessions>): Full session lifecycle -- creation,
retrieval, expiry, and cleanup -- with SQLite, file, or in-memory backends.
Sessions carry arbitrary key/value data. A single-session-per-user policy
is enforced: creating a new session automatically removes any prior session
for that user. Expired sessions are cleaned up each time a desk is opened.

B<User Records> (L<Concierge::Users>): User data store with a configurable
field schema. Standard fields (C<moniker>, C<email>, C<phone>,
C<access_level>, C<user_status>, C<term_ends>, and others) are built in and
can be selectively overridden. Applications add their own fields via
C<app_fields> at setup time. Supports SQLite, YAML, and CSV/TSV backends,
with filtering and listing operations.

For the full API of any component, see its own documentation.

=head2 Desks

A I<desk> is a storage directory containing the configuration and data files
for all three components. Use L<Concierge::Desk::Setup> to create a desk, then
C<open_desk()> to load it at runtime.

=head2 User Participation Levels

Concierge provides three graduated levels of user participation, each
returning a L<Concierge::Desk::User> object:

=over 4

=item B<Visitor> -- C<admit_visitor()>

Assigned a unique identifier only. No session, no stored data. Suitable for
anonymous tracking (e.g., cookies).

=item B<Guest> -- C<checkin_guest()>

Assigned an identifier and a session. Can store temporary data (e.g., a
shopping cart). No authentication or persistent user record.

=item B<Logged-in user> -- C<login_user()>

Authenticated with credentials. Has a session, persistent user data, and
full access to the User object's data methods.

=back

A guest can be converted to a logged-in user with C<login_guest()>,
transferring any session data accumulated during the guest session.

=head2 User Keys

Each active user (guest or logged-in) is tracked by a I<user_key> -- a
random token stored in the concierge's C<user_keys> mapping alongside the
user's C<user_id> and C<session_id>. This mapping is persisted to
C<user_keys.json> in the desk directory and synchronized against active
sessions when the desk is opened.

=head2 Return Values

All methods return a hashref with at least C<success> (0 or 1) and
C<message>:

    # Success
    { success => 1, message => '...', ... }

    # Failure
    { success => 0, message => 'error description' }

Success responses include additional fields relevant to the operation:

=over 4

=item *

User lifecycle methods (C<login_user()>, C<restore_user()>, C<checkin_guest()>,
C<admit_visitor()>, C<login_guest()>) return C<user>, a L<Concierge::Desk::User>
object. Guest and visitor results also set C<is_guest> or C<is_visitor> to 1.

=item *

C<open_desk()> returns C<concierge>, the ready-to-use Concierge object.

=item *

User management methods return C<user_id>. C<remove_user()> also returns
C<deleted_from> (arrayref of component names) and, if any deletion failed,
C<warnings> (arrayref).

=item *

C<verify_user()> returns C<verified> (0 or 1), C<exists_in_auth>, and
C<exists_in_users>.

=item *

C<list_users()> returns C<user_ids> (arrayref) and C<count>. With
C<< include_data => 1 >>, also returns C<users> (hashref keyed by user_id).

=back

See the individual method descriptions below for the complete field list.

Methods never C<croak> during normal operation. The one exception is
C<open_desk()>, which croaks if the desk directory does not exist.

=head2 Architecture

Concierge ships with three I<identity core> components:

=over 4

=item L<Concierge::Auth> -- credential storage and verification

=item L<Concierge::Sessions> -- session lifecycle and persistence

=item L<Concierge::Users> -- user records with configurable field schemas

=back

These three are tightly orchestrated: a single C<login_user()> call
authenticates via Auth, retrieves a record from Users, and creates a
session through Sessions.  This coordination is the purpose of
Concierge -- applications interact with the Concierge API and the
L<Concierge::Desk::User> objects it returns, not with the components
directly.

The identity core is designed to be sufficient on its own, but the
component pattern it follows -- backend abstraction, setup-time
configuration, and Concierge-level orchestration -- is intentionally
replicable.  Each identity core component can also be substituted with
a conforming replacement, and additional components (Organizations,
Assets, etc.) can be added by following the same conventions.  See
L</EXTENSIBILITY> for details.

=head1 METHODS

=head2 Desk Management

=head3 open_desk

    my $result = Concierge->open_desk($desk_location);
    my $concierge = $result->{concierge};

Opens an existing desk directory created by L<Concierge::Desk::Setup>. Reads
the configuration file, instantiates all component modules, loads the
user_keys mapping, and runs session cleanup.

Croaks if C<$desk_location> is not an existing directory.

Returns C<< { success => 1, concierge => $obj } >> on success.

=head2 User Lifecycle

=head3 admit_visitor

    my $result = $concierge->admit_visitor();
    my $user = $result->{user};    # Concierge::Desk::User (visitor)

Creates a visitor with a generated identifier. No session is created
and no data is stored.

=head3 checkin_guest

    my $result = $concierge->checkin_guest(\%session_opts);
    my $user = $result->{user};    # Concierge::Desk::User (guest)

Creates a guest with a generated identifier and a session. The optional
C<%session_opts> hashref may include C<timeout> (in seconds; defaults to
1800).

=head3 login_user

    my $result = $concierge->login_user(\%credentials, \%session_opts);
    my $user = $result->{user};    # Concierge::Desk::User (logged-in)

Authenticates C<user_id> and C<password> from C<%credentials>, retrieves
the user's data record, creates a session, and returns a fully-equipped
User object. If the user already has an active session, the previous
session is replaced.

=head3 restore_user

    my $result = $concierge->restore_user($user_key);
    my $user = $result->{user};    # Concierge::Desk::User (guest or logged-in)

Reconstructs a User object from a C<user_key> (typically stored in a cookie
or URL token). Looks up the key in the concierge mapping, validates the
session, and determines whether the user is a guest or logged-in user.

Logged-in users are restored with their full user data snapshot and backend
closures. Guests are restored with their session only.

If the session has expired, the stale mapping entry is cleaned up and the
method returns failure. The application can then redirect to login or create
a new guest as appropriate.

Returns C<< { success => 1, user => $user } >> on success. Guest restores
also include C<< is_guest => 1 >>.

=head3 login_guest

    my $result = $concierge->login_guest(\%credentials, $guest_user_key);
    my $user = $result->{user};    # Concierge::Desk::User (logged-in)

Converts a guest to a logged-in user. Authenticates with C<%credentials>,
transfers any data from the guest's session to the new session, then
deletes the guest session and removes the guest's user_key mapping.

=head3 logout_user

    my $result = $concierge->logout_user($session_id);

Deletes the session and removes the user_key mapping entry.

=head2 Admin Operations

=head3 add_user

    my $result = $concierge->add_user(\%user_input);

Registers a new user. C<%user_input> must include C<user_id>, C<moniker>,
and C<password>. Any additional fields (C<email>, C<phone>, application-
defined fields, etc.) are stored in the Users component. The password is
stored separately in the Auth component and never reaches the user data
store.

If password validation fails, the Users record is rolled back.

=head3 remove_user

    my $result = $concierge->remove_user($user_id);

Removes the user from all components: Users, Auth, Sessions, and the
user_keys mapping. Attempts all deletions; the response includes
C<deleted_from> (arrayref) and C<warnings> (arrayref, if any component
deletion failed).

=head3 verify_user

    my $result = $concierge->verify_user($user_id);

Checks whether C<$user_id> exists in both Auth and Users components.
Returns C<< verified => 1 >> only if present in both. Includes
C<exists_in_auth> and C<exists_in_users> flags, and a C<warning> if
the user exists in one component but not the other.

=head3 list_users

    # IDs only
    my $result = $concierge->list_users($filter, \%options);
    my @ids = @{ $result->{user_ids} };

    # With full data
    my $result = $concierge->list_users('', { include_data => 1 });
    my %users = %{ $result->{users} };

Returns user IDs from the Users component. C<$filter> is a string passed
through to L<Concierge::Users>. With C<< include_data => 1 >>, fetches
each user's full record into a C<users> hash keyed by user_id. With
C<< fields => [...] >>, returns only the specified fields per user.

=head3 get_user_data

    my $result = $concierge->get_user_data($user_id, @fields);
    my $data = $result->{user};

Retrieves user data from the Users component. If C<@fields> is provided,
returns only those fields; otherwise returns all fields.

=head3 update_user_data

    my $result = $concierge->update_user_data($user_id, \%updates);

Updates the user's record in the Users component. The C<user_id> and
C<password> fields are filtered out and cannot be changed through this
method.

=head2 Password Operations

Initial password registration is handled by C<add_user()>, which sets the
password atomically with user creation. The methods here operate on passwords
for existing users.

=head3 verify_password

    my $result = $concierge->verify_password($user_id, $password);

Checks whether C<$password> is correct for C<$user_id>. Returns
C<< success => 1 >> if the password matches.

=head3 reset_password

    my $result = $concierge->reset_password($user_id, $new_password);

Sets a new password for an existing user. The application is responsible
for verifying the user's identity before calling this method.

=head1 PARAMETER FILTERS

Concierge uses L<Params::Filter> to enforce data segregation at method
boundaries:

=over 4

=item C<$auth_data_filter> -- extracts only C<user_id> and C<password>

=item C<$user_data_filter> -- extracts everything except C<password>

=item C<$session_data_filter> -- extracts C<user_id> plus non-credential fields

=item C<$user_update_filter> -- excludes C<user_id> and C<password> from updates

=back

These ensure that credentials never leak into user data stores and that
identity fields cannot be changed via update operations.

=head1 EXTENSIBILITY

=head2 Component Substitution

Each identity core component can be replaced with a drop-in alternative as
long as the replacement implements the methods Concierge calls on it.

B<Auth> -- Concierge calls:

    $auth->authenticate($user_id, $credential)
    $auth->is_id_known($user_id)
    $auth->enroll($user_id, $credential, \%opts?)
    $auth->change_credentials($user_id, $new_credential)
    $auth->revoke($user_id)

A substitute backend must implement this contract -- see
L<Concierge::Auth::Base> -- and must also provide the
L<Concierge::Auth::Generators> methods (used for visitor/guest
identifiers, independent of authentication). Register it in
C<Concierge::Desk::Setup>'s backend catalog so C<< auth => {
backend => 'mybackend', ... } >> resolves to it at desk-build time,
or bypass config entirely by constructing
C<< Concierge::Auth->new(backend => 'My::Fully::Qualified::Class', ...) >>
directly and assigning it to C<< $concierge->{auth} >> after
C<open_desk>.

B<Sessions> -- Concierge calls:

=over 4

=item C<< Concierge::Sessions->new(%args) >> -- constructor; accepts C<storage_dir> and C<backend>

=item C<< $sessions->new_session(%args) >> -- returns C<< { success => 1, session => $obj } >>

=item C<< $sessions->get_session($session_id) >> -- returns C<< { success => 1, session => $obj } >>

=item C<< $sessions->delete_session($session_id) >> -- returns C<< { success => 1|0, ... } >>

=item C<< $sessions->cleanup_sessions() >> -- returns C<< { success => 1, deleted_count => N, active => [...] } >>

=back

B<Users> -- Concierge calls:

=over 4

=item C<< Concierge::Users->new($config_file) >> -- constructor

=item C<< $users->register_user(\%data) >> -- returns C<< { success => 1|0, message => '...' } >>

=item C<< $users->get_user($user_id) >> -- returns C<< { success => 1, user => \%data } >>

=item C<< $users->update_user($user_id, \%updates) >> -- returns C<< { success => 1|0, ... } >>

=item C<< $users->delete_user($user_id) >> -- returns C<< { success => 1|0, ... } >>

=item C<< $users->list_users($filter) >> -- returns C<< { success => 1, user_ids => [...] } >>

=back

To substitute a component, supply an object that responds to these methods and
assign it to the corresponding slot on the concierge object after C<open_desk()>:

    my $result = Concierge->open_desk($desk_dir);
    my $c = $result->{concierge};
    $c->{auth} = My::LDAPAuth->new(...);   # drop-in replacement

=head2 Additional Components

To add a new records-store component (Organizations, Assets, Catalog, etc.):

=over 4

=item 1.

Subclass L<Concierge::Desk::Base> and implement its seven stub methods.
C<Concierge::Desk::Base> documents the method signatures and the
C<{ success => 1|0, message => '...' }> return convention.

=item 2.

Add a configuration block for your component in C<concierge.conf>:

    { "organizations_config": { "backend": "sqlite", "db_file": "..." } }

=item 3.

After C<open_desk()>, instantiate and attach the component:

    my $result = Concierge->open_desk($desk_dir);
    my $c = $result->{concierge};
    my $orgs = Concierge::Organizations->new();
    $orgs->setup($desk_config->{organizations_config});
    $c->{organizations} = $orgs;

=item 4.

Access the component through the concierge object:

    my $r = $c->{organizations}->add_record('acme', \%data);

=back

=head2 Future Components

The following illustrate the kinds of components the C<Concierge::> namespace
is suited for.  These are not roadmap commitments -- they are examples of what
the component pattern enables:

=over 4

=item * C<Concierge::Organizations> -- multi-tenancy; users belong to orgs

=item * C<Concierge::Assets> -- files, images, or other owned resources

=item * C<Concierge::Guides> -- role and permission records

=item * C<Concierge::Catalog> -- product or content records

=item * C<Concierge::Calendar> -- event and booking records

=back

=head2 Contributing

If you build a component that might be useful to others, contributions to the
C<Concierge::> namespace on CPAN are welcome.  The conventions to follow are:
subclass L<Concierge::Desk::Base>, use the C<{ success => 1|0, message => '...' }>
return convention, accept a desk config block via C<setup()>, and include
comprehensive tests and POD.  Open an issue or pull request at
L<https://github.com/bwva/Concierge> to discuss before publishing.

=head1 SEE ALSO

L<Concierge::Desk::Setup> -- desk creation and configuration

L<Concierge::Desk::User> -- user objects returned by lifecycle methods

L<Concierge::Desk::Base> -- records-store base class for additional components

L<Concierge::Auth>, L<Concierge::Sessions>, L<Concierge::Users> -- component modules

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
