package Concierge::Setup v0.7.0;
use v5.36;

our $VERSION = 'v0.7.0';

# ABSTRACT: Setup and configuration for Concierge desk initialization

use Carp qw<carp croak>;
use File::Spec;
use File::Path qw/make_path/;
use JSON::PP qw< encode_json decode_json >;
use Concierge;

# === COMPONENT MODULES ===
use Concierge::Auth;
use Concierge::Sessions;
use Concierge::Users;

# =============================================================================
# SIMPLE SETUP - Opinionated defaults for quick start
# =============================================================================

sub build_quick_desk ($storage_dir, $app_fields=[]) {
    # Simple, opinionated setup with reasonable defaults:
    # - Database sessions backend (SQLite via Concierge::Sessions)
    # - Database users backend (SQLite via Concierge::Users)
    # - All standard user fields included
    # - All storage co-located in $storage_dir

    return { success => 0, message => 'desk_location is required' }
        unless defined $storage_dir;

    # Safety: Convert '.' or empty string to './desk' to avoid cluttering app root
    if (!$storage_dir || $storage_dir eq '.' || $storage_dir eq './') {
        $storage_dir = './desk';
    }

    # Ensure storage directory exists
    unless (-d $storage_dir) {
        eval { make_path($storage_dir) };
        croak "Cannot create storage directory '$storage_dir': $@" if $@;
    }

    # Create minimal Concierge object for internal operations
    my $concierge = bless {}, 'Concierge';

    # Initialize Sessions component
    $concierge->{sessions} = Concierge::Sessions->new(
        storage_dir => $storage_dir,  # Uses database backend (SQLite) by default
    );

    # Initialize Auth component
    my $auth_file	= File::Spec->catfile($storage_dir, 'auth.pwd');
    $concierge->{auth} = Concierge::Auth->new({
        file => $auth_file
    });

    # Setup Users component
    my $users_setup = Concierge::Users->setup({
        storage_dir             => $storage_dir,
        backend                 => 'database',  # Database backend (SQLite)
        include_standard_fields => 'all',       # All standard fields
        field_overrides         => [],          # No overrides
        app_fields              => $app_fields,
    });
    unless ($users_setup->{success}) {
        return {
            success => 0,
            message => "Failed to setup Users: " . $users_setup->{message}
        };
    }

    # Build configuration to store in concierge session
    my $full_config = {
        users_config_file   => $users_setup->{config_file},
        storage_dir         => $storage_dir,
        sessions_dir        => $storage_dir,
        users_dir           => $storage_dir,
        auth_file           => $auth_file,
        sessions_backend    => 'database',
        users_backend       => 'database',
    };
    # Encode to JSON with pretty formatting and write with trailing newline
    my $json = JSON::PP->new->utf8->pretty->encode($full_config) . "\n";
   
    my $concierge_conf_file	= File::Spec->catfile($storage_dir, 'concierge.conf');
    
    my $fh;
    open $fh, ">", $concierge_conf_file
    	and
    print $fh $json
    	and
    close $fh
    	or return { success => 0, message => "Cannot write to concierge config file: $!" };

    return {
        success => 1,
        message => "Concierge desk built successfully",
        desk    => $storage_dir,
    };
}

# =============================================================================
# ADVANCED SETUP - Full control with custom configuration
# =============================================================================

