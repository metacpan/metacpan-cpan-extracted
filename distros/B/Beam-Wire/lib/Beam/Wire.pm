package Beam::Wire;
our $VERSION = '1.021';
# ABSTRACT: Lightweight Dependency Injection Container

#pod =head1 SYNOPSIS
#pod
#pod     # wire.yml
#pod     captain:
#pod         class: Person
#pod         args:
#pod             name: Malcolm Reynolds
#pod             rank: Captain
#pod     first_officer:
#pod         $class: Person
#pod         name: Zoë Alleyne Washburne
#pod         rank: Commander
#pod
#pod     # script.pl
#pod     use Beam::Wire;
#pod     my $wire = Beam::Wire->new( file => 'wire.yml' );
#pod     my $captain = $wire->get( 'captain' );
#pod     print $captain->name; # "Malcolm Reynolds"
#pod
#pod =head1 DESCRIPTION
#pod
#pod Beam::Wire is a configuration module and a dependency injection
#pod container. In addition to complex data structures, Beam::Wire configures
#pod and creates plain old Perl objects.
#pod
#pod A dependency injection (DI) container creates an inversion of control:
#pod Instead of manually creating all the dependent objects (also called
#pod "services") before creating the main object that we actually want, a DI
#pod container handles that for us: We describe the relationships between
#pod objects, and the objects get built as needed.
#pod
#pod Dependency injection is sometimes called the opposite of garbage
#pod collection. Rather than ensure objects are destroyed in the right order,
#pod dependency injection makes sure objects are created in the right order.
#pod
#pod Using Beam::Wire in your application brings great flexibility,
#pod allowing users to easily add their own code to customize how your
#pod project behaves.
#pod
#pod For an L<introduction to the Beam::Wire service configuration format,
#pod see Beam::Wire::Help::Config|Beam::Wire::Help::Config>.
#pod
#pod =cut

use strict;
use warnings;

use Scalar::Util qw( blessed );
use Moo;
use Config::Any;
use Module::Runtime qw( use_module );
use Data::DPath qw ( dpath );
use Path::Tiny qw( path );
use File::Basename qw( dirname );
use Types::Standard qw( :all );
use Data::Dumper;
use constant DEBUG => $ENV{BEAM_WIRE_DEBUG};

#pod =attr file
#pod
#pod The path of the file where services are configured (typically a YAML
#pod file). The file's contents should be a single hashref. The keys are
#pod service names, and the values are L<service
#pod configurations|Beam::Wire::Help::Config>.
#pod
#pod =cut

has file => (
    is      => 'ro',
    isa     => InstanceOf['Path::Tiny'],
    coerce => sub {
        if ( !blessed $_[0] || !$_[0]->isa('Path::Tiny') ) {
            return path( $_[0] );
        }
        return $_[0];
    },
);

#pod =attr dir
#pod
#pod The directory path to use when searching for inner container files.
#pod Defaults to the directory which contains the file specified by the
#pod L<file attribute|/file>.
#pod
#pod =cut

has dir => (
    is      => 'ro',
    isa     => InstanceOf['Path::Tiny'],
    lazy    => 1,
    default => sub { $_[0]->file->parent },
    coerce => sub {
        if ( !blessed $_[0] || !$_[0]->isa('Path::Tiny') ) {
            return path( $_[0] );
        }
        return $_[0];
    },
);

#pod =attr config
#pod
#pod The raw configuration data. By default, this data is loaded by
#pod L<Config::Any|Config::Any> using the file specified by the L<file attribute|/file>.
#pod
#pod See L<Beam::Wire::Help::Config for details on what the configuration
#pod data structure looks like|Beam::Wire::Help::Config>.
#pod
#pod If you don't want to load a file, you can specify this attribute in the
#pod Beam::Wire constructor.
#pod
#pod =cut

has config => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => 1
);

sub _build_config {
    my ( $self ) = @_;
    return {} if ( !$self->file );
    return $self->_load_config( $self->file );
}

#pod =attr services
#pod
#pod A hashref of cached services built from the L<configuration|/config>. If
#pod you want to inject a pre-built object for other services to depend on,
#pod add it here.
#pod
#pod =cut

has services => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => 1,
);

sub _build_services {
    my ( $self ) = @_;
    my $services = {};
    return $services;
}

#pod =attr meta_prefix
#pod
#pod The character that begins a meta-property inside of a service's C<args>. This
#pod includes C<$ref>, C<$path>, C<$method>, and etc...
#pod
#pod The default value is C<$>. The empty string is allowed.
#pod
#pod =cut

has meta_prefix => (
    is      => 'ro',
    isa     => Str,
    default => sub { q{$} },
);

#pod =method get
#pod
#pod     my $service = $wire->get( $name );
#pod     my $service = $wire->get( $name, %overrides )
#pod
#pod The get method resolves and returns the service named C<$name>, creating
#pod it, if necessary, with L<the create_service method|/create_service>.
#pod
#pod C<%overrides> is an optional list of name-value pairs. If specified,
#pod get() will create an new, anonymous service that extends the named
#pod service with the given config overrides. For example:
#pod
#pod     # test.pl
#pod     use Beam::Wire;
#pod     my $wire = Beam::Wire->new(
#pod         config => {
#pod             foo => {
#pod                 args => {
#pod                     text => 'Hello, World!',
#pod                 },
#pod             },
#pod         },
#pod     );
#pod
#pod     my $foo = $wire->get( 'foo', args => { text => 'Hello, Chicago!' } );
#pod     print $foo; # prints "Hello, Chicago!"
#pod
#pod This allows you to create factories out of any service, overriding service
#pod configuration at run-time.
#pod
#pod If C<$name> contains a slash (C</>) character (e.g. C<foo/bar>), the left
#pod side (C<foo>) will be used as the name of an inner container, and the
#pod right side (C<bar>) is a service inside that container. For example,
#pod these two lines are equivalent:
#pod
#pod     $bar = $wire->get( 'foo/bar' );
#pod     $bar = $wire->get( 'foo' )->get( 'bar' );
#pod
#pod Inner containers can be nested as deeply as desired (C<foo/bar/baz/fuzz>).
#pod
#pod =cut

