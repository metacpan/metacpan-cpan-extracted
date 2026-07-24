package Concierge::Users v0.9.4;
use v5.36;

use Carp		qw/ croak carp /;
use JSON::PP    qw/ encode_json decode_json /;
use File::Path  qw/ make_path /;

use parent		qw/ Concierge::Users::Meta /;

# ==============================================================================
# Setup Method - One-time configuration
# ==============================================================================

sub setup {
    my ($class, $config) = @_;

    croak "Configuration must be a hash reference"
        unless ref $config eq 'HASH';

    # storage_dir is required - validate/create it FIRST before backend operations
    my $storage_dir = $config->{storage_dir}
    	or croak "Configuration must include 'storage_dir' parameter";
    unless (-d $storage_dir) {
        eval { make_path($storage_dir) };
        croak "Cannot create storage directory: $storage_dir\nError: $@" if $@;
    }

    # Explicit backend selection is required
    my $backend_class = $config->{backend_class}
    	or croak "Configuration must include 'backend_class' parameter";

    # Load backend module
    eval "require $backend_class";
    return {
        success => 0,
        message => "Backend '$backend_class' not available: $@"
    } if $@;

	my $field_meta	= Concierge::Users::Meta::init_field_meta($config);

    # Merge original config with field_meta for backend configure()
    # (backend needs storage_dir and other config options)
    my $backend_config = {
        %$config,
        %$field_meta,
    };

    # Call backend configure() to create storage
    my $configure_result = $backend_class->configure( $backend_config );
    return $configure_result unless $configure_result->{success};

    # Config file is always: storage_dir/users-config.json
    my $config_file = "$storage_dir/users-config.json";

    # Build complete config structure for serialization
    my $config_to_save = {
        version => "$Concierge::Users::VERSION",
        generated => Concierge::Users::Meta->current_timestamp(),
        backend_module => $backend_class,
        backend_config => $configure_result->{config},
        fields => $field_meta->{fields},
        field_definitions => $field_meta->{field_definitions},
        storage_initialized => 1,
    };

    # Serialize and save JSON config
    eval {
        open my $fh, '>', $config_file or croak "Cannot open $config_file for writing: $!";
        print {$fh} encode_json($config_to_save);
        close $fh;
    };
    return {
        success => 0,
        message => "Failed to write config file: $config_file\nError: $@"
    } if $@;

    # Generate and save YAML config (human-readable reference)
    my $yaml_file = "$storage_dir/users-config.yaml";
    my $yaml_content = Concierge::Users::Meta::config_to_yaml($config_to_save, $storage_dir);
    eval {
        open my $fh, '>', $yaml_file or croak "Cannot open $yaml_file for writing: $!";
        print {$fh} $yaml_content;
        close $fh;
        chmod 0666, $yaml_file;  # Writable - allows setup() to overwrite
    };
    return {
        success => 0,
        message => "Failed to write YAML config file: $yaml_file\nError: $@"
    } if $@;

    return {
        success => 1,
        message => "Users system configured successfully",
        config_file => $config_file,
        yaml_file => $yaml_file,
    };
}

# ==============================================================================
# Constructor - Load from saved config
# ==============================================================================

sub new {
    my ($class, $config_file) = @_;

    croak "Usage: Concierge::Users->new('/path/to/users-config.json')"
        . "\nCall Concierge::Users->setup() first with configuration to create the config file"
        unless $config_file && -f $config_file;

    # Load and deserialize config
    my $config_json;
    eval {
        open my $fh, '<', $config_file or croak "Cannot open $config_file: $!";
        local $/;  # slurp mode
        $config_json = <$fh>;
        close $fh;
    };
    croak "Failed to read config file: $config_file\nError: $@" if $@;

    my $saved_config;
    eval {
        $saved_config = decode_json($config_json);
    };
    croak "Failed to parse config file: $config_file\nError: $@" if $@;

    # Validate config structure
    croak "Invalid config file: missing 'backend_module' or 'fields'"
        unless $saved_config->{backend_module} && $saved_config->{fields};

    # Load backend module
    my $backend_module = $saved_config->{backend_module};
    eval "require $backend_module";
    croak "Backend '$backend_module' not available: $@" if $@;

    # Instantiate backend with its config (no fields needed for runtime)
    my $backend_obj = $backend_module->new($saved_config->{backend_config});

    # Create Users object - just store what's needed for API operations
    my $self = bless {
        backend            => $backend_obj,
        fields             => $saved_config->{fields},
        field_definitions => $saved_config->{field_definitions},
    }, $class;

    return $self;
}