sub build_desk ($config) {
    # Advanced setup with full configuration options:
    # - Separate storage directories per component
    # - Full Users.pm field configuration (include_standard_fields, field_overrides, etc.)
    # - Custom backend selection for Sessions and Users
    # - No assumptions or defaults

    # Validate required top-level config
    return { success => 0, message => 'Configuration must be a hash reference' }
        unless ref $config eq 'HASH';

    return { success => 0, message => 'Missing storage.base_dir' }
        unless $config->{storage} && $config->{storage}{base_dir};

    # Safety: Convert '.' or empty string to './desk' to avoid cluttering app root
    my $base_dir = $config->{storage}{base_dir};
    if (!$base_dir || $base_dir eq '.' || $base_dir eq './') {
        $base_dir = './desk';
        $config->{storage}{base_dir} = $base_dir;
    }

    # Determine storage locations (support separate dirs or single base_dir)
    my $sessions_dir	= $config->{storage}{sessions_dir} || $base_dir;
    my $users_dir		= $config->{storage}{users_dir} || $base_dir;
    my $auth_file		= $config->{auth}{file} || File::Spec->catfile($base_dir, 'auth.pwd');

    # Create directories if needed
    for my $dir ($base_dir, $sessions_dir, $users_dir) {
        next if -d $dir;
        eval { make_path($dir) };
        return {
            success => 0,
            message => "Failed to create directory '$dir': $@"
        } if $@;
    }

    # Create minimal Concierge object for internal operations
    my $concierge = bless {}, 'Concierge';

    # Initialize Sessions component with specified backend
    my $sessions_backend = $config->{sessions}{backend} || 'database'; 
    $concierge->{sessions} = Concierge::Sessions->new(
        backend     => $sessions_backend,
        storage_dir => $sessions_dir,
    );

    # Initialize Auth component
    $concierge->{auth} = Concierge::Auth->new({
        file => $auth_file
    });

    # Build Users setup configuration
    my $users_config = {
        storage_dir => $users_dir,
        backend     => $config->{users}{backend} || 'database',
    };

    # Add Users-specific configuration options
    $users_config->{include_standard_fields} = $config->{users}{include_standard_fields}
        if exists $config->{users}{include_standard_fields};

    $users_config->{app_fields} = $config->{users}{app_fields}
        if exists $config->{users}{app_fields};

    $users_config->{field_overrides} = $config->{users}{field_overrides}
        if exists $config->{users}{field_overrides};

    # Setup Users component
    my $users_setup = Concierge::Users->setup($users_config);
    unless ($users_setup->{success}) {
        return {
            success => 0,
            message => "Failed to setup Users: " . $users_setup->{message}
        };
    }

    # Build configuration to store in concierge session
    my $full_config = {
        users_config_file   => $users_setup->{config_file},
        storage_dir         => $base_dir,
        sessions_dir        => $sessions_dir,
        users_dir           => $users_dir,
        auth_file           => $auth_file,
        sessions_backend    => $sessions_backend,
        users_backend       => $users_config->{backend},
    };
    my $json = JSON::PP->new->utf8->pretty->encode($full_config) . "\n";

	my $config_location	= $full_config->{storage_dir};
    my $concierge_conf_file	= File::Spec->catfile($config_location, 'concierge.conf');
    my $fh;
    open $fh, ">", $concierge_conf_file
    	and
    print $fh $json
    	and
    close $fh
    	or return { success => 0, message => "Cannot write to concierge config file: $!" };

    return {
        success => 1,
        message => "Custom Concierge desk built successfully",
        desk    => $base_dir,
        config  => $full_config,
    };
}


# =============================================================================
# HELPER METHODS
# =============================================================================

# Validate setup configuration before executing
sub validate_setup_config ($config) {
    my @errors;

    # Check required fields
    push @errors, "Missing storage.base_dir"
        unless $config->{storage} && $config->{storage}{base_dir};

    push @errors, "Missing auth.file"
        unless $config->{auth} && $config->{auth}{file};

    push @errors, "Missing sessions.backend"
        unless $config->{sessions} && $config->{sessions}{backend};

    push @errors, "Missing users.backend"
        unless $config->{users} && $config->{users}{backend};

    # Validate backend values
    if ($config->{sessions}{backend}) {
        my $backend = lc $config->{sessions}{backend};
        push @errors, "Invalid sessions.backend: must be 'database' or 'file'"
            unless $backend =~ /^(database|file)$/;
    }

    if ($config->{users}{backend}) {
        my $backend = lc $config->{users}{backend};
        push @errors, "Invalid users.backend: must be 'database', 'yaml', or 'file'"
            unless $backend =~ /^(database|yaml|file)$/;
    }

    return {
        success => @errors ? 0 : 1,
        (@errors ? (errors => \@errors) : ()),
    };
}

1;

__END__

=head1 NAME

Concierge::Setup - One-time desk creation and configuration for Concierge

=head1 VERSION

v0.7.0

=head1 SYNOPSIS

    use Concierge::Setup;

    # Simple setup -- database backends, all standard user fields
    my $result = Concierge::Setup::build_quick_desk(
        './desk',
        ['role', 'theme'],       # application-specific user fields
    );

    # Advanced setup -- full control over backends and field configuration
    my $result = Concierge::Setup::build_desk({
        storage => {
            base_dir     => './desk',
            sessions_dir => './desk/sessions',
            users_dir    => './desk/users',
        },
        auth => {
            file => './desk/auth.pwd',
        },
        sessions => {
            backend => 'database',  # or 'file'
        },
        users => {
            backend                 => 'database',  # 'database', 'yaml', or 'file'
            include_standard_fields => [qw/email phone first_name last_name/],
            app_fields              => ['membership_tier', 'department'],
            field_overrides         => [{ field_name => 'email', required => 1 }],
        },
    });

