package Concierge::Desk::Setup v0.11.0;
use v5.36;

our $VERSION = 'v0.11.0';

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

# === AUTH BACKEND CATALOG ===
# Maps a friendly auth.backend name (as given in setup config) to its
# fully-qualified class name and the settings it requires. Adding a
# new backend (e.g. an LDAP-backed one) is a one-entry addition here;
# Concierge::Auth itself never guesses or validates any of this --
# see its POD. 'class' need not live under the Concierge:: namespace
# -- Concierge::Auth's factory just require()s it and calls its new()
# (see its POD); any installed module implementing the 5-verb contract
# works, e.g. a company-internal SSO wrapper.
my %AUTH_BACKENDS = (
    pwd => {
        class        => 'Concierge::Auth::Pwd',
        required     => [],              # 'file' always resolves via
                                          # default_file below -- never
                                          # actually missing
        default_file => 'auth.pwd',
    },
    # ldap => {
    #     class    => 'Concierge::Auth::LDAP',
    #     required => [qw/host bind_dn password/],
    # },
    # oauth => {
    #     class    => 'Concierge::Auth::OAuth',
    #     required => [qw/client_id client_secret redirect_uri/],
    # },
    # saml => {
    #     class    => 'Concierge::Auth::SAML',
    #     required => [qw/idp_metadata_url entity_id/],
    # },
    # sso => {
    #     class    => 'MyApp::Auth::SSO',  # outside Concierge:: -- fine, see note above
    #     required => [qw/provider_url/],
    # },
);

# === SESSIONS BACKEND CATALOG ===
# Maps a friendly sessions.backend name to its fully-qualified class
# name and the settings it requires, same shape as %AUTH_BACKENDS.
# Concierge::Sessions itself never guesses a class from a friendly
# name -- it requires an already-resolved backend_class (see its POD).
my %SESSIONS_BACKENDS = (
    database => { class => 'Concierge::Sessions::SQLite', required => [] },
    file     => { class => 'Concierge::Sessions::File',   required => [] },
    # redis => {
    #     class    => 'Concierge::Sessions::Redis',
    #     required => [qw/host port/],
    # },
);

# === USERS BACKEND CATALOG ===
# Maps a friendly users.backend name to its fully-qualified class name
# and the settings it requires, same shape as %AUTH_BACKENDS.
# Concierge::Users itself never guesses a class from a friendly name --
# setup() requires an already-resolved backend_class (see its POD).
my %USERS_BACKENDS = (
    database => { class => 'Concierge::Users::SQLite', required => [] },
    file     => { class => 'Concierge::Users::File',     required => [] },
    yaml     => { class => 'Concierge::Users::YAML',     required => [] },
    # postgres => {
    #     class    => 'Concierge::Users::Postgres',
    #     required => [qw/host dbname user password/],
    # },
);

