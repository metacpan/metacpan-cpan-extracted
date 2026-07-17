package Dancer2::Plugin::ContentCache;
use v5.20;
use warnings;
use Carp;
use Dancer2::Plugin;
use DateTime;
use JSON::MaybeXS qw(encode_json decode_json);
use Module::Runtime qw(use_module);
use UUID::Tiny qw(:std);

use Dancer2::Plugin::ContentCache::CacheEntry;
use Dancer2::Plugin::ContentCache::Driver::DBIC;

our $VERSION = '1.0000'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY

# The only metadata key the plugin reserves for itself internally; it never
# appears in a CacheEntry's ->metadata.
my $FORMAT_KEY = '__content_cache_format';

has cache_result_set => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->config->{cache_result_set} },
);

has schema_name => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->config->{schema} // 'default' },
);

has driver_name => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->config->{driver} // 'DBIx::Class' },
);

has create_redirect_route => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->config->{create_redirect_route} // 1 },
);

has redirect_route => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->config->{redirect_route} // '/recall' },
);

has require_login => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->config->{require_login} // 0 },
);

has cache_aging => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->config->{cache_aging} // 1 },
);

has default_life => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->config->{default_life} // 86400 },
);

has driver => (
    is  => 'lazy',
);

plugin_keywords qw(
    cache_and_send
    cache_and_redirect
    retrieve_cache
    set_cache
    clean_up_cache
);

sub BUILD {
    my $self = shift;

    if ( $self->cache_aging && !$self->driver->has_aging_columns ) {
        croak 'ContentCache: cache_aging is enabled, but the configured '
            . 'cache store has no created_dt/expiry_dt columns';
    }

    return unless $self->create_redirect_route;

    my $route = $self->redirect_route;

    $self->app->add_route(
        method => 'get',
        regexp => "$route/:uuid",
        code   => sub {
            my $app = shift;

            if ( $self->require_login && !$self->_current_user_ok($app) ) {
                return $app->send_error( 'Not Found', 404 );
            }

            my $uuid  = $app->request->params->{uuid};
            my $cache = $self->retrieve_cache($uuid);

            return $app->send_error( 'Not Found', 404 ) unless $cache;

            return $app->send_as( $cache->data_format => $cache->data );
        },
    );

    return;
}

sub cache_and_redirect {
    my ( $self, $content, $metadata ) = @_;

    my $uuid  = $self->set_cache( $content, $metadata );
    my $route = $self->redirect_route;

    return $self->app->redirect("$route/$uuid");
}

sub cache_and_send {
    my ( $self, $content, $metadata ) = @_;

    $self->set_cache( $content, $metadata );

    return $self->app->send_as( _format_of($content) => $content );
}

sub clean_up_cache {
    my $self = shift;

    return 0 unless $self->cache_aging;
    return $self->driver->delete_expired;
}

sub retrieve_cache {
    my ( $self, $uuid ) = @_;

    return undef unless defined $uuid;

    my $row = $self->driver->find_entry($uuid);
    return undef unless $row;

    if ( $self->cache_aging
        && $row->{expiry_dt}
        && DateTime->compare( $row->{expiry_dt}, DateTime->now ) <= 0 )
    {
        return undef;
    }

    my $metadata = decode_json( $row->{metadata} );
    my $format = delete $metadata->{$FORMAT_KEY} // 'html';

    return Dancer2::Plugin::ContentCache::CacheEntry->new(
        uuid        => $row->{uuid},
        data_format => $format,
        data        => $format eq 'JSON' ? decode_json( $row->{data} ) : $row->{data},
        created_dt  => $row->{created_dt},
        expiry_dt   => $row->{expiry_dt},
        metadata    => $metadata,
    );
}

sub set_cache {
    my ( $self, $content, $metadata ) = @_;

    croak 'ContentCache: set_cache requires data to cache' unless defined $content;
    $metadata = {} unless ref $metadata eq 'HASH';

    my $format      = _format_of($content);
    my $stored_data = $format eq 'JSON' ? encode_json($content) : $content;

    my %stored_metadata = %$metadata;
    $stored_metadata{$FORMAT_KEY} = $format;

    my $life;
    if ( $self->cache_aging ) {
        $life = $metadata->{life} // $self->default_life;
        $stored_metadata{life} = $life;
    }

    my $uuid = create_uuid_as_string(UUID_V4);

    $self->driver->create_entry(
        uuid       => $uuid,
        data       => $stored_data,
        metadata   => encode_json( \%stored_metadata ),
        created_dt => $self->driver->has_created_column ? DateTime->now : undef,
        expiry_dt  => $self->cache_aging ? DateTime->now->add( seconds => $life ) : undef,
    );

    return $uuid;
}

sub _build_driver {
    my $self = shift;

    if ( $self->driver_name eq 'DBIx::Class' ) {
        croak q/ContentCache: 'cache_result_set' must be configured/
            unless defined $self->cache_result_set;

        return Dancer2::Plugin::ContentCache::Driver::DBIC->new(
            plugin          => $self,
            schema_name     => $self->schema_name,
            result_set_name => $self->cache_result_set,
        );
    }

    my $driver_class = use_module( $self->driver_name );
    croak "ContentCache: driver class $driver_class does not implement "
        . 'Dancer2::Plugin::ContentCache::Driver'
        unless $driver_class->can('does') && $driver_class->does('Dancer2::Plugin::ContentCache::Driver');

    return $driver_class->new( plugin => $self, config => $self->config );
}

sub _current_user_ok {
    my ( $self, $app ) = @_;

    my ($auth_plugin) =
        grep { ref($_) eq 'Dancer2::Plugin::Auth::Extensible' } @{ $app->plugins };

    return 0 unless $auth_plugin;
    return $auth_plugin->logged_in_user ? 1 : 0;
}

sub _format_of {
    my $content = shift;
    my $ref     = ref $content;

    return ( $ref eq 'HASH' || $ref eq 'ARRAY' ) ? 'JSON' : 'html';
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::ContentCache - Cache HTML/JSON responses for later use.

=head1 VERSION

version 1.0000

=head1 SYNOPSIS

 # In config.yml:
 #
 plugins:
   ContentCache:
      # REQUIRED, unless you supply your own 'driver' (see DRIVERS, below).
      cache_result_set: ContentCache

      # Optional, with defaults
      driver: DBIx::Class
      schema: default
      create_redirect_route: 1
      redirect_route: '/recall'
      require_login: 0
      cache_aging: 1
      default_life: 86400

 # In your Dancer2 application
 #
 package MyApp;
 use Dancer2 appname => 'MyApp';
 use Dancer2::Plugin::ContentCache;

 post '/this_route' => sub {
   # This route is supposed to return HTML

   my $html = template 'Foo',
              { param1 => 'bar' },
              { layout => 'some_layout'};

   cache_and_redirect $html,
              { life => 6000, created_by => 'baz' };
              # metadata; note 'life'
 };

 post '/this_other_route' => sub {
   # do some processing
   # This route is supposed to return JSON

   cache_and_send $results, { created_by => 'baz' };
   # $results is a hashref or arrayref.
 };

 #
 # Example of custom cache handler:
 #
 get '/retrieve_privileged/:uuid' => sub {

    my $cache = retrieve_cache route_parameters->get('uuid');
    my $all_good = 0;

    # Use the stuff in $cache->metadata to decide if you want to send this
    # to the user, and set $all_good as appropriate.

    if ($all_good) {
       send_as $cache->data_format => $cache->data;
    }
    else {
       return send_error('Not Found', 404);
    }
 };

=head1 DESCRIPTION

This plugin for L<Dancer2> implements a response-content cache and optionally
issues a redirect to that content. In particular, this is useful after a POST
route; if the network times out (as can happen on wonky connections), you
don't want the user to re-POST. By redirecting them to the now-cached content
as a GET, you prevent re-POSTing.

Storage is never touched directly by this plugin; every read and write goes
through a small driver object, so you are not locked into L<DBIx::Class>. See
L</DRIVERS>, below.

=head1 CONFIGURATION

In your C<config.yml> for your Dancer2 application, use these configuration
parameters:

=over 3

=item C<driver>

This optional configuration parameter is to allow use of some other driver
for the database than the default, which is L<DBIx::Class>. See L</DRIVERS>.

=item C<schema>

This parameter lets you specify which schema is the one containing your
result set (table). Default value is 'default', which is what's usually used
when you only have one. Only used by the default L<DBIx::Class> driver, which
will use whichever of L<Dancer2::Plugin::DBIC> or
L<Dancer2::Plugin::DBIx::Class> your application has loaded (preferring
C<DBIC> if both are present).

=item C<cache_result_set>

B<Mandatory>, if the C<driver> is the default L<DBIx::Class>. This setting
points at the ResultSet name in which the table will be stored.

=item C<create_redirect_route>

Default is C<1>, true. The system will create a default route to retrieve and
return the cache. The name will be set in C<redirect_route>, below, and will
expect a single route parameter, the UUID of the cache entry.

If set to C<0>, false, then no route will be created, and it's assumed you
will roll your own, using the C<retrieve_cache> keyword below.

=item C<redirect_route>

The name of the built-in redirect route, if it is created. Default is
'/recall'.

=item C<require_login>

If the built-in redirect route is created, is login required? If this is set
to C<1>, true, AND you are using L<Dancer2::Plugin::Auth::Extensible>, then
the created route will check for C<logged_in_user> before returning the data.
If you are not using the Extensible plugin, or the user is not logged in,
they will be returned a 404 error.

=item C<cache_aging>

Default is C<1>, true. Set this to C<0>, false, to disable cache aging. Note
in L</"BUGS AND LIMITATIONS">, below, that if you have aging on, your driver
must be able to record the two necessary fields. The plugin will C<croak> at
application start time, if the necessary bits aren't there.

=item C<default_life>

Default is 86400 seconds (1 day). If C<cache_aging> is on, this sets the
default life of the cache entries, if not specified by C<life> metadata in
the cache entry.

=back

=head1 DANCER2 KEYWORDS

=over 3

=item B<cache_and_send>

This keyword replaces C<send_as [html|JSON]> in your Dancer2 route to first
cache the required data, then ship it along without a redirect pointing at
the cache.

=item B<cache_and_redirect>

This keyword also replaces C<send_as [html|JSON]> in your Dancer2 route to
first cache the required data, then redirect the user to the cache-retrieval
link.

=item B<retrieve_cache>

Given a UUID of the cache, attempts to retrieve the cache with that key. If
the cache is already expired, or doesn't exist under that UUID, return
undef. With an unexpired cache, this keyword returns a cache object (see
L</"THE CACHE OBJECT"> for details).

=item B<set_cache>

This is a convenience method for pushing a cache. It expects either some
HTML (a scalar) or JSON (a hashref or arrayref), and an additional hashref
of optional metadata, and returns the UUID of the cache created.

 # A JSON cache, with five minutes of life.
 my $uuid = set_cache $hashref, { life => 300 };

 # Another JSON cache, this time of an arrayref, with default life.
 my $uuid = set_cache $arrayref, {};

 # An html/scalar cache, with the default life.
 my $uuid = set_cache $html;

=item B<clean_up_cache>

This convenience term should be run from time to time if C<cache_aging> is
turned on. It will look through the store and delete all expired caches,
returning the number of expired entities. If C<cache_aging> is off, it will
always return zero. You might put this in an admin route for super-users, or
it can be included in a cron job to run from time to time.

=back

=head1 THE CACHE OBJECT

The cache object, L<Dancer2::Plugin::ContentCache::CacheEntry>, is a simple
L<Moo> object containing the following field/methods:

=over 3

=item B<data_format>

This will return C<html> if the original data sent into the cache was HTML
or some other scalar, and C<JSON> if a hashref or arrayref was put in the
cache. Useful for C<send_as>-ing a retrieved cache.

=item B<data>

The data that was placed in the cache, exactly as it was sent in with
C<cache_and_send> or C<set_cache>--either a scalar, arrayref, or hashref.

=item B<created_dt>

If the driver is able to record a creation time (see L</DRIVERS>), it is
automatically set at cache create time, and may be retrieved here as a
L<DateTime> object. If not, this will return undefined. This behavior
(unlike C<expiry_dt> below) is B<not> dependent on the value of
C<cache_aging>, merely the driver's capability.

=item B<expiry_dt>

If C<cache_aging> is turned on, this will recall the L<DateTime> that the
cache will expire. If not, this will return undefined.

=item B<metadata>

A hashref containing all the metadata stored with this object. The C<life>
will always be present if the C<cache_aging> setting is turned on.

Note that C<life> is the only reserved metadata term. If aging is turned on,
it will be automatically set by the default unless you override it with a
value.

=back

=head1 DRIVERS

L<Dancer2::Plugin::ContentCache> never touches a database (or anything else)
directly; all storage happens through a driver class that consumes the
L<Dancer2::Plugin::ContentCache::Driver> role. The bundled default,
L<Dancer2::Plugin::ContentCache::Driver::DBIC>, stores entries with
L<DBIx::Class> via L<Dancer2::Plugin::DBIx::Class> or L<Dancer2::Plugin::DBIC>,
whichever your application is using..

To use a different backend, write a class that consumes
L<Dancer2::Plugin::ContentCache::Driver> and set the C<driver> configuration
option to its full package name:

 plugins:
   ContentCache:
     driver: MyApp::ContentCache::Driver::Redis

See L<Dancer2::Plugin::ContentCache::Driver> for the small set of methods
your driver needs to implement.

=head1 SUGGESTED SCHEMA

Here's the sort of schema you'll need for the default L<DBIx::Class> driver
(this one, for PostgreSQL). If you're using more-recent versions of
PostgreSQL that have a UUID type, you could use that, but this is the
lowest-common-denominator form of the schema:

 CREATE TABLE IF NOT EXISTS content_cache (
   uuid TEXT NOT NULL PRIMARY KEY,         -- Or "id", your choice.
   metadata TEXT NOT NULL,                 -- REQUIRED
   data TEXT NOT NULL,                     -- REQUIRED
   created_dt TIMESTAMP WITHOUT TIME ZONE, -- Plugin will always assume "local"
                                           -- unless you store it WITH TIMEZONE
                                           -- Only needed if cache_aging is on.
   expiry_dt TIMESTAMP WITHOUT TIME ZONE   -- Same here as with created_dt
 );

=head1 DEPENDENCIES

=over 3

=item *

L<Dancer2>, obviously.

=item *

L<Dancer2::Plugin::DBIC> or L<Dancer2::Plugin::DBIx::Class>, if you're using
the default driver.

=item *

L<DateTime>

=item *

L<DateTime::Format::Strptime>, if you're using the default driver.

=item *

L<JSON::MaybeXS>, which requires any one of three different JSON processors;
you probably already have at least one of them installed.

=item *

L<Module::Runtime>

=item *

L<UUID::Tiny>

=back

=head1 BUGS AND LIMITATIONS

=over 3

=item *

This tool provides no mechanism for "refreshing" or "updating" a cache. Once
an entry is created, it is immutable, both in content and in its expiry.
That may be a limitation, but we may also call it a feature, depending on
your mindset.

=item *

If you specify C<cache_aging>, but your driver cannot record C<created_dt>
and C<expiry_dt> (for the default DBIx::Class driver: your schema does not
have those two columns), aging won't work!

=back

=head1 ACKNOWLEDGEMENTS

The idea for this plugin comes from Mike Weisenborn of
L<Clearbuilt|https://clearbuilt.com>. Clearbuilt graciously sponsored the
development of this work.

=head1 SEE ALSO

=over 3

=item *

L<Dancer2::Plugin::CHI> is a less-feature-rich key-value cache that could be
used for some of what we're doing here. If this one is doing too much for
your tastes, it's a good choice.

=item *

L<Dancer2::Plugin::ViewCache> also stores HTML page content, but is
deliberately intended for "guest" viewing without requiring a login.

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Cache HTML/JSON responses for later use.