=head1 DESCRIPTION

Concierge::Setup provides methods for one-time initialization of a
Concierge desk -- the storage directory containing configuration and data
files for the identity core components (Auth, Sessions, Users).

Setup is separate from runtime operations.  Use this module once to
create a desk, then use L<Concierge/open_desk> at runtime.

The configuration structure passed to C<build_desk()> is organized by
component (C<auth>, C<sessions>, C<users>).  Applications that
introduce additional components under the C<Concierge::> namespace can
extend this structure with their own configuration blocks, following
the same pattern.  See L<Concierge/Architecture> for details.

=head2 The ./desk Convention

If C<$storage_dir> is C<'.'>, C<'./'>, or an empty string, it is
automatically converted to C<'./desk'> to avoid cluttering the
application root directory.

=head1 METHODS

=head2 build_quick_desk

    my $result = Concierge::Setup::build_quick_desk(
        $storage_dir,
        \@app_fields,
    );

Creates a desk with opinionated defaults: SQLite backends for both
Sessions and Users, all standard user fields included, all storage
co-located in C<$storage_dir>. The password file (C<auth.pwd>) is
created automatically inside C<$storage_dir>.

B<Parameters:>

=over 4

=item C<$storage_dir> (required)

Directory for all data files; created if it does not exist.

=item C<\@app_fields>

Additional user data fields beyond the standard set.

=back

Returns C<< { success => 1, desk => $desk_location } >> on success,
or C<< { success => 0, message => '...' } >> on failure.

=head2 build_desk

    my $result = Concierge::Setup::build_desk(\%config);

Creates a desk with full control over backend selection, storage layout,
and user field configuration.

B<Configuration structure:>

    {
        storage => {
            base_dir     => $path,       # required
            sessions_dir => $path,       # default: base_dir
            users_dir    => $path,       # default: base_dir
        },
        auth => {
            file => $path,               # default: base_dir/auth.pwd
        },
        sessions => {
            backend => 'database',       # 'database' or 'file'
        },
        users => {
            backend                 => 'database',  # 'database', 'yaml', or 'file'
            include_standard_fields => 'all',        # 'all' or \@field_names
            app_fields              => \@fields,     # custom fields
            field_overrides         => \@overrides,  # modify built-in fields
        },
    }

The C<users> block is where field configuration happens.  The sections
below describe the available fields and show how to customize them.

=head3 User Field Reference

Every user record draws from four field categories:

B<Core fields> (always present):

    user_id        system   Primary authentication identifier (max 30)
    moniker        moniker  Display name, nickname, or initials (max 24)
    user_status    enum     Eligible*, OK, Inactive (max 20)
    access_level   enum     anon*, visitor, member, staff, admin (max 20)

B<Standard fields> (selectable at setup):

    first_name     name     max 50
    middle_name    name     max 50
    last_name      name     max 50
    prefix         enum     (none) Dr Mr Ms Mrs Mx Prof Hon Sir Madam
    suffix         enum     (none) Jr Sr II III IV V PhD MD DDS Esq
    organization   text     max 100
    title          text     max 100
    email          email    max 255
    phone          phone    max 20
    text_ok        boolean
    last_login_date timestamp
    term_ends      date

B<System fields> (auto-managed, always present):

    last_mod_date  system   Updated on every write
    created_date   system   Set once on creation

Core and system fields cannot be removed.  Standard fields default to
C<< required => 0 >>.

=head3 Validator Types

Ten built-in validators are available for field definitions and
overrides:

    text        Any string (max_length enforced if set)
    email       user@domain.tld pattern
    phone       Digits, spaces, hyphens, parens, optional +; min 7 chars
    date        YYYY-MM-DD
    timestamp   YYYY-MM-DD HH:MM:SS (or with T separator)
    boolean     Strictly 0 or 1
    integer     Optional minus, digits only
    enum        Value must appear in the field's options list
    moniker     2-24 alphanumeric, no spaces
    name        Letters (incl. accented), hyphens, apostrophes, spaces