sub get {
    my ( $self, $name, %override ) = @_;

    ; print STDERR "Get service: $name\n" if DEBUG;

    if ( $name =~ q{/} ) {
        my ( $container_name, $service ) = split m{/}, $name, 2;
        return $self->get( $container_name )->get( $service, %override );
    }

    if ( keys %override ) {
        return $self->create_service( "\$anonymous extends $name", %override, extends => $name );
    }

    my $service = $self->services->{$name};
    if ( !$service ) {
        ; printf STDERR 'Service "%s" does not exist. Creating.' . "\n", $name if DEBUG;

        my $config_ref = $self->get_config($name);
        unless ( $config_ref ) {
            Beam::Wire::Exception::NotFound->throw(
                name => $name,
                file => $self->file,
            );
        }

        ; print STDERR "Got service config: " . Dumper $config_ref if DEBUG;

        if ( ref $config_ref eq 'HASH' && $self->is_meta( $config_ref, 1 ) ) {
            my %config  = %{ $self->normalize_config( $config_ref ) };
            $service = $self->create_service( $name, %config );
            if ( !$config{lifecycle} || lc $config{lifecycle} ne 'factory' ) {
                $self->services->{$name} = $service;
            }
        }
        else {
            $self->services->{$name} = $service = $self->find_refs( $name, $config_ref );
        }
    }

    ; print STDERR "Returning service: " . Dumper $service if DEBUG;

    return $service;
}

#pod =method set
#pod
#pod     $wire->set( $name => $service );
#pod
#pod The set method configures and stores the specified C<$service> with the
#pod specified C<$name>. Use this to add or replace built services.
#pod
#pod Like L<the get() method, above|/get>, C<$name> can contain a slash (C</>)
#pod character to traverse through nested containers.
#pod
#pod =cut

## no critic ( ProhibitAmbiguousNames )
# This was named set() before I started using Perl::Critic, and will
# continue to be named set() now that I no longer use Perl::Critic
sub set {
    my ( $self, $name, $service ) = @_;
    if ( $name =~ q{/} ) {
        my ( $container_name, $service_name ) = split m{/}, $name, 2;
        return $self->get( $container_name )->set( $service_name, $service );
    }
    $self->services->{$name} = $service;
    return;
}

#pod =method get_config
#pod
#pod     my $conf = $wire->get_config( $name );
#pod
#pod Get the config with the given C<$name>. Like L<the get() method,
#pod above|/get>, C<$name> can contain slash (C</>) characters to traverse
#pod through nested containers.
#pod
#pod =cut

sub get_config {
    my ( $self, $name ) = @_;
    if ( $name =~ q{/} ) {
        my ( $container_name, $service ) = split m{/}, $name, 2;
        my $inner_config = $self->get( $container_name )->get_config( $service );
        # Fix relative references to prefix the container name
        return { $self->fix_refs( $container_name, %{$inner_config} ) };
    }
    return $self->config->{$name};
}

#pod =method normalize_config
#pod
#pod     my $out_conf = $self->normalize_config( $in_conf );
#pod
#pod Normalize the given C<$in_conf> into to hash that L<the create_service
#pod method|/create_service> expects. This method allows a service to be
#pod defined with prefixed meta-names (C<$class> instead of C<class>) and
#pod the arguments specified without prefixes.
#pod
#pod For example, these two services are identical.
#pod
#pod     foo:
#pod         class: Foo
#pod         args:
#pod             fizz: buzz
#pod
#pod     foo:
#pod         $class: Foo
#pod         fizz: buzz
#pod
#pod The C<$in_conf> must be a hash, and must already pass L<an is_meta
#pod check|/is_meta>.
#pod
#pod =cut

sub normalize_config {
    my ( $self, $conf ) = @_;

    ; print STDERR "In conf: " . Dumper $conf if DEBUG;

    my %meta = reverse $self->get_meta_names;

    # Confs without prefixed keys can be used as-is
    return $conf if !grep { $meta{ $_ } } keys %$conf;

    my %out_conf;
    for my $key ( keys %$conf ) {
        if ( $meta{ $key } ) {
            $out_conf{ $meta{ $key } } = $conf->{ $key };
        }
        else {
            $out_conf{ args }{ $key } = $conf->{ $key };
        }
    }

    ; print STDERR "Out conf: " . Dumper \%out_conf if DEBUG;

    return \%out_conf;
}

