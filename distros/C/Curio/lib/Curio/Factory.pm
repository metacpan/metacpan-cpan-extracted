package Curio::Factory;
our $VERSION = '0.04';

=encoding utf8

=head1 NAME

Curio::Factory - Definer, creator, provider, and holder of Curio objects.

=head1 SYNOPSIS

    my $factory = MyApp::Service::Cache->factory();

=head1 DESCRIPTION

The factory object contains the vast majority of Curio's logic.
Each Curio class (L<Moo> classes who consume L<Curio::Role>) gets
a single factory object created for them via L<Curio::Role/initialize>.

Note that much of the example code in this documentation is based
on the L<Curio/SYNOPSIS>.  Also when you see the term "Curio
object" it is referring to instances of L</class>.

=cut

use Curio::Guard;
use Curio::Util;
use Package::Stash;
use Scalar::Util qw( blessed refaddr );
use Types::Common::String qw( NonEmptySimpleStr );
use Types::Standard qw( Bool Map HashRef Undef );

use Moo;
use strictures 2;
use namespace::clean;

my %class_to_factory;

my $undef_key = '__UNDEF_KEY__';

sub BUILD {
    my ($self) = @_;

    $self->_store_class_to_factory();
    $self->_install_fetch_method();
    $self->_install_factory_method();

    return;
}

sub _store_class_to_factory {
    my ($self) = @_;

    my $class = $self->class();

    croak "Class already has a Curio::Factory object: $class"
        if $class_to_factory{ $class };

    $class_to_factory{ $class } = $self;

    return;
}

sub _install_fetch_method {
    my ($self) = @_;

    Package::Stash->new( $self->class() )->add_symbol(
        '&fetch',
        subname(
            'fetch',
            sub{
                shift;
                return $self->fetch_curio( @_ );
            },
        ),
    );

    return;
}

sub _install_factory_method {
    my ($self) = @_;

    Package::Stash->new( $self->class() )->add_symbol(
        '&factory',
        subname(
            'factory',
            sub{ $self },
        ),
    );

    return;
}

sub _process_key_arg {
    my ($self, $args) = @_;

    my $caller_sub_name = (caller 1)[3];
    $caller_sub_name =~ s{^.*::}{};

    my $key;

    if ($self->does_keys()) {
        if (@$args) {
            $key = shift @$args;
            croak "Invalid key passed to $caller_sub_name()"
                if !NonEmptySimpleStr->check( $key );
        }
        elsif (defined $self->default_key()) {
            $key = $self->default_key();
        }
        else {
            croak "No key was passed to $caller_sub_name()";
        }

        if (!$self->allow_undeclared_keys()) {
            croak "Undeclared key passed to $caller_sub_name()"
                if !$self->_keys->{$key};
        }
    }

    $key = $self->_aliases->{$key}
        if defined( $key )
        and defined( $self->_aliases->{$key} );

    return $key;
}

has _cache => (
    is       => 'ro',
    init_arg => undef,
    default  => sub{ {} },
);

sub _cache_set {
    my ($self, $key, $curio) = @_;
    $key = $self->_fixup_cache_key( $key );
    $self->_cache->{$key} = $curio;
    return;
}

sub _cache_get {
    my ($self, $key) = @_;
    $key = $self->_fixup_cache_key( $key );
    return $self->_cache->{$key};
}

sub _fixup_cache_key {
    my ($self, $key) = @_;

    $key = $undef_key if !defined $key;
    return $key if !$self->cache_per_process();

    $key .= "-$$";
    $key .= '-' . threads->tid() if $INC{'threads.pm'};

    return $key;
}

has _registry => (
    is       => 'ro',
    init_arg => undef,
    default  => sub{ {} },
);

has _keys => (
    is       => 'ro',
    init_arg => undef,
    default  => sub{ {} },
);

has _aliases => (
    is       => 'ro',
    init_arg => undef,
    default  => sub{ {} },
);

has _injections => (
    is       => 'ro',
    init_arg => undef,
    default  => sub{ {} },
);

=head1 REQUIRED ARGUMENTS

=head2 class

    class => 'MyApp::Service::Cache',

The Curio class that this factory uses to instantiate Curio
objects.

This is automatically set by L<Curio::Role/initialize>.

=cut

has class => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
);

=head1 OPTIONAL ARGUMENTS

=head2 does_registry

    does_registry => 1,
    resource_method_name => 'chi',

Causes the resource of all Curio objects to be automatically
registered so that L</find_curio> may function.