See L<Concierge::Users::Meta/VALIDATOR TYPES> for patterns and null
values.

Set the environment variable C<USERS_SKIP_VALIDATION> to a true value
to bypass all validation -- useful for bulk imports or testing.

=head3 Selecting Standard Fields

Include all standard fields:

    users => {
        backend                 => 'database',
        include_standard_fields => 'all',
    },

Or pick only the ones your application needs:

    users => {
        backend                 => 'database',
        include_standard_fields => [qw/first_name last_name email/],
    },

Pass an empty arrayref C<[]> to exclude all standard fields -- useful
when your application defines its own fields from scratch.  Omitting
C<include_standard_fields> (or setting it to any falsy value) includes
all 12 standard fields, the same as C<'all'>.

=head3 Adding Application Fields

Custom fields are passed as C<app_fields>, an arrayref of field names
(string shorthand) or full definition hashrefs:

    users => {
        backend    => 'database',
        app_fields => [
            'nickname',                          # string: text, not required
            'bio',                               # string: text, not required
            {                                    # hashref: full control
                field_name  => 'department',
                type        => 'enum',
                options     => ['*Engineering', 'Sales', 'Support'],
                required    => 1,
                label       => 'Department',
                description => 'Primary department assignment',
            },
            {
                field_name    => 'employee_id',
                type          => 'text',
                validate_as   => 'moniker',      # text storage, moniker validation
                required      => 1,
                must_validate => 1,
                max_length    => 12,
            },
        ],
    },

String shorthand creates a field with C<< type => 'text' >>,
C<< required => 0 >>.

B<Enum default convention:> In an C<options> arrayref, prefix exactly
one value with C<*> to mark it as the default for new records.
C<< ['*Community', 'Maker', 'Pro'] >> means new records get
C<Community> unless another value is supplied.  A bare C<*> (as used
by the built-in C<prefix> and C<suffix> fields) designates an
empty-string default.  The C<*> is stripped internally before
validation -- stored values never contain it.  If no C<*> option
exists and no explicit C<default> is set, the default is C<"">.

=head3 Available attributes for field definition hashrefs

=over 4

=item C<field_name>

Internal name (snake_case); required.

=item C<type>

C<text>, C<email>, C<phone>, C<date>, C<timestamp>, C<boolean>,
C<integer>, C<enum>.

=item C<validate_as>

Validator to use when different from C<type> (e.g.,
C<< validate_as => 'moniker' >> on a C<text> field applies
alphanumeric-only validation while storing as text).

=item C<label>

Human-readable display label; auto-generated from C<field_name> if
omitted (e.g., C<badge_name> becomes "Badge Name").

=item C<description>

Short explanatory text for documentation or UI hints.

=item C<required>

C<1> if the field must have a non-null value on creation; C<0>
otherwise.

=item C<must_validate>

C<1> to reject the entire operation on validation failure; C<0> to
silently drop the invalid value and append a warning (auto-enabled
when C<< required => 1 >>).

=item C<options>

Arrayref of allowed values for C<enum> fields; prefix one with C<*>
to designate the default (e.g.,
C<['*Free', 'Premium', 'Enterprise']>); a bare C<*> means an
empty-string default.

=item C<default>

Value assigned on new-record creation when no value is supplied; for
enum fields, auto-set from the C<*>-marked option if not specified
explicitly.

=item C<null_value>

Sentinel representing "no data" for the field type (e.g., C<""> for
text, C<""> for boolean, C<"0000-00-00"> for date); values equal to
C<null_value> are treated as empty.

=item C<max_length>

Maximum character length; enforced by the C<text> validator and
available as a UI hint.

=back

See L<Concierge::Users::Meta/FIELD ATTRIBUTES> for the complete
attribute reference.

=head3 Modifying Standard Fields

Use C<field_overrides> to change attributes of built-in fields without
replacing them:

    users => {
        backend                 => 'database',
        include_standard_fields => [qw/email phone organization/],
        field_overrides         => [
            {
                field_name => 'email',
                required   => 1,               # make email mandatory
                label      => 'Work Email',
            },
            {
                field_name => 'organization',
                required   => 1,
                max_length => 200,             # increase from default 100
            },
        ],
    },

B<Overriding enum options:> Core fields like C<user_status> and
C<access_level> are always present, but their C<options> are not fixed.
Replace them with values that fit your domain:

    # Makerspace member status instead of the default
    # Eligible / OK / Inactive
    field_overrides => [
        {
            field_name => 'user_status',
            options    => [qw( *Applicant Novice Skilled Expert Mentor Steward )],
        },
    ],

