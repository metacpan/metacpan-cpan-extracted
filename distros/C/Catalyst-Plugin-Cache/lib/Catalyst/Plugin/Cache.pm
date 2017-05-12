#!/usr/bin/perl

package Catalyst::Plugin::Cache;
use Moose;

with 'Catalyst::ClassData';

our $VERSION = "0.12";

use Scalar::Util ();
use Catalyst::Utils ();
use Carp ();
use MRO::Compat;
use Scalar::Util qw/ blessed /;
use Catalyst::Plugin::Cache::Curried;

__PACKAGE__->mk_classdata( "_cache_backends" );
has _default_curried_cache => (
    is => 'rw',
);
no Moose;

sub setup {
    my $app = shift;

    # set it once per app, not once per plugin,
    # and don't overwrite if some plugin was wicked
    $app->_cache_backends({}) unless $app->_cache_backends;

    my $ret = $app->maybe::next::method( @_ );

    $app->setup_cache_backends;

    $ret;
}
{
    my %has_warned_for;
    sub _get_cache_plugin_config {
        my ($app) = @_;
        my $config = $app->config->{'Plugin::Cache'};
        if (!$config) {
            $config = $app->config->{cache};
            my $appname = ref($app);
            if (! $has_warned_for{$appname}++ ) {
                $app->log->warn($config ?
                    'Catalyst::Plugin::Cache config found in deprecated $c->config->{cache}, please move to $c->config->{"Plugin::Cache"}.'
                    : 'Catalyst::Plugin::Cache config not found, using empty config!'
                );
            }
        }
        return $config || {};
    }
}

sub get_default_cache_backend_config {
    my ( $app, $name ) = @_;
    $app->_get_cache_plugin_config->{backend} || $app->get_cache_backend_config("default");
}

sub get_cache_backend_config {
    my ( $app, $name ) = @_;
    $app->_get_cache_plugin_config->{backends}{$name};
}

sub setup_cache_backends {
    my $app = shift;

    # give plugins a chance to find things for themselves
    $app->maybe::next::method;

    # FIXME - Don't know why the _get_cache_plugin_config method doesn't work here!
    my $conf = $app->_get_cache_plugin_config->{backends};
    foreach my $name ( keys %$conf ) {
        next if $app->get_cache_backend( $name );
        $app->setup_generic_cache_backend( $name, $app->get_cache_backend_config( $name ) || {} );
    }

    if ( !$app->get_cache_backend("default") ) {
        ### XXX currently we dont have a fallback scenario
        ### so die here with the error message. Once we have
        ### an in memory fallback, we may consider silently
        ### logging the error and falling back to that.
        ### If we dont die here, the app will silently start
        ### up and then explode at the first cache->get or
        ### cache->set request with a FIXME error
        #local $@;
        #eval { 
        $app->setup_generic_cache_backend( default => $app->get_default_cache_backend_config || {} );
        #};
        
   }
}

sub default_cache_store {
    my $app = shift;
    $app->_get_cache_plugin_config->{default_store} || $app->guess_default_cache_store;
}

sub guess_default_cache_store {
    my $app = shift;

    my @stores = map { /Cache::Store::(.*)$/ ? $1 : () } $app->registered_plugins;

    if ( @stores == 1 ) {
        return $stores[0];
    } else {
        Carp::croak "You must configure a default store type unless you use exactly one store plugin.";
    }
}

sub setup_generic_cache_backend {
    my ( $app, $name, $config ) = @_;
    my %config = %$config;

    if ( my $class = delete $config{class} ) {
        
        ### try as list and as hashref, collect the
        ### error if things go wrong
        ### if all goes well, exit the loop
        my @errors;
        for my $aref ( [%config], [\%config] ) {
            eval { $app->setup_cache_backend_by_class( 
                        $name, $class, @$aref 
                    );
            } ? do { @errors = (); last }
              : push @errors, "\t$@";
        }
        
        ### and die with the errors if we have any
        die "Couldn't construct $class with either list style or hash ref style param passing:\n @errors" if @errors;
        
    } elsif ( my $store = delete $config->{store} || $app->default_cache_store ) {
        my $method = lc("setup_${store}_cache_backend");

        Carp::croak "You must load the $store cache store plugin (if it exists). ".
        "Please consult the Catalyst::Plugin::Cache documentation on how to configure hetrogeneous stores."
            unless $app->can($method);

        $app->$method( $name, \%config );
    } else {
        $app->log->warn("Couldn't setup the cache backend named '$name'");
    }
}

sub setup_cache_backend_by_class {
    my ( $app, $name, $class, @args ) = @_;
    Catalyst::Utils::ensure_class_loaded( $class );
    $app->register_cache_backend( $name => $class->new( @args ) );
}

# end of spaghetti setup DWIM

sub cache {
    my ( $c, @meta ) = @_;

    if ( @meta == 1 ) {
        my $name = $meta[0];
        return ( $c->get_preset_curried($name) || $c->get_cache_backend($name) );
    } elsif ( !@meta && blessed $c ) {
        # be nice and always return the same one for the simplest case
        return ( $c->_default_curried_cache || $c->_default_curried_cache( $c->curry_cache( @meta ) ) );
    } else {
        return $c->curry_cache( @meta );
    }
}

sub construct_curried_cache {
    my ( $c, @meta ) = @_;
    return $c->curried_cache_class( @meta )->new( @meta );
}

sub curried_cache_class {
    my ( $c, @meta ) = @_;
    $c->_get_cache_plugin_config->{curried_class} || "Catalyst::Plugin::Cache::Curried";
}

sub curry_cache {
    my ( $c, @meta ) = @_;
    return $c->construct_curried_cache( $c, $c->_cache_caller_meta, @meta );
}

sub get_preset_curried {
    my ( $c, $name ) = @_;

    if ( ref( my $preset = $c->_get_cache_plugin_config->{profiles}{$name} ) ) {
        return $preset if Scalar::Util::blessed($preset);

        my @meta = ( ( ref $preset eq "HASH" ) ? %$preset : @$preset );
        return $c->curry_cache( @meta );
    }

    return;
}

sub get_cache_backend {
    my ( $c, $name ) = @_;
    $c->_cache_backends->{$name};
}

sub register_cache_backend {
    my ( $c, $name, $backend ) = @_;

    no warnings 'uninitialized';
    Carp::croak("$backend does not look like a cache backend - "
    . "it must be an object supporting get, set and remove")
        unless eval { $backend->can("get") && $backend->can("set") && $backend->can("remove") };

    $c->_cache_backends->{$name} = $backend;
}

sub unregister_cache_backend {
    my ( $c, $name ) = @_;
    delete $c->_cache_backends->{$name};
}

sub default_cache_backend {
    my $c = shift;
    $c->get_cache_backend( "default" ) || $c->temporary_cache_backend;
}

sub temporary_cache_backend {
    my $c = shift;
    die "FIXME - make up an in memory cache backend, that hopefully works well for the current engine";
}

sub _cache_caller_meta {
    my $c = shift;

    my ( $caller, $component, $controller );
    
    for my $i ( 0 .. 15 ) { # don't look to far
        my @info = caller(2 + $i) or last;

        $caller     ||= \@info unless $info[0] =~ /Plugin::Cache/;
        $component  ||= \@info if $info[0]->isa("Catalyst::Component");
        $controller ||= \@info if $info[0]->isa("Catalyst::Controller");
    
        last if $caller && $component && $controller;
    }

    my ( $caller_pkg, $component_pkg, $controller_pkg ) =
        map { $_ ? $_->[0] : undef } $caller, $component, $controller;

    return (
        'caller'   => $caller_pkg,
        component  => $component_pkg,
        controller => $controller_pkg,
        caller_frame     => $caller,
        component_frame  => $component,
        controller_frame => $controller,
    );
}

# this gets a shit name so that the plugins can override a good name
sub choose_cache_backend_wrapper {
    my ( $c, @meta ) = @_;

    Carp::croak("metadata must be an even sized list") unless @meta % 2 == 0;

    my %meta = @meta;

    unless ( exists $meta{'caller'} ) {
        my %caller = $c->_cache_caller_meta;
        @meta{keys %caller} = values %caller;
    }
    
    # allow the cache client to specify who it wants to cache with (but loeave room for a hook)
    if ( exists $meta{backend} ) {
        if ( Scalar::Util::blessed($meta{backend}) ) {
            return $meta{backend};
        } else {
            return $c->get_cache_backend( $meta{backend} ) || $c->default_cache_backend;
        }
    };
    
    if ( my $chosen = $c->choose_cache_backend( %meta ) ) {
        $chosen = $c->get_cache_backend( $chosen ) unless Scalar::Util::blessed($chosen); # if it's a name find it
        return $chosen if Scalar::Util::blessed($chosen); # only return if it was an object or name lookup worked

        # FIXME
        # die "no such backend"?
        # currently, we fall back to default
    }
    
    return $c->default_cache_backend;
}

sub choose_cache_backend { shift->maybe::next::method( @_ ) } # a convenient fallback

sub cache_set {
    my ( $c, $key, $value, %meta ) = @_;
    $c->choose_cache_backend_wrapper( key =>  $key, value => $value, %meta )
        ->set( $key, $value, exists $meta{expires} ? $meta{expires} : () );
}

sub cache_get {
    my ( $c, $key, @meta ) = @_;
    $c->choose_cache_backend_wrapper( key => $key, @meta )->get( $key );
}

sub cache_remove {
    my ( $c, $key, @meta ) = @_;
    $c->choose_cache_backend_wrapper( key => $key, @meta )->remove( $key );
}

sub cache_compute {
    my ($c, $key, $code, %meta) = @_;

    my $backend = $c->choose_cache_backend_wrapper( key =>  $key, %meta );
    if ($backend->can('compute')) {
        return $backend->compute( $key, $code, exists $meta{expires} ? $meta{expires} : () );
    }

    Carp::croak "must specify key and code" unless defined($key) && defined($code);

    my $value = $c->cache_get( $key, %meta );
    if ( !defined $value ) {
        $value = $code->();
        $c->cache_set( $key, $value, %meta );
    }
    return $value;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Cache - Flexible caching support for Catalyst.

=head1 SYNOPSIS

	use Catalyst qw/
        Cache
    /;

    # configure a backend or use a store plugin 
    __PACKAGE__->config->{'Plugin::Cache'}{backend} = {
        class => "Cache::Bounded",
        # ... params for Cache::Bounded...
    };

    # typical example for Cache::Memcached::libmemcached
    __PACKAGE__->config->{'Plugin::Cache'}{backend} = {
        class   => "Cache::Memcached::libmemcached",
        servers => ['127.0.0.1:11211'],
        debug   => 2,
    };


    # In a controller:

    sub foo : Local {
        my ( $self, $c, $id ) = @_;

        my $cache = $c->cache;

        my $result;

        unless ( $result = $cache->get( $id ) ) {
            # ... calculate result ...
            $c->cache->set( $id, $result );
        }
    };

=head1 DESCRIPTION

This plugin gives you access to a variety of systems for caching
data. It allows you to use a very simple configuration API, while
maintaining the possibility of flexibility when you need it later.

Among its features are support for multiple backends, segmentation based
on component or controller, keyspace partitioning, and so more, in
various subsidiary plugins.

=head1 METHODS

=over 4

=item cache $profile_name

=item cache %meta

Return a curried object with metadata from C<$profile_name> or as
explicitly specified.

If a profile by the name C<$profile_name> doesn't exist, but a backend
object by that name does exist, the backend will be returned instead,
since the interface for curried caches and backends is almost identical.

This method can also be called without arguments, in which case is
treated as though the C<%meta> hash was empty.

See L</METADATA> for details.

=item curry_cache %meta

Return a L<Catalyst::Plugin::Cache::Curried> object, curried with C<%meta>.

See L</METADATA> for details.

=item cache_set $key, $value, %meta

=item cache_get $key, %meta

=item cache_remove $key, %meta

=item cache_compute $key, $code, %meta

These cache operations will call L<choose_cache_backend> with %meta, and
then call C<set>, C<get>, C<remove>, or C<compute> on the resulting backend
object.

If the backend object does not support C<compute> then we emulate it by
calling L<cache_get>, and if the returned value is undefined we call the passed
code reference, stores the returned value with L<cache_set>, and then returns
the value.  Inspired by L<CHI>.

=item choose_cache_backend %meta

Select a backend object. This should return undef if no specific backend
was selected - its caller will handle getting C<default_cache_backend>
on its own.

This method is typically used by plugins.

=item get_cache_backend $name

Get a backend object by name.

=item default_cache_backend

Return the default backend object.

=item temporary_cache_backend

When no default cache backend is configured this method might return a
backend known to work well with the current L<Catalyst::Engine>. This is
a stub.

=item 

=back

=head1 METADATA

=head2 Introduction

Whenever you set or retrieve a key you may specify additional metadata
that will be used to select a specific backend.

This metadata is very freeform, and the only key that has any meaning by
default is the C<backend> key which can be used to explicitly choose a backend
by name.

The C<choose_cache_backend> method can be overridden in order to
facilitate more intelligent backend selection. For example,
L<Catalyst::Plugin::Cache::Choose::KeyRegexes> overrides that method to
select a backend based on key regexes.

Another example is a L<Catalyst::Plugin::Cache::ControllerNamespacing>,
which wraps backends in objects that perform key mangling, in order to
keep caches namespaced per controller.

However, this is generally left as a hook for larger, more complex
applications. Most configurations should make due XXXX

The simplest way to dynamically select a backend is based on the
L</Cache Profiles> configuration.

=head2 Meta Data Keys

C<choose_cache_backend> is called with some default keys.

=over 4

=item key

Supplied by C<cache_get>, C<cache_set>, and C<cache_remove>.

=item value

Supplied by C<cache_set>.

=item caller

The package name of the innermost caller that doesn't match
C<qr/Plugin::Cache/>.

=item caller_frame

The entire C<caller($i)> frame of C<caller>.

=item component

The package name of the innermost caller who C<isa>
L<Catalyst::Component>.

=item component_frame

This entire C<caller($i)> frame of C<component>.

=item controller

The package name of the innermost caller who C<isa>
L<Catalyst::Controller>.

=item controller_frame

This entire C<caller($i)> frame of C<controller>.

=back

=head2 Metadata Currying

In order to avoid specifying C<%meta> over and over again you may call
C<cache> or C<curry_cache> with C<%meta> once, and get back a B<curried
cache object>. This object responds to the methods C<get>, C<set>, and
C<remove>, by appending its captured metadata and delegating them to
C<cache_get>, C<cache_set>, and C<cache_remove>.

This is simpler than it sounds.

Here is an example using currying:

    my $cache = $c->cache( %meta ); # cache is curried

    $cache->set( $key, $value );

    $cache->get( $key );

And here is an example without using currying:

    $c->cache_set( $key, $value, %meta );

    $c->cache_get( $key, %meta );

See L<Catalyst::Plugin::Cache::Curried> for details.

=head1 CONFIGURATION

    $c->config->{'Plugin::Cache'} = {
        ...
    };

All configuration parameters should be provided in a hash reference
under the C<Plugin::Cache> key in the C<config> hash.

=head2 Backend Configuration

Configuring backend objects is done by adding hash entries under the
C<backends> key in the main config.

A special case is that the hash key under the C<backend> (singular) key
of the main config is assumed to be the backend named C<default>.

=over 4

=item class

Instantiate a backend from a L<Cache> compatible class. E.g.

    $c->config->{'Plugin::Cache'}{backends}{small_things} = {
        class    => "Cache::Bounded",
        interval => 1000,
        size     => 10000,
    };
    
    $c->config->{'Plugin::Cache'}{backends}{large_things} = {
        class => "Cache::Memcached",
        data  => '1.2.3.4:1234',
    };

The options in the hash are passed to the class's C<new> method.

The class will be C<required> as necessary during setup time.

=item store

Instantiate a backend using a store plugin, e.g.

    $c->config->{'Plugin::Cache'}{backend} = {
        store => "FastMmap",
    };

Store plugins typically require less configuration because they are
specialized for L<Catalyst> applications. For example
L<Catalyst::Plugin::Cache::Store::FastMmap> will specify a default
C<share_file>, and additionally use a subclass of L<Cache::FastMmap>
that can also store non reference data.

The store plugin must be loaded.

=back

=head2 Cache Profiles

=over 4

=item profiles

Supply your own predefined profiles for cache metadata, when using the
C<cache> method.

For example when you specify

    $c->config->{'Plugin::Cache'}{profiles}{thumbnails} = {
        backend => "large_things",
    };

And then get a cache object like this:

    $c->cache("thumbnails");

It is the same as if you had done:

    $c->cache( backend => "large_things" );

=back

=head2 Miscellaneous Configuration

=over 4

=item default_store

When you do not specify a C<store> parameter in the backend
configuration this one will be used instead. This configuration
parameter is not necessary if only one store plugin is loaded.

=back

=head1 TERMINOLOGY

=over 4

=item backend

An object that responds to the methods detailed in
L<Catalyst::Plugin::Cache::Backend> (or more).

=item store

A plugin that provides backends of a certain type. This is a bit like a
factory.

=item cache

Stored key/value pairs of data for easy re-access.

=item metadata

"Extra" information about the item being stored, which can be used to
locate an appropriate backend.

=item curried cache

  my $cache = $c->cache(type => 'thumbnails');
  $cache->set('pic01', $thumbnaildata);

A cache which has been pre-configured with a particular set of
namespacing data. In the example the cache returned could be one
specifically tuned for storing thumbnails.

An object that responds to C<get>, C<set>, and C<remove>, and will
automatically add metadata to calls to C<< $c->cache_get >>, etc.

=back

=head1 SEE ALSO

L<Cache> - the generic cache API on CPAN.

L<Catalyst::Plugin::Cache::Store> - how to write a store plugin.

L<Catalyst::Plugin::Cache::Curried> - the interface for curried caches.

L<Catalyst::Plugin::Cache::Choose::KeyRegexes> - choose a backend based on
regex matching on the keys. Can be used to partition the keyspace.

L<Catalyst::Plugin::Cache::ControllerNamespacing> - wrap backend objects in a
name mangler so that every controller gets its own keyspace.

=head1 AUTHOR

Yuval Kogman, C<nothingmuch@woobling.org>

Jos Boumans, C<kane@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) Yuval Kogman, 2006. All rights reserved.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself, as well as under the terms of the MIT license.

=cut