# Resolve a component's storage directory against base_dir: a relative
# $dir is joined onto $base_dir (so it moves if base_dir does); an
# absolute $dir is used as-is (letting a component's storage live
# anywhere, including outside the desk entirely); an undefined $dir
# falls back to $base_dir itself.
sub _resolve_dir ($dir, $base_dir) {
    return $base_dir unless defined $dir;
    return $dir if File::Spec->file_name_is_absolute($dir);
    return File::Spec->catdir($base_dir, $dir);
}

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

    # Initialize Sessions component -- build_quick_desk is fully
    # opinionated (like its fixed 'database' choice for Users), so the
    # resolved class name is hardcoded here rather than going through
    # the catalog/validation path used by build_desk().
    my $sessions_backend = 'Concierge::Sessions::SQLite';
    $concierge->{sessions} = Concierge::Sessions->new(
        backend_class => $sessions_backend,
        storage_dir   => $storage_dir,
    );

    # Initialize Auth component -- same rationale as Sessions above.
    my $auth_file    = File::Spec->catfile($storage_dir, 'auth.pwd');
    my $auth_backend = 'Concierge::Auth::Pwd';
    my $auth_args    = { file => $auth_file };
    unlink $auth_file if -f $auth_file;
    $concierge->{auth} = Concierge::Auth->new(
        backend_class => $auth_backend,
        %$auth_args,
    );

    # Setup Users component -- same rationale as Sessions above.
    my $users_backend = 'Concierge::Users::SQLite';
    my $users_setup = Concierge::Users->setup({
        storage_dir             => $storage_dir,
        backend_class           => $users_backend,
        include_standard_fields => 'all',       # All standard fields
        field_overrides         => [],          # No overrides
        app_fields              => $app_fields,
    });
    unless ($users_setup->{success}) {
        return {
            success => 0,
            message => "Failed to set up Users: " . $users_setup->{message}
        };
    }

    # Build configuration to store in concierge session
    my $full_config = {
        users_config_file   => $users_setup->{config_file},
        storage_dir         => $storage_dir,
        sessions_dir        => $storage_dir,
        users_dir           => $storage_dir,
        auth_backend        => $auth_backend,
        auth_args           => $auth_args,
        sessions_backend    => $sessions_backend,
        users_backend       => $users_backend,
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
    # - Custom backend selection for Authentication, Sessions, and Users
    # - No assumptions or defaults

    # Validate required top-level config
    return { success => 0, message => 'Configuration must be a hash reference' }
        unless ref $config eq 'HASH';

    return { success => 0, message => 'Missing base_dir' }
        unless $config->{base_dir};

    # Safety: Convert '.' or empty string to './desk' to avoid cluttering app root
    my $base_dir = $config->{base_dir};
    if (!$base_dir || $base_dir eq '.' || $base_dir eq './') {
        $base_dir = './desk';
        $config->{base_dir} = $base_dir;
    }

    # Determine storage locations. Each component may specify its own
    # 'dir' (falls back to base_dir if omitted). A relative dir is
    # resolved against base_dir, so it moves with it; an absolute dir
    # is used as-is, letting a component's storage live entirely
    # outside the desk (e.g. for security) without tying that
    # placement to how the rest of the desk is laid out.
    my $sessions_dir	= _resolve_dir($config->{sessions}{dir}, $base_dir);
    my $users_dir		= _resolve_dir($config->{users}{dir}, $base_dir);
    my $auth_dir		= _resolve_dir($config->{auth}{dir}, $base_dir);

    # Resolve the auth backend: config gives a friendly name (e.g.
    # 'pwd'); the catalog maps it to a fully-qualified class name and
    # the settings that backend requires. No default -- unlike
    # build_quick_desk(), this path is not opinionated about backend
    # choice.
    my $auth_backend_name = $config->{auth}{backend}
        or return { success => 0, message => 'Missing auth.backend' };
    my $auth_spec = $AUTH_BACKENDS{lc $auth_backend_name}
        or return { success => 0, message => "Unknown auth.backend: $auth_backend_name" };

    # auth.file is a filename only (not a path) -- where it lives is a
    # separate concern controlled by auth.dir (falls back to base_dir,
    # same as sessions.dir/users.dir). This lets the auth store be
    # located anywhere, including outside the rest of the desk's
    # storage for security, without tying that placement to
    # what the file happens to be named. The default filename is
    # backend-specific (only 'pwd' has one, since it's the only
    # backend that needs a file at all); this does not mean
    # Concierge::Auth itself has a fallback -- it never guesses at
    # runtime (see Concierge::Auth POD).
    my $auth_filename = $config->{auth}{file} || $auth_spec->{default_file};
    my %auth_args = defined $auth_filename
        ? ( file => File::Spec->catfile($auth_dir, $auth_filename) )
        : ();  # today's only 'pwd' setting; a future backend's required
               # keys would be read from $config->{auth}{$key} here instead

    # Validate every setting the chosen backend requires, failing the
    # build now rather than deferring to a runtime error later.
    for my $key (@{ $auth_spec->{required} }) {
        return { success => 0, message => "Missing auth.$key required for backend '$auth_backend_name'" }
            unless defined $auth_args{$key} && length $auth_args{$key};
    }

    # Resolve the sessions backend: same friendly-name-to-class
    # resolution as auth, via %SESSIONS_BACKENDS.
    my $sessions_backend_name = $config->{sessions}{backend}
        or return { success => 0, message => 'Missing sessions.backend' };
    my $sessions_spec = $SESSIONS_BACKENDS{lc $sessions_backend_name}
        or return { success => 0, message => "Unknown sessions.backend: $sessions_backend_name" };
    for my $key (@{ $sessions_spec->{required} }) {
        return { success => 0, message => "Missing sessions.$key required for backend '$sessions_backend_name'" }
            unless defined $config->{sessions}{$key} && length $config->{sessions}{$key};
    }

    # Resolve the users backend: same friendly-name-to-class
    # resolution as auth, via %USERS_BACKENDS.
    my $users_backend_name = $config->{users}{backend}
        or return { success => 0, message => 'Missing users.backend' };
    my $users_spec = $USERS_BACKENDS{lc $users_backend_name}
        or return { success => 0, message => "Unknown users.backend: $users_backend_name" };
    for my $key (@{ $users_spec->{required} }) {
        return { success => 0, message => "Missing users.$key required for backend '$users_backend_name'" }
            unless defined $config->{users}{$key} && length $config->{users}{$key};
    }

    # Create directories if needed
    for my $dir ($base_dir, $sessions_dir, $users_dir, $auth_dir) {
        next if -d $dir;
        eval { make_path($dir) };
        return {
            success => 0,
            message => "Failed to create directory '$dir': $@"
        } if $@;
    }

    # Create minimal Concierge object for internal operations
    my $concierge = bless {}, 'Concierge';

    # Initialize Sessions component with the resolved backend class
    $concierge->{sessions} = Concierge::Sessions->new(
        backend_class => $sessions_spec->{class},
        storage_dir   => $sessions_dir,
    );

    # Initialize Auth component
    unlink $auth_args{file} if $auth_args{file} && -f $auth_args{file};
    $concierge->{auth} = Concierge::Auth->new(
        backend_class => $auth_spec->{class},
        %auth_args,
    );

    # Build Users setup configuration
    my $users_config = {
        storage_dir   => $users_dir,
        backend_class => $users_spec->{class},
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

    # Initialize any additional components declared in config->{components}.
    # Unlike sessions/auth/users (hardcoded core affordances), these are
    # resolved once, here, at build time -- never recomputed at
    # open_desk()/runtime. Each entry's class is require()d and constructed
    # with a no-arg new() (build time is not the same call path as
    # open_desk()'s runtime new($payload)), then setup() is called with
    # its config block; the result is persisted verbatim as that
    # component's 'payload'. A setup() failure always fails the whole
    # build, regardless of 'optional' -- 'optional' only affects behavior
    # at open_desk() time.
    # Claims table for 'promote' collision detection, seeded from
    # names that are structurally known before any component is even
    # instantiated: every component's own bare-accessor name (its key
    # in the components config) and Concierge's real core methods.
    # Populated further, below, as each component's 'promote' entries
    # are validated.
    my %claimed = map { $_ => "component '$_' accessor" }
                  keys %{ $config->{components} // {} };
    for my $core (Concierge::core_methods()) {
        $claimed{$core} //= 'a core Concierge method';
    }

    my %components;
    for my $name (keys %{ $config->{components} // {} }) {
        my $entry = $config->{components}{$name};
        return { success => 0, message => "components.$name must be a hash reference" }
            unless ref $entry eq 'HASH';

        my $class = $entry->{class}
            or return { success => 0, message => "components.$name is missing required 'class'" };
        my $optional = $entry->{optional} ? 1 : 0;
        my $promote  = $entry->{promote};

        # Validate 'promote' shape and normalize into a list of
        # [$top_name, $method_name] pairs. This is build-time-only
        # validation -- open_desk() trusts the persisted result
        # completely and performs none of this itself.
        my @pairs;
        if (!defined $promote) {
            # no promotion for this component
        }
        elsif (ref $promote eq 'ARRAY') {
            for my $method_name (@$promote) {
                return {
                    success => 0,
                    message => "components.$name.promote array must contain only method-name strings"
                } unless defined $method_name && !ref($method_name) && length($method_name);
            }
            @pairs = map { [$_, $_] } @$promote;
        }
        elsif (ref $promote eq 'HASH') {
            for my $top_name (keys %$promote) {
                my $method_name = $promote->{$top_name};
                return {
                    success => 0,
                    message => "components.$name.promote hash must map top-level names to method-name strings"
                } unless defined $top_name && !ref($top_name) && length($top_name)
                      && defined $method_name && !ref($method_name) && length($method_name);
            }
            @pairs = map { [$_, $promote->{$_}] } keys %$promote;
        }
        else {
            return { success => 0, message => "components.$name.promote must be an arrayref or hashref" };
        }

        my $comp_dir = _resolve_dir($entry->{dir}, $base_dir);
        unless (-d $comp_dir) {
            eval { make_path($comp_dir) };
            return {
                success => 0,
                message => "Failed to create directory '$comp_dir' for component '$name': $@"
            } if $@;
        }

        my $comp;
        eval {
            (my $file = $class) =~ s{::}{/}g;
            require "$file.pm";
            $comp = $class->new();
        };
        return {
            success => 0,
            message => "Failed to build component '$name' ($class): $@"
        } if $@;

        my %setup_args = %$entry;
        delete $setup_args{class};
        delete $setup_args{optional};
        delete $setup_args{promote};
        $setup_args{dir}  = $comp_dir;
        $setup_args{name} = $name;

        my $setup_result = $comp->setup(\%setup_args);
        return $setup_result unless $setup_result->{success};

        # Validate 'promote' method-existence and name-collisions now
        # that $comp is a fully live, working instance (setup()
        # succeeded above). Sorted by top_name for deterministic
        # error messages.
        for my $pair (sort { $a->[0] cmp $b->[0] } @pairs) {
            my ($top_name, $method_name) = @$pair;

            return {
                success => 0,
                message => "components.$name.promote references unknown method "
                    . "'$method_name' on component '$name' ($class)"
            } unless $comp->can($method_name);

            if (exists $claimed{$top_name}) {
                return {
                    success => 0,
                    message => "Cannot promote '$method_name' from component '$name' as "
                        . "'$top_name': '$top_name' is already $claimed{$top_name}"
                };
            }
            $claimed{$top_name} = "promoted from component '$name' (method '$method_name')";
        }

        $components{$name} = {
            class    => $class,
            optional => $optional,
            payload  => $setup_result,
            (defined $promote ? (promote => $promote) : ()),
        };
    }

    # Build configuration to store in concierge session
    my $full_config = {
        users_config_file   => $users_setup->{config_file},
        storage_dir         => $base_dir,
        sessions_dir        => $sessions_dir,
        users_dir           => $users_dir,
        auth_dir            => $auth_dir,
        auth_backend        => $auth_spec->{class},
        auth_args           => \%auth_args,
        sessions_backend    => $sessions_spec->{class},
        users_backend       => $users_config->{backend_class},
        (%components ? (components => \%components) : ()),
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
    push @errors, "Missing base_dir"
        unless $config->{base_dir};

    push @errors, "Missing auth.backend"
        unless $config->{auth} && $config->{auth}{backend};

    push @errors, "Missing sessions.backend"
        unless $config->{sessions} && $config->{sessions}{backend};

    push @errors, "Missing users.backend"
        unless $config->{users} && $config->{users}{backend};

    # Validate backend values
    if ($config->{auth}{backend}) {
        my $spec = $AUTH_BACKENDS{lc $config->{auth}{backend}};
        if (!$spec) {
            push @errors, "Invalid auth.backend: '$config->{auth}{backend}'";
        } else {
            for my $key (@{ $spec->{required} }) {
                push @errors, "Missing auth.$key required for backend '$config->{auth}{backend}'"
                    unless defined $config->{auth}{$key} && length $config->{auth}{$key};
            }
        }
    }

    if ($config->{sessions}{backend}) {
        my $spec = $SESSIONS_BACKENDS{lc $config->{sessions}{backend}};
        if (!$spec) {
            push @errors, "Invalid sessions.backend: '$config->{sessions}{backend}'";
        } else {
            for my $key (@{ $spec->{required} }) {
                push @errors, "Missing sessions.$key required for backend '$config->{sessions}{backend}'"
                    unless defined $config->{sessions}{$key} && length $config->{sessions}{$key};
            }
        }
    }

    if ($config->{users}{backend}) {
        my $spec = $USERS_BACKENDS{lc $config->{users}{backend}};
        if (!$spec) {
            push @errors, "Invalid users.backend: '$config->{users}{backend}'";
        } else {
            for my $key (@{ $spec->{required} }) {
                push @errors, "Missing users.$key required for backend '$config->{users}{backend}'"
                    unless defined $config->{users}{$key} && length $config->{users}{$key};
            }
        }
    }

    return {
        success => @errors ? 0 : 1,
        (@errors ? (errors => \@errors) : ()),
    };
}

1;

__END__

=head1 NAME

Concierge::Desk::Setup - One-time desk creation and configuration for Concierge

=head1 VERSION

v0.11.0

=head1 SYNOPSIS

    use Concierge::Desk::Setup;

    # Simple setup -- database backends, all standard user fields
    my $result = Concierge::Desk::Setup::build_quick_desk(
        './desk',
        ['position', 'rbi'],     # application-specific user fields
    );

    # Advanced setup -- full control over backends and field configuration
    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => './desk',
        auth => {
            backend => 'pwd',
            dir     => 'auth',               # optional; default: base_dir.
                                              # Relative to base_dir here
                                              # ('./desk/auth'); an absolute
                                              # path would be used as-is.
            file    => 'auth.pwd',           # optional; a filename, not a path
        },
        sessions => {
            backend => 'database',  # or 'file'
            dir     => 'sessions',           # optional; default: base_dir
        },
        users => {
            backend                 => 'database',  # 'database', 'yaml', or 'file'
            dir                     => 'users',      # optional; default: base_dir
            include_standard_fields => [qw/email phone first_name last_name/],
            app_fields              => ['employee_id', 'department'],
            field_overrides         => [{ field_name => 'email', required => 1 }],
        },
    });

    # base_dir can also be any explicit path, not just './desk' -- the
    # './desk' conversion only kicks in for '.', './', or ''. Each
    # component's dir still resolves the same way: relative joins onto
    # whatever base_dir is, absolute escapes it entirely.
    my $result2 = Concierge::Desk::Setup::build_desk({
        base_dir => '/var/lib/myapp/desk',
        auth => {
            backend => 'pwd',
            dir     => '/Users/Shared/Tests',  # absolute -- lives outside
                                                # the desk entirely, e.g. for
                                                # a more restrictively
                                                # permissioned location
        },
        sessions => { backend => 'database' },
        users    => { backend => 'database', include_standard_fields => [] },
    });

=head1 DESCRIPTION

Concierge::Desk::Setup provides methods for one-time initialization of a
Concierge desk -- the storage directory containing configuration and data
files for the identity core components (Auth, Sessions, Users), and may
be used by added components as well.

Setup is separate from runtime operations.  Use this module once to
create a desk, then use L<Concierge/open_desk> at runtime.

The configuration structure passed to C<build_desk()> has one
top-level setting, C<base_dir> (the desk-wide storage root), plus a
block per component (C<auth>, C<sessions>, C<users>) for backend
selection and settings, including each component's own storage
location (C<dir>).  Applications that introduce additional components
under the C<Concierge::> namespace can extend this structure with
their own configuration blocks, following the same pattern.  See
L<Concierge/Architecture> for details.

=head2 The ./desk Convention

If C<$storage_dir> is C<'.'>, C<'./'>, or an empty string, it is
automatically converted to C<'./desk'> to avoid cluttering the
application root directory.

=head1 METHODS

=head2 build_quick_desk

    my $result = Concierge::Desk::Setup::build_quick_desk(
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

    my $result = Concierge::Desk::Setup::build_desk(\%config);

Creates a desk with full control over backend selection, storage layout,
and user field configuration.

B<Configuration structure:>

    {
        base_dir => $path,               # required; desk-wide storage root
        auth => {
            backend => 'pwd',            # required, no default -- see below
            dir     => $path,            # default: base_dir
            file    => $filename,        # default: 'auth.pwd' (backend-specific)
        },
        sessions => {
            backend => 'database',       # required, no default -- 'database' or 'file'
            dir     => $path,            # default: base_dir
        },
        users => {
            backend                 => 'database',  # required, no default -- 'database', 'yaml', or 'file'
            dir                     => $path,        # default: base_dir
            include_standard_fields => 'all',        # 'all' or \@field_names
            app_fields              => \@fields,     # custom fields
            field_overrides         => \@overrides,  # modify built-in fields
        },
    }

C<auth.backend>, C<sessions.backend>, and C<users.backend> are each a
friendly name resolved via that component's own internal backend
catalog (C<%AUTH_BACKENDS>, C<%SESSIONS_BACKENDS>, C<%USERS_BACKENDS>)
to a fully-qualified class -- e.g. C<auth.backend =E<gt> 'pwd'>
resolves to L<Concierge::Auth::Pwd>, C<sessions.backend =E<gt>
'database'> resolves to L<Concierge::Sessions::SQLite>, and
C<users.backend =E<gt> 'yaml'> resolves to L<Concierge::Users::YAML>.
None of the three has a default; each must be specified explicitly.
The resolved class is what actually gets passed down, as
C<backend_class>, to L<Concierge::Sessions/new> and
L<Concierge::Users/setup> (and, for auth, to L<Concierge::Auth/new>)
-- none of those modules ever guesses a class from a friendly name
themselves.

Each component's C<dir> controls I<where> that component's storage
lives (for C<auth>, e.g. C<'pwd'>'s password file) -- it defaults to
the top-level C<base_dir> but can point anywhere, independent of how
the rest of the desk is laid out. A relative C<dir> (e.g. C<'auth'> or
C<'./auth'>) is resolved I<against> C<base_dir>, so it moves along
with it; an absolute C<dir> (e.g. C<'/Users/Shared/Tests'>) is used
as-is, letting that component's storage live entirely outside the
rest of the desk (e.g. a more restrictively permissioned directory).
C<auth.file>, by contrast, is only ever a I<filename> (never a path)
naming the file within C<auth.dir> -- for C<'pwd'> it defaults to
C<auth.pwd>. This mirrors how storage location (each component's
C<dir>) and backend selection/settings (C<backend>, C<file>, etc.)
are kept as separate concerns within each component's own block.

Each catalog entry also lists the settings that backend requires;
today's built-in entries (C<'pwd'> for auth; C<'database'>/C<'file'>
for sessions; C<'database'>/C<'file'>/C<'yaml'> for users) all have
none, since their settings always resolve via computed defaults.
Adding support for another backend (e.g. hypothetical
C<Concierge::Auth::LDAP>, C<Concierge::Sessions::Redis>, or
C<Concierge::Users::Postgres>) is a one-entry addition to the relevant
internal catalog (C<%AUTH_BACKENDS>, C<%SESSIONS_BACKENDS>, or
C<%USERS_BACKENDS>), mapping a new friendly name to its class and
required settings (e.g. C<host>, C<bind_dn>, C<password> for an LDAP
auth backend); C<build_desk()> and C<validate_setup_config()> then
handle it automatically. C<class> is not required to live under the
C<Concierge::> namespace -- any installed module implementing the
relevant component's contract works (see L<Concierge::Auth>'s,
L<Concierge::Sessions>'s, or L<Concierge::Users>'s POD).

The C<users> block is where field configuration happens.  The sections
below describe the available fields and show how to customize them.

=head3 User Field Reference

Every user record draws from four field categories:

B<Core fields> (always present):

    user_id        system   Primary authentication identifier (max 30)
    moniker        moniker  Display name, nickname, or initials (max 24)
    user_status    enum     *Eligible, OK, Inactive (max 20)
    access_level   enum     *anon, visitor, member, staff, admin (max 20)

B<Standard fields> (selectable and configurable at setup):

    first_name     name     max 50
    middle_name    name     max 50
    last_name      name     max 50
    prefix         enum     (no default) Dr Mr Ms Mrs Mx Prof Hon Sir Madam
    suffix         enum     (no default) Jr Sr II III IV V PhD MD DDS Esq
    organization   text     max 100
    title          text     max 100
    email          email    max 255
    phone          phone    max 20
    text_ok        boolean
    term_ends      date

B<System fields> (auto-managed, always present):

    last_login_date system   Updated on every successful login
    last_mod_date   system   Updated on every write
    created_date    system   Set once on creation

B<Application fields> (optional, defined by the application):

    Custom fields the application adds via C<app_fields>; see
    L</Adding Application Fields> below.

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
all 11 standard fields, the same as C<'all'>.

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

=item C<format_as>

Optional hint for consuming applications (UI, CLI, report generators,
etc.) describing how to present or input this field.  Not used or
validated by Concierge.  See L</UI Formatting Hints> below.

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

=head3 UI Formatting Hints

The C<format_as> field attribute lets an application store
presentation instructions directly in the field definition and retrieve
them at runtime via C<get_field_hints()>.  Concierge does not use or
validate C<format_as>; it simply passes whatever value was supplied
straight through.

All built-in fields carry a C<format_as> value using Concierge
conventions (C<text>, C<options>, C<boolean>, C<number>, C<date>,
C<datetime>, C<time>).  Applications may override these on any standard
field via C<field_overrides>, or set any value on app-defined fields via
C<app_fields> -- including the application's own native format codes.

B<Example:> a template-based UI uses three input tokens: C<t> (text
input), C<b> (checkbox), C<sel> (select list).  Templates reference
fields by name and token:

    {{labeled_input=first_name,t}}
    {{labeled_input=last_name,t}}
    {{labeled_input=user_status,sel}}
    {{labeled_input=phone,t}}
    {{labeled_input=text_ok,b}}

Store the tokens in the field definitions at setup time:

    field_overrides => [
        { field_name => 'first_name',  format_as => 't'   },
        { field_name => 'last_name',   format_as => 't'   },
        { field_name => 'user_status', format_as => 'sel' },
        { field_name => 'phone',       format_as => 't'   },
        { field_name => 'text_ok',     format_as => 'b'   },
    ],

Retrieve them at runtime -- no translation table needed:

    for my $field (@{$users->get_user_fields()}) {
        my $hints = $users->get_field_hints($field);
        my $token = $hints->{format_as} or next;
        print "{{labeled_input=$field,$token}}\n";
    }

App-defined fields work the same way:

    app_fields => [
        {
            field_name => 'department',
            type       => 'enum',
            options    => ['*Engineering', 'Sales', 'Support'],
            format_as  => 'sel',
        },
    ],

The C<format_as> value set during setup is returned unchanged by
C<get_field_hints()>, making it a lightweight, zero-overhead channel
for passing application-specific formatting instructions through
Concierge without any involvement from the Concierge layer itself.

=head3 Complete Example

A community makerspace tracking members with custom fields, selective
standard fields, and modified built-in defaults:

    my $result = Concierge::Desk::Setup::build_desk({
        base_dir => './makerspace-desk',
        auth     => { backend => 'pwd' },
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
fields (C<email> now required), 4 application fields, and 3 system
fields -- 16 fields total.  The core C<user_status> field keeps its
usual role but uses makerspace-specific statuses (defaulting to
C<Applicant>).  New members default to the C<Community> tier (marked
with C<*>) and must provide a C<badge_name> that passes moniker
validation (2-24 alphanumeric characters).

=head3 Configuration Introspection

After building a desk, the field schema can be inspected at runtime
through L<Concierge::Users> (inherited from L<Concierge::Users::Meta>):

    # Before setup: retrieve built-in default field definitions
    my $default = Concierge::Users::Meta->show_default_config();
    print $default->{config} if $default->{success};

    # After setup: retrieve the active schema for this desk
    my $users = Concierge::Users->new('./makerspace-desk/users-config.json');
    my $cfg = $users->show_config();
    print $cfg->{config} if $cfg->{success};

    # Get UI-friendly hints for building forms dynamically
    my $hints = $users->get_field_hints('membership_tier');
    # Returns: { label, type, validate_as, options, max_length,
    #            description, required, default, null, format_as }

    # Get the ordered field list for this schema
    my $fields = $users->get_user_fields();

C<show_default_config()> returns a service hashref
C<< { success => 1, config => $yaml_string } >> containing the built-in
field template -- useful for reviewing available standard fields before
writing a setup script.  C<show_config()> returns
C<< { success => 1, config => $yaml_string, config_file => $path } >>
reflecting the actual schema including any overrides and application
fields.  C<get_field_hints()> returns a hashref of display-ready
attributes for a single field, suitable for generating form elements
programmatically.

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

    my $result = Concierge::Desk::Setup::validate_setup_config(\%config);

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