B<Protected fields> (cannot be overridden): C<user_id>, C<created_date>,
C<last_mod_date>.

B<Protected attributes> (cannot be changed): C<field_name>, C<category>.

B<Auto-behaviors:> changing C<type> auto-updates C<validate_as> to match;
setting C<< required => 1 >> auto-enables C<must_validate>.

See L<Concierge::Users::Meta/FIELD CUSTOMIZATION> for the complete
customization reference and L<Concierge::Users::Meta/FIELD CATALOG> for
full field specifications.

=head3 Complete Example

A community makerspace tracking members with custom fields, selective
standard fields, and modified built-in defaults:

    my $result = Concierge::Setup::build_desk({
        storage => {
            base_dir => './makerspace-desk',
        },
        sessions => { backend => 'database' },
        users => {
            backend                 => 'database',
            include_standard_fields => [qw/
                first_name last_name email phone organization
            /],
            field_overrides => [
                {
                    field_name => 'user_status',
                    options    => [qw( *Applicant Novice Skilled Expert Mentor Steward )],
                },
                {
                    field_name => 'email',
                    required   => 1,           # mandatory for members
                    label      => 'Contact Email',
                },
                {
                    field_name => 'organization',
                    max_length => 200,         # increase from default 100
                },
            ],
            app_fields => [
                'skills',                      # string shorthand: text, optional
                {
                    field_name  => 'membership_tier',
                    type        => 'enum',
                    options     => ['*Community', 'Maker', 'Pro', 'Sponsor'],
                    required    => 1,
                    label       => 'Membership Tier',
                    description => 'Determines access to equipment and hours',
                },
                {
                    field_name    => 'badge_name',
                    type          => 'text',
                    validate_as   => 'moniker',  # alphanumeric validation
                    required      => 1,
                    must_validate => 1,
                    max_length    => 16,
                    label         => 'Badge Name',
                    description   => 'Printed on member access badge',
                },
                {
                    field_name => 'newsletter_ok',
                    type       => 'boolean',
                    default    => 0,
                    label      => 'Newsletter Opt-in',
                },
            ],
        },
    });

This produces a user schema with 4 core fields, 5 selected standard
fields (C<email> now required), 4 application fields, and 2 system
timestamps -- 15 fields total.  The core C<user_status> field keeps its
usual role but uses makerspace-specific statuses (defaulting to
C<Applicant>).  New members default to the C<Community> tier (marked
with C<*>) and must provide a C<badge_name> that passes moniker
validation (2-24 alphanumeric characters).

=head3 Configuration Introspection

After building a desk, the field schema can be inspected at runtime
through L<Concierge::Users> (inherited from L<Concierge::Users::Meta>):

    # Before setup: view built-in default field definitions
    Concierge::Users::Meta->show_default_config();

    # After setup: view the active schema for this desk
    my $users = Concierge::Users->new('./makerspace-desk/users-config.json');
    $users->show_config();

    # Get UI-friendly hints for building forms dynamically
    my $hints = $users->get_field_hints('membership_tier');
    # Returns: { label, type, options, max_length, description, required }

    # Get the ordered field list for this schema
    my $fields = $users->get_user_fields();

C<show_default_config()> prints the built-in field template to STDOUT --
useful for reviewing available standard fields before writing a setup
script.  C<show_config()> prints the YAML configuration generated
during C<setup()>, reflecting the actual schema including any overrides
and application fields.  C<get_field_hints()> returns a hashref of
display-ready attributes for a single field, suitable for generating
form elements programmatically.

=head3 Data Archiving

Calling C<< Concierge::Users->setup() >> when data already exists in
the storage directory automatically archives the existing data files
(renamed with a timestamp suffix) before creating new storage.  This
means re-running a setup script to change the field schema will not
silently destroy existing user records.

B<Returns:>

    { success => 1, desk => $base_dir, config => \%full_config }

On failure:

    { success => 0, message => '...' }

=head2 validate_setup_config

    my $result = Concierge::Setup::validate_setup_config(\%config);

Validates a configuration hashref without creating anything. Returns
C<< { success => 1 } >> or C<< { success => 0, errors => [...] } >>.

=head1 SEE ALSO

L<Concierge> -- runtime operations after desk is built

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