# ==============================================================================
# Public API Methods
# ==============================================================================

# Register a new user
sub register_user {
    my ($self, $user_data) = @_;

    return { success => 0, message => "User data must be a hash reference" }
        unless ref $user_data eq 'HASH';

    # Clone user_data to avoid modifying caller's hashref
    my $data = { %$user_data };

    # 0. Clean $data
    # Delete any data for system timestamps
    delete $data->{$_} for qw/created_date last_mod_date/;
    # Define undefined values and remove leading and trailing whitespace
    for my $f (keys $data->%*) {
    	$data->{$f} //= '';
    	$data->{$f} =~ s/^\s*|\s*$//g;
    }

    # 1. Validate user_id, including allowing email address as ID
    return { success => 0, message => "user_id is required as 2-30 characters, email OK, no spaces" }
        unless $data->{user_id}
        	&& $data->{user_id} =~ /^[a-zA-Z0-9._@-]{2,30}$/;

    # 2. Validate moniker
    return { success => 0, message => "moniker is required as 2-24 alphanumeric characters, no spaces" }
        unless $data->{moniker}
        && $data->{moniker} =~ /^[a-zA-Z0-9]{2,24}$/;

    # 3. Check if user already exists
    my $existing = $self->get_user($data->{user_id});
    return { success => 0, message => "User '$data->{user_id}' already exists" }
    	if $existing->{success};

    # 4. Store user_id and moniker, then remove from data for further processing
    my $new_user_id = delete $data->{user_id};
    my $user_init_record	= {
    	user_id		=> $new_user_id,
    	moniker		=> delete $data->{moniker},
    };
    for my $field (@{$self->{fields}}) {
    	# Skip user_id and moniker - already set
    	next if $field eq 'user_id' || $field eq 'moniker';

    	# Get field definition
		my $def = $self->{field_definitions}->{$field};
		# Apply default for new records if it is defined
		if (defined $def->{default}) {
			$user_init_record->{$field} = $def->{default};
		}
		# Otherwise apply null_value for record initialization
		elsif (defined $def->{null_value}) {
			$user_init_record->{$field} = $def->{null_value};
		}
		else {
			$user_init_record->{$field} = '';
		}
    }
    my $result = $self->{backend}->add( $new_user_id, $user_init_record );
    return $result unless $result->{success};

    # 5. Validate
    my $validation = $self->validate_user_data( $data );
    return $validation unless $validation->{success};
    # Proceed only with validated data
    my $validated_user_data	= $validation->{valid_data};

    # 6. Populate the record with validated user data
    $result = $self->{backend}->update( $new_user_id, $validated_user_data );

    # Override message to indicate creation rather than update
    $result->{message} = "User '$new_user_id' created";

    # Add warnings to result if any
    $result->{warnings} = $validation->{warnings} if $validation->{warnings};

    return $result;
}

# Get user by ID
sub get_user {
    my ($self, $user_id, $options) = @_;

    return { success => 0, message => "user_id is required" }
        unless $user_id && $user_id =~ /\S/;

    $options ||= {};

    my $fetch_result = $self->{backend}->fetch($user_id);

    unless ($fetch_result->{success}) {
        return { success => 0, message => $fetch_result->{message} };
    }

    my $user_data = $fetch_result->{data};

    # Handle field selection
    if ($options->{fields} && ref $options->{fields} eq 'ARRAY') {
        my %selected;
        $selected{$_} = $user_data->{$_} for @{$options->{fields}};
        $selected{user_id} = $user_data->{user_id};  # Always include user_id
        $user_data = \%selected;
    }

    return {
        success => 1,
        user_id => $user_id,
        user => $user_data
    };
}