#pod =method create_service
#pod
#pod     my $service = $wire->create_service( $name, %config );
#pod
#pod Create the service with the given C<$name> and C<%config>. Config can
#pod contain the following keys:
#pod
#pod =over 4
#pod
#pod =item class
#pod
#pod The class name of an object to create. Can be combined with C<method>,
#pod and C<args>. An object of any class can be created with Beam::Wire.
#pod
#pod =item args
#pod
#pod The arguments to the constructor method. Used with C<class> and
#pod C<method>. Can be a simple value, or a reference to an array or
#pod hash which will be dereferenced and passed in to the constructor
#pod as a list.
#pod
#pod If the C<class> consumes the L<Beam::Service role|Beam::Service>,
#pod the service's C<name> and C<container> will be added to the C<args>.
#pod
#pod =item method
#pod
#pod The method to call to create the object. Only used with C<class>.
#pod Defaults to C<"new">.
#pod
#pod This can also be an array of hashes which describe a list of methods
#pod that will be called on the object. The first method should create the
#pod object, and each subsequent method can be used to modify the object. The
#pod hashes should contain a C<method> key, which is a string containing the
#pod method to call, and optionally C<args> and C<return> keys. The C<args>
#pod key works like the top-level C<args> key, above. The optional C<return>
#pod key can have the special value C<"chain">, which will use the return
#pod value from the method as the value for the service (L<The tutorial shows
#pod examples of this|Beam::Wire::Help::Config/Multiple Constructor
#pod Methods>).
#pod
#pod If an array is used, the top-level C<args> key is not used.
#pod
#pod =item value
#pod
#pod The value of this service. Can be a simple value, or a reference to an
#pod array or hash. This value will be simply returned by this method, and is
#pod mostly useful when using container files.
#pod
#pod C<value> can not be used with C<class> or C<extends>.
#pod
#pod =item config
#pod
#pod The path to a configuration file, relative to L<the dir attribute|/dir>.
#pod The file will be read with L<Config::Any>, and the resulting data
#pod structure returned.
#pod
#pod =item extends
#pod
#pod The name of a service to extend. The named service's configuration will
#pod be merged with this configuration (via L<the merge_config
#pod method|/merge_config>).
#pod
#pod This can be used in place of the C<class> key if the extended configuration
#pod contains a class.
#pod
#pod =item with
#pod
#pod Compose a role into the object's class before creating the object. This
#pod can be a single string, or an array reference of strings which are roles
#pod to combine.
#pod
#pod This uses L<Moo::Role|Moo::Role> and L<the create_class_with_roles
#pod method|Role::Tiny/create_class_with_roles>, which should work with any
#pod class (as it uses L<the Role::Tiny module|Role::Tiny> under the hood).
#pod
#pod This can be used with the C<class> key.
#pod
#pod =item on
#pod
#pod Attach an event handler to a L<Beam::Emitter subclass|Beam::Emitter>. This
#pod is an array of hashes of event names and handlers. A handler is made from
#pod a service reference (C<$ref> or an anonymous service), and a subroutine to
#pod call on that service (C<$sub>).
#pod
#pod For example:
#pod
#pod     emitter:
#pod         class: My::Emitter
#pod         on:
#pod             - my_event:
#pod                 $ref: my_handler
#pod                 $sub: on_my_event
#pod
#pod This can be used with the C<class> key.
#pod
#pod =back
#pod
#pod This method uses L<the parse_args method|/parse_args> to parse the C<args> key,
#pod L<resolving references|resolve_ref> as needed.
#pod
#pod =cut

sub create_service {
    my ( $self, $name, %service_info ) = @_;

    ; print STDERR "Creating service: " . Dumper \%service_info if DEBUG;

    # Compose the parent ref into the copy, in case the parent changes
    %service_info = $self->merge_config( %service_info );

    # value and class/extends are mutually exclusive
    # must check after merge_config in case parent config has class/value
    if ( exists $service_info{value} && (
            exists $service_info{class} || exists $service_info{extends}
        )
    ) {
        Beam::Wire::Exception::InvalidConfig->throw(
            name => $name,
            file => $self->file,
            error => '"value" cannot be used with "class" or "extends"',
        );
    }
    if ( $service_info{value} ) {
        return $service_info{value};
    }

    if ( $service_info{config} ) {
        my $conf_path = path( $service_info{config} );
        if ( $self->file ) {
            $conf_path = path( $self->file )->parent->child( $conf_path );
        }
        return $self->_load_config( "$conf_path" );
    }

    if ( !$service_info{class} ) {
        Beam::Wire::Exception::InvalidConfig->throw(
            name => $name,
            file => $self->file,
            error => 'Service configuration incomplete. Missing one of "class", "value", "config"',
        );
    }

    use_module( $service_info{class} );

    if ( my $with = $service_info{with} ) {
        my @roles = ref $with ? @{ $with } : ( $with );
        my $class = Moo::Role->create_class_with_roles( $service_info{class}, @roles );
        $service_info{class} = $class;
    }

    my $method = $service_info{method} || "new";
    my $service;
    if ( ref $method eq 'ARRAY' ) {
        for my $m ( @{$method} ) {
            my $method_name = $m->{method};
            my $return = $m->{return} || q{};
            delete $service_info{args};
            my @args = $self->parse_args( $name, $service_info{class}, $m->{args} );
            my $invocant = $service || $service_info{class};
            my $output = $invocant->$method_name( @args );
            $service = !$service || $return eq 'chain' ? $output
                     : $service;
        }
    }
    else {
        my @args = $self->parse_args( $name, @service_info{"class","args"} );
        if ( $service_info{class}->can( 'DOES' ) && $service_info{class}->DOES( 'Beam::Service' ) ) {
            push @args, name => $name, container => $self;
        }
        $service = $service_info{class}->$method( @args );
    }

    if ( $service_info{on} ) {
        my %meta = $self->get_meta_names;
        my @listeners;

        if ( ref $service_info{on} eq 'ARRAY' ) {
            @listeners = map { [ %$_ ] } @{ $service_info{on} };
        }
        elsif ( ref $service_info{on} eq 'HASH' ) {
            for my $event ( keys %{ $service_info{on} } ) {
                if ( ref $service_info{on}{$event} eq 'ARRAY' ) {
                    push @listeners,
                        map {; [ $event => $_ ] }
                        @{ $service_info{on}{$event} };
                }
                else {
                    push @listeners, [ $event => $service_info{on}{$event} ];
                }
            }
        }

        for my $listener ( @listeners ) {
            my ( $event, $conf ) = @$listener;
            if ( $conf->{ $meta{method} } && !$conf->{ $meta{sub} } ) {
                _deprecated( 'warning: (deprecated) "$method" in event handlers is now "$sub" in service "' . $name . '"' );
            }
            my $sub_name = delete $conf->{ $meta{sub} } || delete $conf->{ $meta{method} };
            my ( $listen_svc ) = $self->find_refs( $name, $conf );
            $service->on( $event => sub { $listen_svc->$sub_name( @_ ) } );
        }
    }

    return $service;
}

#pod =method merge_config
#pod
#pod     my %merged = $wire->merge_config( %config );
#pod
#pod If C<%config> contains an C<extends> key, merge the extended config together
#pod with this one, returning the merged service configuration. This works recursively,
#pod so a service can extend a service that extends another service just fine.
#pod
#pod When merging, hashes are combined, with the child configuration taking
#pod precedence. The C<args> key is handled specially to allow a hash of
#pod args to be merged.
#pod
#pod The configuration returned is a safe copy and can be modified without
#pod effecting the original config.
#pod
#pod =cut

sub merge_config {
    my ( $self, %service_info ) = @_;
    if ( $service_info{ extends } ) {
        my $base_config_ref = $self->get_config( $service_info{extends} );
        unless ( $base_config_ref ) { 
            Beam::Wire::Exception::NotFound->throw(
                name => $service_info{extends},
                file => $self->file,
            );
        }
        my %base_config = %{ $self->normalize_config( $base_config_ref ) };
        # Merge the args separately, to be a bit nicer about hashes of arguments
        my $args;
        if ( ref $service_info{args} eq 'HASH' && ref $base_config{args} eq 'HASH' ) {
            $args = { %{ delete $base_config{args} }, %{ delete $service_info{args} } };
        }
        %service_info = ( $self->merge_config( %base_config ), %service_info );
        if ( $args ) {
            $service_info{args} = $args;
        }
    }
    return %service_info;
}

#pod =method parse_args
#pod
#pod     my @args = $wire->parse_args( $for_name, $class, $args );
#pod
#pod Parse the arguments (C<$args>) for the given service (C<$for_name>) with
#pod the given class (C<$class>).
#pod
#pod C<$args> can be an array reference, a hash reference, or a simple
#pod scalar. The arguments will be searched for references using L<the
#pod find_refs method|/find_refs>, and then a list of arguments will be
#pod returned, ready to pass to the object's constructor.
#pod
#pod Nested containers are handled specially by this method: Their inner
#pod references are not resolved by the parent container. This ensures that
#pod references are always relative to the container they're in.
#pod
#pod =cut

sub parse_args {
    my ( $self, $for, $class, $args ) = @_;
    return if not $args;
    my @args;
    if ( ref $args eq 'ARRAY' ) {
        @args = $self->find_refs( $for, @{$args} );
    }
    elsif ( ref $args eq 'HASH' ) {
        # Hash args could be a ref
        # Subcontainers cannot scan for refs in their configs
        if ( $class->isa( 'Beam::Wire' ) ) {
            my %args = %{$args};
            my $config = delete $args{config};
            # Relative subcontainer files should be from the current
            # container's directory
            if ( exists $args{file} && !path( $args{file} )->is_absolute ) {
                $args{file} = $self->dir->child( $args{file} );
            }
            @args = $self->find_refs( $for, %args );
            if ( $config ) {
                push @args, config => $config;
            }
        }
        else {
            my ( $maybe_ref ) = $self->find_refs( $for, $args );
            if ( blessed $maybe_ref ) {
                @args = ( $maybe_ref );
            }
            else {
                @args   = ref $maybe_ref eq 'HASH' ? %$maybe_ref
                        : ref $maybe_ref eq 'ARRAY' ? @$maybe_ref
                        : ( $maybe_ref );
            }
        }
    }
    else {
        # Try anyway?
        @args = $args;
    }

    return @args;
}

#pod =method find_refs
#pod
#pod     my @resolved = $wire->find_refs( $for_name, @args );
#pod
#pod Go through the C<@args> and recursively resolve any references and
#pod services found inside, returning the resolved result. References are
#pod identified with L<the is_meta method|/is_meta>.
#pod
#pod If a reference contains a C<$ref> key, it will be resolved by L<the
#pod resolve_ref method|/resolve_ref>. Otherwise, the reference will be
#pod treated as an anonymous service, and passed directly to L<the
#pod create_service method|/create_service>.
#pod
#pod This is used when L<creating a service|create_service> to ensure all
#pod dependencies are created first.
#pod
#pod =cut

sub find_refs {
    my ( $self, $for, @args ) = @_;

    ; printf STDERR qq{Searching for refs for "%s": %s}, $for, Dumper \@args if DEBUG;

    my @out;
    my %meta = $self->get_meta_names;
    for my $arg ( @args ) {
        if ( ref $arg eq 'HASH' ) {
            if ( $self->is_meta( $arg ) ) {
                if ( $arg->{ $meta{ ref } } ) {
                    push @out, $self->resolve_ref( $for, $arg );
                }
                else { # Try to treat it as a service to create
                    ; print STDERR "Creating anonymous service: " . Dumper $arg if DEBUG;

                    my %service_info = %{ $self->normalize_config( $arg ) };
                    push @out, $self->create_service( '$anonymous', %service_info );
                }
            }
            else {
                push @out, { $self->find_refs( $for, %{$arg} ) };
            }
        }
        elsif ( ref $arg eq 'ARRAY' ) {
            push @out, [ map { $self->find_refs( $for, $_ ) } @{$arg} ];
        }
        else {
            push @out, $arg; # simple scalars
        }
    }

    # In case we only pass in one argument and want one return value
    return wantarray ? @out : $out[-1];
}

#pod =method is_meta
#pod
#pod     my $is_meta = $wire->is_meta( $ref_hash, $root );
#pod
#pod Returns true if the given hash reference describes some kind of
#pod Beam::Wire service. This is used to identify service configuration
#pod hashes inside of larger data structures.
#pod
#pod A service hash reference must contain at least one key, and must either
#pod contain a L<prefixed|/meta_prefix> key that could create or reference an
#pod object (one of C<class>, C<extends>, C<config>, C<value>, or C<ref>) or,
#pod if the C<$root> flag exists, be made completely of unprefixed meta keys
#pod (as returned by L<the get_meta_names method|/get_meta_names>).
#pod
#pod The C<$root> flag is used by L<the get method|/get> to allow unprefixed
#pod meta keys in the top-level hash values.
#pod
#pod =cut

sub is_meta {
    my ( $self, $arg, $root ) = @_;

    # Only a hashref can be meta
    return unless ref $arg eq 'HASH';

    my @keys = keys %$arg;
    return unless @keys;

    my %meta = $self->get_meta_names;
    my %meta_names = map { $_ => 1 } values %meta;

    # A regular service does not need the prefix, but must consist
    # only of meta keys
    return 1 if $root && scalar @keys eq grep { $meta{ $_ } } @keys;

    # A meta service contains at least one of these keys, as these are
    # the keys that can create a service. All other keys are
    # modifiers
    return 1
        if grep { exists $arg->{ $_ } }
            map { $meta{ $_ } }
            qw( ref class extends config value );

    # Must not be meta
    return;
}

#pod =method get_meta_names
#pod
#pod     my %meta_keys = $wire->get_meta_names;
#pod
#pod Get all the possible service keys with the L<meta prefix|/meta_prefix> already
#pod attached.
#pod
#pod =cut

sub get_meta_names {
    my ( $self ) = @_;
    my $prefix = $self->meta_prefix;
    my %meta = (
        ref         => "${prefix}ref",
        path        => "${prefix}path",
        method      => "${prefix}method",
        args        => "${prefix}args",
        class       => "${prefix}class",
        extends     => "${prefix}extends",
        sub         => "${prefix}sub",
        call        => "${prefix}call",
        lifecycle   => "${prefix}lifecycle",
        on          => "${prefix}on",
        with        => "${prefix}with",
        value       => "${prefix}value",
        config      => "${prefix}config",
    );
    return wantarray ? %meta : \%meta;
}

#pod =method resolve_ref
#pod
#pod     my @value = $wire->resolve_ref( $for_name, $ref_hash );
#pod
#pod Resolves the given dependency from the configuration hash (C<$ref_hash>)
#pod for the named service (C<$for_name>). Reference hashes contain the
#pod following keys:
#pod
#pod =over 4
#pod
#pod =item $ref
#pod
#pod The name of a service in the container. Required.
#pod
#pod =item $path
#pod
#pod A data path to pick some data out of the reference. Useful with C<value>
#pod and C<config> services.
#pod
#pod     # container.yml
#pod     bounties:
#pod         value:
#pod             malcolm: 50000
#pod             zoe: 35000
#pod             simon: 100000
#pod
#pod     captain:
#pod         class: Person
#pod         args:
#pod             name: Malcolm Reynolds
#pod             bounty:
#pod                 $ref: bounties
#pod                 $path: /malcolm
#pod
#pod =item $call
#pod
#pod Call a method on the referenced object and use the resulting value. This
#pod may be a string, which will be the method name to call, or a hash with
#pod C<$method> and C<$args>, which are the method name to call and the
#pod arguments to that method, respectively.
#pod
#pod     captain:
#pod         class: Person
#pod         args:
#pod             name: Malcolm Reynolds
#pod             location:
#pod                 $ref: beacon
#pod                 $call: get_location
#pod             bounty:
#pod                 $ref: news
#pod                 $call:
#pod                     $method: get_bounty
#pod                     $args:
#pod                         name: mreynolds
#pod
#pod =back
#pod
#pod =cut

sub resolve_ref {
    my ( $self, $for, $arg ) = @_;

    my %meta = $self->get_meta_names;

    my @ref;
    my $name = $arg->{ $meta{ref} };
    my $service = $self->get( $name );
    # resolve service ref w/path
    if ( my $path = $arg->{ $meta{path} } ) {
        # locate foreign service data
        my $conf = $self->get_config($name);
        @ref = dpath( $path )->match($service);
    }
    elsif ( my $call = $arg->{ $meta{call} } ) {
        my ( $method, @args );

        if ( ref $call eq 'HASH' ) {
            $method = $call->{ $meta{method} };
            my $args = $call->{ $meta{args} };
            @args = !$args ? ()
                  : ref $args eq 'ARRAY'  ? @{ $args }
                  : $args;
        }
        else {
            $method = $call;
        }

        @ref = $service->$method( @args );
    }
    elsif ( my $method = $arg->{ $meta{method} } ) {
        _deprecated( 'warning: (deprecated) Using "$method" to get a value in a dependency is now "$call" in service "' . $for . '"' );
        my $args = $arg->{ $meta{args} };
        my @args = !$args                ? ()
                 : ref $args eq 'ARRAY'  ? @{ $args }
                 : $args;
        @ref = $service->$method( @args );
    }
    else {
        @ref = $service;
    }

    return @ref;
}

#pod =method fix_refs
#pod
#pod     my @fixed = $wire->fix_refs( $for_name, @args );
#pod
#pod Similar to L<the find_refs method|/find_refs>. This method searches
#pod through the C<@args> and recursively fixes any reference paths to be
#pod absolute. References are identified with L<the is_meta
#pod method|/is_meta>.
#pod
#pod This is used by L<the get_config method|/get_config> to ensure that the
#pod configuration can be passed directly in to L<the create_service
#pod method|create_service>.
#pod
#pod =cut

sub fix_refs {
    my ( $self, $container_name, @args ) = @_;
    my @out;
    my %meta = $self->get_meta_names;
    for my $arg ( @args ) {
        if ( ref $arg eq 'HASH' ) {
            if ( $self->is_meta( $arg ) ) {
                my %new = ();
                for my $key ( @meta{qw( ref extends )} ) {
                    if ( $arg->{$key} ) {
                        $new{ $key } = join( q{/}, $container_name, $arg->{$key} );
                    }
                }
                push @out, \%new;
            }
            else {
                push @out, { $self->fix_refs( $container_name, %{$arg} ) };
            }
        }
        elsif ( ref $arg eq 'ARRAY' ) {
            push @out, [ map { $self->fix_refs( $container_name, $_ ) } @{$arg} ];
        }
        else {
            push @out, $arg; # simple scalars
        }
    }
    return @out;
}


#pod =method new
#pod
#pod     my $wire = Beam::Wire->new( %attributes );
#pod
#pod Create a new container.
#pod
#pod =cut

sub BUILD {
    my ( $self ) = @_;

    if ( $self->file && !path( $self->file )->exists ) {
        my $file = $self->file;
        Beam::Wire::Exception::Constructor->throw(
            attr => 'file',
            error => qq{Container file '$file' does not exist},
        );
    }

    # Create all the eager services
    my %meta = $self->get_meta_names;
    for my $key ( keys %{ $self->config } ) {
        my $config = $self->config->{$key};
        if ( ref $config eq 'HASH' ) {
            my $lifecycle = $config->{lifecycle} || $config->{ $meta{lifecycle} };
            if ( $lifecycle && $lifecycle eq 'eager' ) {
                $self->get($key);
            }
        }
    }
    return;
}

my %deprecated_warnings;
sub _deprecated {
    my ( $warning ) = @_;
    return if $deprecated_warnings{ $warning };
    warn $deprecated_warnings{ $warning } = $warning . "\n";
}

# Load a config file
sub _load_config {
    my ( $self, $path ) = @_;
    local $Config::Any::YAML::NO_YAML_XS_WARNING = 1;

    my $loader;
    eval {
        $loader = Config::Any->load_files( {
            files  => [$path], use_ext => 1, flatten_to_hash => 1
        } );
    };
    if ( $@ ) {
        Beam::Wire::Exception::Config->throw(
            file => $self->file,
            config_error => $@,
        );
    }

   return "HASH" eq ref $loader ? (values(%{$loader}))[0] : {};
}

# Check config file for known issues and report
# Optionally attempt to get all configured items for complete test
# Intended for use with beam-wire script
sub validate {
    my $error_count = 0;
    my @valid_dependency_nodes = qw( class method args extends lifecycle on config );
    my ( $self, $instantiate, $show_all_errors ) = @_;

    while ( my ( $name, $v ) = each %{ $self->{config} } ) {

        if ($instantiate) {
            if ($show_all_errors) {
                eval {
                    $self->get($name);
                };
                print $@ if $@;
            }
            else {
                $self->get($name);
            }
            next;
        };

        my %config = %{ $self->get_config($name) };
        %config = $self->merge_config(%config);

        if ( exists $config{value} && ( exists $config{class} || exists $config{extends})) {
            $error_count++;
            if ($show_all_errors) {
                print qq(Invalid config for service '$name': "value" cannot be used with "class" or "extends"\n);
                next;
            }

            Beam::Wire::Exception::InvalidConfig->throw(
                name => $name,
                file => $self->file,
                error => '"value" cannot be used with "class" or "extends"',
            );
        }

        if ( $config{config} ) {
            my $conf_path = path( $config{config} );
            if ( $self->file ) {
                $conf_path = path( $self->file )->parent->child($conf_path);
            }
            %config = %{ $self->_load_config("$conf_path") };
        }

        unless ( $config{value} || $config{class} || $config{extends} ) {
            next;
        }

        if ($config{class}) {
            eval "require " . $config{class} if $config{class};
        }
        #TODO: check method chain & serial
    }
    return $error_count;
}

#pod =head1 EXCEPTIONS
#pod
#pod If there is an error internal to Beam::Wire, an exception will be thrown. If there is an
#pod error with creating a service or calling a method, the exception thrown will be passed-
#pod through unaltered.
#pod
#pod =head2 Beam::Wire::Exception
#pod
#pod The base exception class
#pod
#pod =cut

package Beam::Wire::Exception;
use Moo;
with 'Throwable';
use Types::Standard qw( :all );
use overload q{""} => sub { $_[0]->error };

has error => (
    is => 'ro',
    isa => Str,
);

#pod =head2 Beam::Wire::Exception::Constructor
#pod
#pod An exception creating a Beam::Wire object
#pod
#pod =cut

package Beam::Wire::Exception::Constructor;
use Moo;
use Types::Standard qw( :all );
extends 'Beam::Wire::Exception';

has attr => (
    is => 'ro',
    isa => Str,
    required => 1,
);

#pod =head2 Beam::Wire::Exception::Config
#pod
#pod An exception loading the configuration file.
#pod
#pod =cut

package Beam::Wire::Exception::Config;
use Moo;
use Types::Standard qw( :all );
extends 'Beam::Wire::Exception';

has file => (
    is          => 'ro',
    isa         => Maybe[InstanceOf['Path::Tiny']],
);

has config_error => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has '+error' => (
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        return sprintf 'Could not load container file "%s": Error from config parser: %s',
            $self->file,
            $self->config_error;
    },
);

#pod =head2 Beam::Wire::Exception::Service
#pod
#pod An exception with service information inside
#pod
#pod =cut

package Beam::Wire::Exception::Service;
use Moo;
use Types::Standard qw( :all );
extends 'Beam::Wire::Exception';

has name => (
    is          => 'ro',
    isa         => Str,
    required    => 1,
);

has file => (
    is          => 'ro',
    isa         => Maybe[InstanceOf['Path::Tiny']],
);

#pod =head2 Beam::Wire::Exception::NotFound
#pod
#pod The requested service or configuration was not found.
#pod
#pod =cut

package Beam::Wire::Exception::NotFound;
use Moo;
extends 'Beam::Wire::Exception::Service';

has '+error' => (
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        my $name = $self->name;
        my $file = $self->file;
        return "Service '$name' not found" . ( $file ? " in file '$file'" : '' );
    },
);

#pod =head2 Beam::Wire::Exception::InvalidConfig
#pod
#pod The configuration is invalid:
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod Both "value" and "class" or "extends" are defined. These are mutually-exclusive.
#pod
#pod =back
#pod
#pod =cut

package Beam::Wire::Exception::InvalidConfig;
use Moo;
extends 'Beam::Wire::Exception::Service';
use overload q{""} => sub {
    my ( $self ) = @_;
    my $file = $self->file;

    sprintf "Invalid config for service '%s': %s%s",
        $self->name,
        $self->error,
        ( $file ? " in file '$file'" : "" ),
        ;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Beam::Wire - Lightweight Dependency Injection Container

=head1 VERSION

version 1.021

=head1 SYNOPSIS

    # wire.yml
    captain:
        class: Person
        args:
            name: Malcolm Reynolds
            rank: Captain
    first_officer:
        $class: Person
        name: Zoë Alleyne Washburne
        rank: Commander

    # script.pl
    use Beam::Wire;
    my $wire = Beam::Wire->new( file => 'wire.yml' );
    my $captain = $wire->get( 'captain' );
    print $captain->name; # "Malcolm Reynolds"

=head1 DESCRIPTION

Beam::Wire is a configuration module and a dependency injection
container. In addition to complex data structures, Beam::Wire configures
and creates plain old Perl objects.

A dependency injection (DI) container creates an inversion of control:
Instead of manually creating all the dependent objects (also called
"services") before creating the main object that we actually want, a DI
container handles that for us: We describe the relationships between
objects, and the objects get built as needed.

Dependency injection is sometimes called the opposite of garbage
collection. Rather than ensure objects are destroyed in the right order,
dependency injection makes sure objects are created in the right order.

Using Beam::Wire in your application brings great flexibility,
allowing users to easily add their own code to customize how your
project behaves.

For an L<introduction to the Beam::Wire service configuration format,
see Beam::Wire::Help::Config|Beam::Wire::Help::Config>.

=head1 ATTRIBUTES

=head2 file

The path of the file where services are configured (typically a YAML
file). The file's contents should be a single hashref. The keys are
service names, and the values are L<service
configurations|Beam::Wire::Help::Config>.

=head2 dir

The directory path to use when searching for inner container files.
Defaults to the directory which contains the file specified by the
L<file attribute|/file>.

=head2 config

The raw configuration data. By default, this data is loaded by
L<Config::Any|Config::Any> using the file specified by the L<file attribute|/file>.

See L<Beam::Wire::Help::Config for details on what the configuration
data structure looks like|Beam::Wire::Help::Config>.

If you don't want to load a file, you can specify this attribute in the
Beam::Wire constructor.

=head2 services

A hashref of cached services built from the L<configuration|/config>. If
you want to inject a pre-built object for other services to depend on,
add it here.

=head2 meta_prefix

The character that begins a meta-property inside of a service's C<args>. This
includes C<$ref>, C<$path>, C<$method>, and etc...

The default value is C<$>. The empty string is allowed.

=head1 METHODS

=head2 get

    my $service = $wire->get( $name );
    my $service = $wire->get( $name, %overrides )

The get method resolves and returns the service named C<$name>, creating
it, if necessary, with L<the create_service method|/create_service>.

C<%overrides> is an optional list of name-value pairs. If specified,
get() will create an new, anonymous service that extends the named
service with the given config overrides. For example:

    # test.pl
    use Beam::Wire;
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                args => {
                    text => 'Hello, World!',
                },
            },
        },
    );

    my $foo = $wire->get( 'foo', args => { text => 'Hello, Chicago!' } );
    print $foo; # prints "Hello, Chicago!"

This allows you to create factories out of any service, overriding service
configuration at run-time.

If C<$name> contains a slash (C</>) character (e.g. C<foo/bar>), the left
side (C<foo>) will be used as the name of an inner container, and the
right side (C<bar>) is a service inside that container. For example,
these two lines are equivalent:

    $bar = $wire->get( 'foo/bar' );
    $bar = $wire->get( 'foo' )->get( 'bar' );

Inner containers can be nested as deeply as desired (C<foo/bar/baz/fuzz>).

=head2 set

    $wire->set( $name => $service );

The set method configures and stores the specified C<$service> with the
specified C<$name>. Use this to add or replace built services.

Like L<the get() method, above|/get>, C<$name> can contain a slash (C</>)
character to traverse through nested containers.

=head2 get_config

    my $conf = $wire->get_config( $name );

Get the config with the given C<$name>. Like L<the get() method,
above|/get>, C<$name> can contain slash (C</>) characters to traverse
through nested containers.

=head2 normalize_config

    my $out_conf = $self->normalize_config( $in_conf );

Normalize the given C<$in_conf> into to hash that L<the create_service
method|/create_service> expects. This method allows a service to be
defined with prefixed meta-names (C<$class> instead of C<class>) and
the arguments specified without prefixes.

For example, these two services are identical.

    foo:
        class: Foo
        args:
            fizz: buzz

    foo:
        $class: Foo
        fizz: buzz

The C<$in_conf> must be a hash, and must already pass L<an is_meta
check|/is_meta>.

=head2 create_service

    my $service = $wire->create_service( $name, %config );

Create the service with the given C<$name> and C<%config>. Config can
contain the following keys:

=over 4

=item class

The class name of an object to create. Can be combined with C<method>,
and C<args>. An object of any class can be created with Beam::Wire.

=item args

The arguments to the constructor method. Used with C<class> and
C<method>. Can be a simple value, or a reference to an array or
hash which will be dereferenced and passed in to the constructor
as a list.

If the C<class> consumes the L<Beam::Service role|Beam::Service>,
the service's C<name> and C<container> will be added to the C<args>.

=item method

The method to call to create the object. Only used with C<class>.
Defaults to C<"new">.

This can also be an array of hashes which describe a list of methods
that will be called on the object. The first method should create the
object, and each subsequent method can be used to modify the object. The
hashes should contain a C<method> key, which is a string containing the
method to call, and optionally C<args> and C<return> keys. The C<args>
key works like the top-level C<args> key, above. The optional C<return>
key can have the special value C<"chain">, which will use the return
value from the method as the value for the service (L<The tutorial shows
examples of this|Beam::Wire::Help::Config/Multiple Constructor
Methods>).

If an array is used, the top-level C<args> key is not used.

=item value

The value of this service. Can be a simple value, or a reference to an
array or hash. This value will be simply returned by this method, and is
mostly useful when using container files.

C<value> can not be used with C<class> or C<extends>.

=item config

The path to a configuration file, relative to L<the dir attribute|/dir>.
The file will be read with L<Config::Any>, and the resulting data
structure returned.

=item extends

The name of a service to extend. The named service's configuration will
be merged with this configuration (via L<the merge_config
method|/merge_config>).

This can be used in place of the C<class> key if the extended configuration
contains a class.

=item with

Compose a role into the object's class before creating the object. This
can be a single string, or an array reference of strings which are roles
to combine.

This uses L<Moo::Role|Moo::Role> and L<the create_class_with_roles
method|Role::Tiny/create_class_with_roles>, which should work with any
class (as it uses L<the Role::Tiny module|Role::Tiny> under the hood).

This can be used with the C<class> key.

=item on

Attach an event handler to a L<Beam::Emitter subclass|Beam::Emitter>. This
is an array of hashes of event names and handlers. A handler is made from
a service reference (C<$ref> or an anonymous service), and a subroutine to
call on that service (C<$sub>).

For example:

    emitter:
        class: My::Emitter
        on:
            - my_event:
                $ref: my_handler
                $sub: on_my_event

This can be used with the C<class> key.

=back

This method uses L<the parse_args method|/parse_args> to parse the C<args> key,
L<resolving references|resolve_ref> as needed.

=head2 merge_config

    my %merged = $wire->merge_config( %config );

If C<%config> contains an C<extends> key, merge the extended config together
with this one, returning the merged service configuration. This works recursively,
so a service can extend a service that extends another service just fine.

When merging, hashes are combined, with the child configuration taking
precedence. The C<args> key is handled specially to allow a hash of
args to be merged.

The configuration returned is a safe copy and can be modified without
effecting the original config.

=head2 parse_args

    my @args = $wire->parse_args( $for_name, $class, $args );

Parse the arguments (C<$args>) for the given service (C<$for_name>) with
the given class (C<$class>).

C<$args> can be an array reference, a hash reference, or a simple
scalar. The arguments will be searched for references using L<the
find_refs method|/find_refs>, and then a list of arguments will be
returned, ready to pass to the object's constructor.

Nested containers are handled specially by this method: Their inner
references are not resolved by the parent container. This ensures that
references are always relative to the container they're in.

=head2 find_refs

    my @resolved = $wire->find_refs( $for_name, @args );

Go through the C<@args> and recursively resolve any references and
services found inside, returning the resolved result. References are
identified with L<the is_meta method|/is_meta>.

If a reference contains a C<$ref> key, it will be resolved by L<the
resolve_ref method|/resolve_ref>. Otherwise, the reference will be
treated as an anonymous service, and passed directly to L<the
create_service method|/create_service>.

This is used when L<creating a service|create_service> to ensure all
dependencies are created first.

=head2 is_meta

    my $is_meta = $wire->is_meta( $ref_hash, $root );

Returns true if the given hash reference describes some kind of
Beam::Wire service. This is used to identify service configuration
hashes inside of larger data structures.

A service hash reference must contain at least one key, and must either
contain a L<prefixed|/meta_prefix> key that could create or reference an
object (one of C<class>, C<extends>, C<config>, C<value>, or C<ref>) or,
if the C<$root> flag exists, be made completely of unprefixed meta keys
(as returned by L<the get_meta_names method|/get_meta_names>).

The C<$root> flag is used by L<the get method|/get> to allow unprefixed
meta keys in the top-level hash values.

=head2 get_meta_names

    my %meta_keys = $wire->get_meta_names;

Get all the possible service keys with the L<meta prefix|/meta_prefix> already
attached.

=head2 resolve_ref

    my @value = $wire->resolve_ref( $for_name, $ref_hash );

Resolves the given dependency from the configuration hash (C<$ref_hash>)
for the named service (C<$for_name>). Reference hashes contain the
following keys:

=over 4

=item $ref

The name of a service in the container. Required.

=item $path

A data path to pick some data out of the reference. Useful with C<value>
and C<config> services.

    # container.yml
    bounties:
        value:
            malcolm: 50000
            zoe: 35000
            simon: 100000

    captain:
        class: Person
        args:
            name: Malcolm Reynolds
            bounty:
                $ref: bounties
                $path: /malcolm

=item $call

Call a method on the referenced object and use the resulting value. This
may be a string, which will be the method name to call, or a hash with
C<$method> and C<$args>, which are the method name to call and the
arguments to that method, respectively.

    captain:
        class: Person
        args:
            name: Malcolm Reynolds
            location:
                $ref: beacon
                $call: get_location
            bounty:
                $ref: news
                $call:
                    $method: get_bounty
                    $args:
                        name: mreynolds

=back

=head2 fix_refs

    my @fixed = $wire->fix_refs( $for_name, @args );

Similar to L<the find_refs method|/find_refs>. This method searches
through the C<@args> and recursively fixes any reference paths to be
absolute. References are identified with L<the is_meta
method|/is_meta>.

This is used by L<the get_config method|/get_config> to ensure that the
configuration can be passed directly in to L<the create_service
method|create_service>.

=head2 new

    my $wire = Beam::Wire->new( %attributes );

Create a new container.

=head1 EXCEPTIONS

If there is an error internal to Beam::Wire, an exception will be thrown. If there is an
error with creating a service or calling a method, the exception thrown will be passed-
through unaltered.

=head2 Beam::Wire::Exception

The base exception class

=head2 Beam::Wire::Exception::Constructor

An exception creating a Beam::Wire object

=head2 Beam::Wire::Exception::Config

An exception loading the configuration file.

=head2 Beam::Wire::Exception::Service

An exception with service information inside

=head2 Beam::Wire::Exception::NotFound

The requested service or configuration was not found.

=head2 Beam::Wire::Exception::InvalidConfig

The configuration is invalid:

=over 4

=item *

Both "value" and "class" or "extends" are defined. These are mutually-exclusive.

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item BEAM_WIRE_DEBUG

If set, print a bunch of internal debugging information to STDERR.

=back

=head1 AUTHORS

=over 4

=item *

Doug Bell <preaction@cpan.org>

=item *

Al Newkirk <anewkirk@ana.io>

=back

=head1 CONTRIBUTORS

=for stopwords Ben Moon Bruce Armstrong Kent Fredric mohawk2

=over 4

=item *

Ben Moon <guiltydolphin@gmail.com>

=item *

Bruce Armstrong <bruce@armstronganchor.net>

=item *

Kent Fredric <kentnl@cpan.org>

=item *

mohawk2 <mohawk2@users.noreply.github.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