Defaults off (C<0>), meaning L</find_curio> will always return
C<undef>.

=cut

has does_registry => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head2 resource_method_name

    resource_method_name => 'chi',

The method name in the Curio class to retrieve the resource that
it holds.  A resource is whatever "thing" the Curio class
encapsulates.  In the case of the example in L<Curio/SYNOPSIS> the
resource is the CHI object which is accessible via the C<chi>
method.

It is still your job to create the method in the Curio class that
this argument refers to, such as:

    has chi => ( is=>'lazy', ... );

This argument must be defined in order for L<fetch_resource> and
L</does_registry> to work, otherwise they will have no way
to know how to get at the resource object.

This defaults to the string C<resource>.

=cut

has resource_method_name => (
  is      => 'rw',
  isa     => NonEmptySimpleStr,
  default => 'resource',
);

=head2 installs_curio_method

    does_registry => 1,
    resource_method_name => 'chi',
    installs_curio_method => 1,

This causes a C<curio()> method to be installed in all resource
object classes.  The method calls L</find_curio> and returns it,
allowing for reverse lookups from resource objects to curio objects.

L</does_registry> must be set for this to function.

=cut

has installs_curio_method => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head2 does_caching

    does_caching => 1,

When caching is enabled all calls to L</fetch_curio> will attempt to
retrieve from an in-memory cache.

Defaults off (C<0>), meaning all fetch calls will return a new
Curio object.

=cut

has does_caching => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head2 cache_per_process

    cache_per_process 1,

Some resource objects do not like to be created in one process
and then used in others.  When enabled this will add the current
process's PID and thread ID (if threads are enabled) to the key
used to cache the Curio object.

If either of these process IDs change then fetch will not re-use
the cached Curio object from a different process and will create
a new Curio object under the new process IDs.

Defaults to off (C<0>), meaning the same Curio objects will be
used by fetch across all forks and threads.

Normally the default works fine.  Some L<CHI> drivers need
this turned on.

=cut

has cache_per_process => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head2 export_function_name

    export_function_name => 'myapp_cache',

The export function is exported when the the Curio class is
imported, as in:

    use MyApp::Service::Cache;
    my $chi = myapp_cache( $key );

See also L</always_export> and L</export_resource>.

=cut

has export_function_name => (
    is  => 'rw',
    isa => NonEmptySimpleStr | Undef,
);

=head2 always_export

    always_export => 1,

When enabled this causes the export function to be always exported.

    use MyApp::Service::Cache;

When this option is not set you must explicitly request that the
export function be exported.

    use MyApp::Service::Cache qw( myapp_cache );

=cut

has always_export => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head2 export_resource

    export_resource => 1,

Rather than returning the curio object this will cause the resource
object to be returned by the export function.  Requires that
L</resource_method_name> be set.

=cut

has export_resource => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head2 does_keys

    does_keys => 1,

Turning this on allows a key argument to be passed to L</fetch_curio>
and many other methods.  Typically, though,  you don't have to
set this as you'll be using L</add_key> which automatically
turns this on.

By enabling keys this allows L</fetch_curio>, caching, resource
registration, injecting, and anything else dealing with
a Curio object to deal with multiple Curio objects based on
the passed key argument.

Defaults to off (C<0>), meaning the factory will only ever
manage a single Curio object.

=cut

has does_keys => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head2 allow_undeclared_keys

    allow_undeclared_keys => 1,

When L</fetch_curio>, and other key-accepting methods are called, they
normally throw an exception if the passed key has not already been
declared with L</add_key>.  By allowing undeclared keys any key
may be passed, which can be useful especially if coupled with
L</key_argument>.

Defaults to off (C<0>), meaning keys must always be declared before
being used.

=cut

has allow_undeclared_keys => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

=head2 default_key

    default_key => 'generic',

If no key is passed to key-accepting methods like L</fetch_curio> then
they will use this default key if available.

Defaults to no default key.

=cut

has default_key => (
    is  => 'rw',
    isa => NonEmptySimpleStr | Undef,
);

=head2 key_argument

    key_argument => 'connection_key',

When set, this causes an extra argument to be passed to the Curio
class during object instantiation.  The argument's key will be
whatever you set C<key_argument> to and the value will be the
key used to fetch the Curio object.

You will still need to write the code in your Curio class to
capture the argument, such as:

    has connection_key => ( is=>'ro' );

Defaults to no key argument.

=cut

has key_argument => (
    is  => 'rw',
    isa => NonEmptySimpleStr | Undef,
);

=head2 default_arguments

    default_arguments => {
        arg => 'value',
        ...
    },

When set, these arguments will be used when creating new instances
of the Curio class.

Any other arguments such as those provided by L</add_key> and
L</key_argument> will overwrite these default arguments.

=cut

has default_arguments => (
    is      => 'rw',
    isa     => HashRef,
    default => sub{ {} },
);

=head1 ATTRIBUTES

=head2 keys

    my $keys = $factory->keys();
    foreach my $key (@$keys) { ... }

Returns an array ref containing all the keys declared with
L</add_key>.

=cut

sub keys {
    my ($self) = @_;
    return [ keys %{ $self->_keys() } ];
}

=head1 METHODS

=head2 fetch_curio

    my $curio = $factory->fetch_curio();
    my $curio = $factory->fetch_curio( $key );

Returns a Curio object.  If L</does_caching> is enabled then
a cached object may be returned.

=cut

sub fetch_curio {
    my $self = shift;
    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to fetch_curio()' if @_;

    return $self->_fetch_curio( $key );
}

sub _fetch_curio {
    my ($self, $key) = @_;

    if ($self->does_caching()) {
        my $curio = $self->_cache_get( $key );
        return $curio if $curio;
    }

    my $curio = $self->_create( $key );

    if ($self->does_caching()) {
        $self->_cache_set( $key, $curio );
    }

    return $curio;
}

=head2 fetch_resource

    my $resource = $factory->fetch_resource();
    my $resource = $factory->fetch_resource( $key );

Like L</fetch_curio>, but always returns a resource.

=cut

sub fetch_resource {
    my $self = shift;
    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to fetch_resource()' if @_;

    return $self->_fetch_resource( $key );
}

sub _fetch_resource {
    my ($self, $key) = @_;

    my $method = $self->resource_method_name();

    my $curio = $self->_fetch_curio( $key );
    return undef if !$curio->can( $method );

    return $curio->$method();
}

# I see no need for a public create() method at this time.

#sub create {
#    my $self = shift;
#    my $key = $self->_process_key_arg( \@_ );
#    croak 'Too many arguments passed to create()' if @_;
#
#    return $self->_create( $key );
#}

sub _create {
    my ($self, $key) = @_;

    my $args = $self->_arguments( $key );

    my $curio = $self->class->new( $args );

    my $method = $self->resource_method_name();
    if ($curio->can($method)) {
        my $resource = $curio->$method();
        $self->_register_resource( $curio, $resource );

        my $resource_class = blessed $resource;
        $self->_install_curio_method( $resource_class ) if $resource_class;

    }

    return $curio;
}

sub _register_resource {
    my ($self, $curio, $resource) = @_;

    return if !$self->does_registry();
    return if !ref $resource;

    $self->_registry->{ refaddr $resource } = $curio;

    return;
}

sub _install_curio_method {
    my ($self, $resource_class) = @_;

    return if !$self->installs_curio_method();
    return if $resource_class->can('curio');

    no strict 'refs';

    *{"$resource_class\::curio"} = sub{
        my ($resource) = @_;
        return undef if !blessed $resource;
        return $self->find_curio( $resource );
    };

    return;
}

=head2 arguments

    my $args = $factory->arguments();
    my $args = $factory->arguments( $key );

This method returns an arguments hashref that would be used to
instantiate a new Curio object.  You could, for example, use this
to produce a base-line set of arguments, then sprinkle in some
more, and make yourself a special mock object to be injected.

=cut

sub arguments {
    my $self = shift;
    my $key = $self->_process_key_arg( \@_ );
    croak 'Too many arguments passed to arguments()' if @_;

    return $self->_arguments( $key );
}

sub _arguments {
    my ($self, $key) = @_;

    my $args = { %{ $self->default_arguments() } };

    return $args if !defined $key;

    %$args = (
        %$args,
        %{ $self->_keys->{$key} || {} },
    );

    if (defined $self->key_argument()) {
        $args->{ $self->key_argument() } = $key;
    }

    return $args;
}

=head2 add_key

    $factory->add_key( $key, %arguments );

Declares a new key and turns L</does_keys> on if it is not already
turned on.

Arguments are optional, but if present they will be saved and used
by L</fetch_curio> when calling C<new()> on L</class>.

=cut

sub add_key {
    my ($self, $key, @args) = @_;

    croakf(
        'Invalid key passed to add_key(): %s',
        NonEmptySimpleStr->get_message( $key ),
    ) if !NonEmptySimpleStr->check( $key );

    croak "Already declared key passed to add_key(): $key"
        if $self->_keys->{$key};

    croak 'Odd number of key arguments passed to add_key()'
        if @args % 2 != 0;

    $self->_keys->{$key} = { @args };

    $self->does_keys( 1 );

    return;
}

=head2 alias_key

    $factory->alias_key( $alias_key => $real_key );

Adds a key that is an alias to a key that was declared with
L</add_key>.  Alias keys can be used anywhere a declared key
can be used.

=cut

sub alias_key {
    my ($self, $alias, $key) = @_;

    croakf(
        'Invalid alias passed to alias_key(): %s',
        NonEmptySimpleStr->get_message( $alias ),
    ) if !NonEmptySimpleStr->check( $alias );

    croakf(
        'Invalid key passed to alias_key(): %s',
        NonEmptySimpleStr->get_message( $key ),
    ) if !NonEmptySimpleStr->check( $key );

    croak "Already declared alias passed to alias_key(): $alias"
        if defined $self->_aliases->{$alias};

    croak "Undeclared key passed to alias_key(): $key"
        if !$self->allow_undeclared_keys() and !$self->_keys->{$key};

    $self->_aliases->{$alias} = $key;

    return;
}

=head2 find_curio

    my $curio_object = $factory->find_curio( $resource );

Given a Curio object's resource this will return that Curio
object for it.

This does a reverse lookup of sorts and can be useful in
specialized situations where you have the resource, and you
need to introspect back into the Curio object.

    # I have my $chi and nothing else.
    my $factory = MyApp::Service::Cache->factory();
    my $curio = $factory->find_curio( $chi );

This only works if you've enabled L</does_registry>, otherwise
C<undef> is always returned by this method.

=cut

sub find_curio {
    my ($self, $resource) = @_;

    croak 'Non-reference resource passed to find_curio()'
        if !ref $resource;

    return $self->_registry->{ refaddr $resource };
}

=head2 inject

    $factory->inject( $curio_object );
    $factory->inject( $key, $curio_object );

Takes a curio object of your making and forces L</fetch_curio> to
return the injected object (or the injected object's resource).
This is useful for injecting mock objects in tests.

=cut

sub inject {
    my $self = shift;
    my $key = $self->_process_key_arg( \@_ );
    my $object = shift;

    $key = $undef_key if !defined $key;

    croak 'No object passed to inject()'
        if !blessed( $object );

    croakf(
        'Object of an incorrect class passed to inject(): %s (want %s)',
        ref( $object ), $self->class(),
    ) if !$object->isa( $self->class() );

    croak 'Cannot inject a Curio object where one has already been injected'
        if $self->_injections->{$key};

    $self->_injections->{$key} = $object;

    return;
}

=head2 inject_with_guard

    my $guard = $factory->inject_with_guard(
        $curio_object,
    );
    
    my $guard = $factory->inject_with_guard(
        $key, $curio_object,
    );

This is just like L</inject> except it returns an guard object which,
when it leaves scope and is destroyed, will automatically L</uninject>.

=cut

sub inject_with_guard {
    my $class = shift;

    $class->factory->inject( @_ );
    my $key = (@_==1) ? undef : shift( @_ );

    return Curio::Guard->new(sub{
        $class->factory->uninject( $key ? $key : () );
    });
}

=head2 uninject

    my $curio_object = $factory->uninject();
    my $curio_object = $factory->uninject( $key );

Removes the previously injected curio object, restoring the
original behavior of L</fetch_curio>.

Returns the previously injected curio object.

=cut

sub uninject {
    my $self = shift;
    my $key = $self->_process_key_arg( \@_ );

    $key = $undef_key if !defined $key;

    croak 'Cannot uninject a Curio object where one has not already been injected'
        if !$self->_injections->{$key};

    my $object = delete $self->_injections->{$key};

    return $object;
}

=head1 CLASS METHODS

=head2 find_factory

    my $factory = Curio::Factory->find_factory( $class );

Given a Curio class this will return its factory object,
or C<undef> otherwise.

=cut

sub find_factory {
    my ($class, $curio_class) = @_;

    croak 'Undefined Curio class passed to find_factory()'
        if !defined $curio_class;

    $curio_class = blessed( $curio_class ) || $curio_class;

    return $class_to_factory{ $curio_class };
}

1;
__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