# Update user
sub update_user {
    my ($self, $user_id, $updates) = @_;

    return { success => 0, message => "user_id is required" }
        unless $user_id && $user_id =~ /\S/;

    return { success => 0, message => "Updates must be a hash reference" }
        unless ref $updates eq 'HASH';

    # Check if user exists
    my $existing = $self->get_user($user_id);
    unless ($existing->{success}) {
        return { success => 0, message => "User '$user_id' not found" };
    }

    # 0. Clean $updates
    # Delete any data for user_id and system timestamps
    delete $updates->{$_} for qw/user_id created_date last_mod_date/;
    # Define undefined values and remove leading and trailing whitespace
    for my $f (keys $updates->%*) {
    	$updates->{$f} //= '';
    	$updates->{$f} =~ s/^\s*|\s*$//g;
    }

    # 1. Validate 
    my $validation = $self->validate_user_data( $updates );
    return $validation unless $validation->{success};
    # Proceed only with validated data
    my $validated_updates	= $validation->{valid_data};

    # 2. Populate the record with user data
    my $result = $self->{backend}->update( $user_id, $validated_updates );
    
    # Add warnings to result if any
    if ($validation->{warnings}) {
        $result->{warnings} = $validation->{warnings};
    }

    return $result;
}

# List users - only returns user_ids with optional filtering
sub list_users {
    my ($self, $filter_string) = @_;

    # Parse filter string if provided
    my $filters = {};
    if ($filter_string && $filter_string =~ /\S/) {
        $filters = $self->parse_filter_string($filter_string);
    }

    my $users = $self->{backend}->list($filters, {});
    my @user_ids = map { $_->{user_id} } @{$users->{data} || []};

    return {
        success => 1,
        user_ids => \@user_ids,
        total_count => $users->{total_count} || 0,
        filter_applied => ($filter_string && $filter_string =~ /\S/) ? $filter_string : '',
    };
}

# Delete user
sub delete_user {
    my ($self, $user_id) = @_;

    return { success => 0, message => "user_id is required" }
        unless $user_id && $user_id =~ /\S/;

    # Check if user exists
    my $existing = $self->get_user($user_id);
    unless ($existing->{success}) {
        return { success => 0, message => "User '$user_id' not found" };
    }

    # Delete using backend
    my $result = $self->{backend}->delete($user_id);

    return $result;
}

# Utility methods

# Cleanup
sub DESTROY {
    my $self = shift;

    # Disconnect backend if it has a disconnect method
    if ($self->{backend} && $self->{backend}->can('disconnect')) {
        $self->{backend}->disconnect();
    }
}

1;

__END__

=head1 NAME

Concierge::Users - User data management with multiple storage backends

=head1 VERSION

v0.9.4

=head1 SYNOPSIS

    use Concierge::Users;

    # One-time setup -- creates storage and config file
    my $result = Concierge::Users->setup({
        storage_dir             => './data/users',
        backend_class           => 'Concierge::Users::SQLite',
        include_standard_fields => 'all',
        app_fields              => ['role', 'theme'],
    });

    # Runtime -- load from saved config
    my $users = Concierge::Users->new('./data/users/users-config.json');

    # Register a user
    my $result = $users->register_user({
        user_id => 'alice',
        moniker => 'Alice',
        email   => 'alice@example.com',
    });

    # Retrieve a user
    my $result = $users->get_user('alice');
    my $data   = $result->{user};

    # Update a user
    $users->update_user('alice', { email => 'new@example.com' });

    # List users (optionally with filters)
    my $result = $users->list_users('user_status=Active');
    my @ids    = @{ $result->{user_ids} };

    # Delete a user
    $users->delete_user('alice');

=head1 DESCRIPTION

Concierge::Users manages user data records with a two-phase lifecycle:

=over 4

=item 1. B<Setup> (one-time) -- C<< Concierge::Users->setup(\%config) >>
configures the storage backend, defines the field schema, and writes a
JSON config file.

=item 2. B<Runtime> -- C<< Concierge::Users->new($config_file) >> loads
the saved config and provides CRUD operations.

=back

All public methods return hashrefs with a C<success> key (1 or 0) and a
C<message> on failure:

    { success => 1, user_id => 'alice', user => \%data }
    { success => 0, message => 'User not found' }

Concierge::Users is the user data component of the Concierge suite,
alongside L<Concierge::Auth> (password authentication) and
L<Concierge::Sessions> (session management). It can also be used
standalone.

=head2 Storage Backends

A backend is selected by passing its fully-qualified class name as
C<backend_class> to C<setup()>. Concierge::Users performs no
friendly-name guessing or default selection of its own -- the named
module is C<require>d dynamically inside C<setup()>. When used as a
component of a Concierge desk, resolving a friendly name (such as a
config file's C<users.backend> setting) to a fully-qualified class name
is a desk-build-time concern handled by L<Concierge::Desk::Setup> (see
its backend catalog, C<%USERS_BACKENDS>), not by this module.

=over 4

=item B<Concierge::Users::SQLite> -- SQLite via L<DBI>/L<DBD::SQLite>.
Recommended for production and larger datasets.

=item B<Concierge::Users::File> -- CSV/TSV flat file. Simple,
human-readable, no database dependency.

=item B<Concierge::Users::YAML> -- One YAML file per user via
L<YAML::Tiny>. Good for individual user access patterns.

=back

All backends provide the same CRUD API. The backend is selected at setup
time and its class name is recorded verbatim in the config file.

=head2 Field System

Every user record has two required fields: C<user_id> and C<moniker>.
Beyond these, the field schema is configured at setup time from four
categories:

B<Core (4):> C<user_id>, C<moniker>, C<user_status>, C<access_level> --
always present.

B<Standard (11):> C<first_name>, C<middle_name>, C<last_name>,
C<prefix>, C<suffix>, C<organization>, C<title>, C<email>, C<phone>,
C<text_ok>, C<term_ends> -- included by default.
Select specific ones with an arrayref, or pass an empty arrayref
C<[]> to exclude all standard fields.

B<System (3):> C<last_login_date>, C<last_mod_date>, C<created_date> -- auto-managed
timestamps, protected from overrides and API writes.

B<Application:> Custom fields defined with C<app_fields> as name strings
or full definition hashrefs.

Field definitions can also be modified with C<field_overrides>.
See L<Concierge::Users::Meta/FIELD CATALOG> for complete field details
and L<Concierge::Users::Meta/FIELD CUSTOMIZATION> for the customization
guide.

=head2 Validation

Field values are validated on C<register_user> and C<update_user>.
Ten validator types are available:

C<text>, C<email>, C<phone>, C<date>, C<timestamp>, C<boolean>,
C<integer>, C<enum>, C<moniker>, C<name>.

Each field's validator is determined by its C<validate_as> attribute, or
by C<type> as a fallback.  Fields where C<must_validate> is C<1> will
reject the entire operation on failure.  Fields where C<must_validate>
is C<0> produce a non-fatal warning and the invalid value is dropped.

Set the environment variable C<USERS_SKIP_VALIDATION> to a true value to
bypass all validation (useful for bulk imports or testing).

See L<Concierge::Users::Meta/VALIDATOR TYPES> for accepted patterns and
null values for each type.

=head2 Data Archiving

Calling C<setup()> when data already exists automatically archives the
existing data (renamed with a timestamp suffix) before creating new
storage. This prevents accidental data loss during schema changes.

=head1 METHODS

=head2 setup

    my $result = Concierge::Users->setup(\%config);

One-time initialization. Creates the storage directory, backend storage,
and writes the config files (JSON and YAML).

B<Configuration keys:>

=over 4

=item C<storage_dir> (required) -- directory for data files; created if
absent.

=item C<backend_class> (required) -- fully-qualified backend class name,
e.g. C<Concierge::Users::SQLite>, C<Concierge::Users::File>, or
C<Concierge::Users::YAML>.

=item C<include_standard_fields> -- Optional.  When omitted or set to
C<'all'>, all 12 standard fields are included (the default).  Pass an
arrayref of field names to select specific standard fields, or an empty
arrayref C<[]> to exclude all standard fields.

=item C<app_fields> -- arrayref of application-specific field names
(strings) or field definition hashrefs.

=item C<file_format> -- C<'csv'> or C<'tsv'> (file backend only;
default C<'tsv'>).

=item C<field_overrides> -- arrayref of hashrefs that modify built-in
field definitions.  Core enum fields like C<user_status> and
C<access_level> cannot be removed, but their C<options> can be
replaced to fit your application.
See L<Concierge::Users::Meta/Field Overrides>.

=back

Returns C<< { success => 1, config_file => $path } >> on success.

Croaks if C<storage_dir> or C<backend_class> is missing, or if the
directory cannot be created.

=head2 new

    my $users = Concierge::Users->new($config_file);

Loads a previously created config file and instantiates the backend.

Croaks if the config file does not exist, cannot be parsed, or the
backend module cannot be loaded.

=head2 register_user

    my $result = $users->register_user(\%user_data);

Registers a new user. C<%user_data> must include C<user_id> and
C<moniker>. Additional fields are validated against the schema and
stored. Fields not in the schema are silently ignored.

User IDs must be 2-30 characters (alphanumeric plus C<.>, C<_>, C<@>,
C<->). Monikers must be 2-24 alphanumeric characters.

Returns C<< { success => 1, message => "User 'id' created" } >> on
success. May include a C<warnings> arrayref for non-fatal validation
issues.

=head2 get_user

    my $result = $users->get_user($user_id);
    my $result = $users->get_user($user_id, { fields => [qw/email phone/] });

Retrieves a user record. With the C<fields> option, returns only the
specified fields (C<user_id> is always included).

Returns C<< { success => 1, user_id => $id, user => \%data } >>.

=head2 update_user

    my $result = $users->update_user($user_id, \%updates);

Updates an existing user record. The C<user_id>, C<created_date>, and
C<last_mod_date> fields are stripped from updates automatically.
Remaining fields are validated before writing.

Returns C<< { success => 1 } >> on success.

=head2 list_users

    my $result = $users->list_users();
    my $result = $users->list_users('user_status=OK');
    my $result = $users->list_users('access_level=staff|access_level=admin');

Returns user IDs, optionally filtered.  The filter string supports five
operators: C<=> (exact), C<:> (contains), C<!> (not-contains), C<E<gt>>
(greater than), C<E<lt>> (less than).  Combine conditions with C<;>
(AND) or C<|> (OR); AND binds tighter than OR.

    # Active members
    user_status=OK;access_level=member

    # Staff or admin
    access_level=staff|access_level=admin

See L<Concierge::Users::Meta/FILTER DSL> for the full reference.

Returns:

    {
        success        => 1,
        user_ids       => \@ids,
        total_count    => $n,
        filter_applied => $filter_string,
    }

=head2 delete_user

    my $result = $users->delete_user($user_id);

Deletes a user record. Fails if the user does not exist.

=head2 show_default_config

    my $result = Concierge::Users::Meta->show_default_config();
    print $result->{config} if $result->{success};

Returns C<< { success => 1, config => $yaml_string } >> containing the
built-in default field configuration template.  Always succeeds.
Callers decide how to use the string.  Can be called as a class or
instance method (inherited from L<Concierge::Users::Meta>).

=head2 show_config

    my $result = $users->show_config();
    my $result = $users->show_config(output_path => '/tmp/my-config.yaml');
    print $result->{config} if $result->{success};

Returns C<< { success => 1, config => $yaml_string, config_file => $path } >>
with the active YAML configuration for this instance.  Callers decide
how to use the string.  Must be called on an instance (after C<new>).
Inherited from L<Concierge::Users::Meta>.

=head1 SEE ALSO

L<Concierge::Users::Meta> -- field definitions, validators, and
configuration utilities

L<Concierge::Users::SQLite>, L<Concierge::Users::File>,
L<Concierge::Users::YAML> -- storage backend implementations

L<Concierge::Desk::Setup> -- resolves friendly backend names (e.g.
C<'database'>) to fully-qualified classes at desk-build time

L<Concierge::Auth>, L<Concierge::Sessions> -- companion Concierge
components

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut