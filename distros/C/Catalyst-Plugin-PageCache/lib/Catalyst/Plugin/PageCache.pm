package Catalyst::Plugin::PageCache;

use strict;
use base qw/Class::Accessor::Fast/;
use MRO::Compat;
use Digest::SHA1 ();

our $VERSION = '0.32';

# Do we need to cache the current page?
__PACKAGE__->mk_accessors('_cache_page');

# Keeps track of whether the current request was served from cache
__PACKAGE__->mk_accessors('_page_cache_used');

# Keeps a safe copy of the initial request parameters, in case the
# user changes them during processing
__PACKAGE__->mk_accessors('_page_cache_key');

sub cache_page {
    my ( $c, @args ) = @_;
    my %options;

    # Mark that cache_page has been called but defer on selecting the time
    # period to cache for until finalize. _get_page_cache_expiration_time has
    # more options at that time, such as various headers which may have been set.

    if (@args == 1) {
        my $expires = shift @args;

        # Allow specific end time
        $expires = $expires->epoch - time()
            if ref($expires) && $expires->can('epoch');

        $options{cache_seconds} = $expires;
    }
    else {
        %options = @args;
    }

    $c->_cache_page( \%options );
}


sub clear_cached_page {
    my ( $c, $uri ) = @_;

    return undef unless $c->can( 'cache' );

    my $pc_config = $c->config->{'Plugin::PageCache'};
    my $is_debug  = $pc_config->{debug};
    
    # Warn if index was disabled
    my $index_page_key = $pc_config->{index_page_key} or do {
        $c->log->warn("clear_cached_page($uri) did not clear the cache because disable_index is set");
        return;
    };
    
    my $cache = $c->cache; # curry the cache just once, here

    my $index = $cache->get( $index_page_key ) || {};

    my $removed = 0;
    foreach my $index_key ( keys %$index ) {

        # find matching entries, ignoring the language prefix
        next unless $index_key =~ /^ $uri (?:\#.*)? $/x;

        # delete from the index and remove the corresponding cache entry
        # (which may have a different key, e.g., sha1 encoded)
        my $cache_key = delete $index->{$index_key};
        $cache->remove( $cache_key );
        $removed++;

        $c->log->debug( "Removed $index_key from page cache" ) if $is_debug;
    }

    $cache->set( $index_page_key, $index, $pc_config->{no_expire} )
        if $removed;

    $removed;
}


# return the time that the item should expire
sub _get_page_cache_expiration_time {
    my ($c, $options) = @_;
    my $pc_config = $c->config->{'Plugin::PageCache'};
    my $is_debug = $pc_config->{debug};

    my $expires;

    # Use the explicitely passed in duration if available.
    # XXX but why then ignore it if it's <= 0 ?
    if ($options->{cache_seconds} and $options->{cache_seconds} > 0) {
        $c->log->debug("expires in specified $options->{cache_seconds}s")
            if $is_debug;

        $expires = time() + $options->{cache_seconds};
    }
    # else {
    #   ... calculate expiry based on the response headers
    # }
    # If all else fails, fallback to the default 'expires' configuration value.
    else {
        $c->log->debug("expires in default $pc_config->{expires}s")
            if $is_debug;
        $expires = time() + $pc_config->{expires};
    }

    return $expires;
}


sub dispatch {
    my $c = shift;

    # only serve GET and HEAD request pages from cache
    # (never POST, PUT, DELETE etc)
    return $c->next::method(@_)
        unless $c->req->method =~ m/^(?:GET|HEAD)$/;

    my $pc_config = $c->config->{'Plugin::PageCache'};

    my $hook_name = $pc_config->{cache_dispatch_hook} || $pc_config->{cache_hook};
    my $hook = $hook_name ? $c->can($hook_name) : undef;
    return $c->next::method(@_) if ( $hook && !$c->$hook() );

    return $c->next::method(@_)
      if ( $pc_config->{auto_check_user}
        && $c->can('user_exists')
        && $c->user_exists);

    # check the page cache for a cached copy of this page
    return $c->next::method(@_)
        unless my $key = $c->_get_page_cache_key;

    my $cache = $c->cache; # curry the cache just once, here

    return $c->next::method(@_)
        unless my $data = $cache->get( $key );

    # Time to remove page from cache?

    if ( $data->{expire_time} && $data->{expire_time} <= time ) {
        if ( my $busy_lock = $pc_config->{busy_lock} ) {
            # Extend the expiration time for others while
            # this caller refreshes the cache
            $data->{expire_time} = time() + $busy_lock;
            
            $cache->set( $key, $data );
            
            $c->log->debug( "$key has expired, being refreshed for $busy_lock seconds" )
                if ($pc_config->{debug});
        }
        else {
            $c->log->debug( "Expiring $key from page cache" )
              if ($pc_config->{debug});

            $cache->remove( $key );

            if ( my $index_page_key = $pc_config->{index_page_key} ) {
                my $index = $cache->get( $index_page_key ) || {};
                my $found = delete $index->{ $data->{index_key} };
                $cache->set( $index_page_key, $index, $pc_config->{no_expire})
                    if $found;
            }
        }

        return $c->next::method(@_);
    }

    $c->log->debug("Serving $key from page cache, expires in "
          . ($data->{expire_time} - time)
          . " seconds")
        if ($pc_config->{debug});

    $c->_page_cache_used( 1 );

    # Check If-Modified-Since headers
    return 1 if $c->_page_cache_not_modified( $data );

    # Serve cached page

    $c->res->body( $data->{body} );

    $c->res->content_type( join '; ', @{$data->{content_type}} )
        if $data->{content_type};

    $c->res->content_encoding( $data->{content_encoding} )
        if $data->{content_encoding};

    $c->_set_page_cache_headers( $data );

    $c->res->header('X-PageCache', 'Catalyst');

}

# See if request matches last_modified date in cache
# if so, arrange to return a 304 Not Modified status
# and return true.

sub _page_cache_not_modified {
    my ( $c, $data ) = @_;

    if ( $c->req->headers->if_modified_since ) {

        if ( $c->req->headers->if_modified_since == $data->{create_time} ) {
            $c->res->status(304); # Not Modified
            $c->res->headers->remove_content_headers;
            $c->_set_page_cache_headers( $data );
            $c->res->body( '' );
            return 1;
        }
    }

    return;
}

# Sets cache headers for the page if set_http_headers is true.

sub _set_page_cache_headers {
    my ( $c, $data ) = @_;
    my $headers = $c->res->headers;
    my $pc_config = $c->config->{'Plugin::PageCache'};

    if ( $pc_config->{cache_headers} ) {
        for my $header_key ( keys %{ $data->{headers} || {} } ) {
            $headers->header(
                $header_key => $data->{headers}->{$header_key}
            );
        }
    }
    
    return unless $pc_config->{set_http_headers};

    if ( exists $data->{expires} ) {

        # page cache but not client cache
        if ( !$data->{expires} ) {
            $headers->header( 'Cache-Control' => 'no-cache' );
            $headers->header( 'Pragma' => 'no-cache' );
            return;
        }

        $headers->header(
            'Cache-Control' => "max-age=" . $data->{expires});

        $headers->expires( time + $data->{expires} );

    }
    else {

        $headers->header(
            'Cache-Control' => "max-age=" . ($data->{expire_time} - time));

        $headers->expires( $data->{expire_time} );
    }

    $headers->last_modified( $data->{create_time} )
        unless $c->res->status && $c->res->status == 304;
}

sub finalize {
    my $c = shift;

    # never cache POST requests
    return $c->next::method(@_) if ( $c->req->method eq "POST" );

    my $pc_config = $c->config->{'Plugin::PageCache'};

    my $hook_name = $pc_config->{cache_finalize_hook} || $pc_config->{cache_hook};
    my $hook = $hook_name ? $c->can($hook_name) : undef;
    return $c->next::method(@_) if ( $hook && !$c->$hook() );

    return $c->next::method(@_)
      if ( $pc_config->{auto_check_user}
        && $c->can('user_exists')
        && $c->user_exists);
    return $c->next::method(@_) if ( scalar @{ $c->error } );

    # if we already served the current request from cache, we can skip the
    # rest of this method
    return $c->next::method(@_) if ( $c->_page_cache_used );

    if (!$c->_cache_page
        && scalar @{ $pc_config->{auto_cache} })
    {

        # is this page part of the auto_cache list?
        my $path = "/" . $c->req->path;

        # For performance, this should be moved to setup, and generate a hash.
        AUTO_CACHE:
        foreach my $auto (@{ $pc_config->{auto_cache} })
        {
            next if $auto =~ m/^\d$/;
            if ( $path =~ /^$auto$/ ) {
                $c->log->debug( "Auto-caching page $path" )
                    if ($pc_config->{debug});
                $c->cache_page;
                last AUTO_CACHE;
            }
        }
    }

    if ($c->_cache_page) {
        my $data = $c->_store_page_in_cache($c->_cache_page) ;

        # Check for If-Modified-Since
        $c->_page_cache_not_modified( $data ) if $data;
    }

    return $c->next::method(@_);
}


sub _store_page_in_cache {
    my ($c, $options) = @_;

    my $key = $c->_get_page_cache_key;
    my $pc_config = $c->config->{'Plugin::PageCache'};
    my $now = time();

    my $headers = $c->res->headers;

    # Cache some additional metadata along with the content
    # Some caches don't support expirations, so we do it manually
    my $data = {
        body => $c->res->body || undef,
        content_type => [ $c->res->content_type ] || undef,
        content_encoding => $c->res->content_encoding || undef,
        create_time      => $options->{last_modified}
            || $headers->last_modified
            || $now,
        expire_time => $c->_get_page_cache_expiration_time($options),
    };

    return undef if $data->{expire_time} <= $now;

    $c->log->debug(
        "Caching page $key for ". ($data->{expire_time} - time()) ." seconds"
    ) if ($pc_config->{debug});
    
    if ( $pc_config->{cache_headers} ) {
        $data->{headers} = {
            map { $_ => $headers->header($_) } $headers->header_field_names
        };
    }

    if ($pc_config->{index_page_key}) {
        # We can't simply use $key for $index_key because $key may have been
        # mangled by sha1 and/or a key_maker hook.  We include $key to ensure
        # unique entries in the index in cases where a given uri might produce
        # different results eg due to headers like language.
        $data->{index_key}  = '/'.$c->req->path;
        $data->{index_key} .= '?'.$c->req->uri->query if $c->req->uri->query;
        $data->{index_key} .= '#'.$key;
    }

    if (exists $options->{expires}) {
        $data->{expires} = $options->{expires}
    }

    my $cache = $c->cache; # curry the cache just once, here

    $cache->set( $key, $data );

    $c->_set_page_cache_headers( $data );  # don't forget the first time

    if ( $data->{index_key} ) {
        # Keep an index cache of all pages that have been cached, for use
        # with clear_cached_page. This is error prone. See KNOWN ISSUES.
        my $index_page_key = $pc_config->{index_page_key};
        my $index = $cache->get($index_page_key) || {};
        $index->{ $data->{index_key} } = $key;
        $cache->set($index_page_key, $index, $pc_config->{no_expire});
    }

    return $data;
}


sub setup {
    my $c = shift;

    $c->next::method(@_);

    # allow code using old config key to work
    if ( $c->config->{page_cache} and !$c->config->{'Plugin::PageCache'} ) {
        $c->config->{'Plugin::PageCache'} = delete $c->config->{page_cache};
    }

    my $pc_config = $c->config->{'Plugin::PageCache'} ||= {};

    $pc_config->{auto_cache}       ||= [];
    $pc_config->{expires}          ||= 60 * 5;
    $pc_config->{cache_headers}    ||= 0;
    $pc_config->{set_http_headers} ||= 0;
    $pc_config->{busy_lock}        ||= 0;
    $pc_config->{debug}            ||= $c->debug;

    # default the page key to include the app name to give some measure
    # of protection if the cache doesn't have a namespace set.
    $pc_config->{index_page_key} = "$c._page_cache_index"
        unless defined $pc_config->{index_page_key};

    if (not defined $pc_config->{disable_index}) {
        warn "Plugin::PageCache config does not include disable_index, which currently defaults false but may default true in future\n";
        $pc_config->{disable_index} = 0;
    }
    $pc_config->{index_page_key} = undef
        if $pc_config->{disable_index};

    # detect the cache plugin being used and set appropriate
    # never-expires syntax
    if ( $c->can('cache') ) {

        # Newer C::P::Cache, cannot call $c->cache as a package method
        if ( $c->isa('Catalyst::Plugin::Cache') ) {
            return;
        }

        my $cache = $c->cache; # curry the cache just once, here

        # Older Cache plugins
        if ( $cache->isa('Cache::FileCache') ) {
            $pc_config->{no_expire} = "never";
        }
        elsif ($cache->isa('Cache::Memcached')
            || $cache->isa('Cache::FastMmap'))
        {

          # Memcached defaults to 'never' when not given an expiration
          # In FastMmap, it's not possible to set an expiration
            $pc_config->{no_expire} = undef;
        }
    }
    else {
        die __PACKAGE__ . " requires a Catalyst::Plugin::Cache plugin.";
    }
}

sub _get_page_cache_key {
    my $c = shift;
    
    # We can't rely on the params after the user's code has run,
    # so we cache the key created during the initial dispatch phase
    # and reuse it at finalize time.
    return $c->_page_cache_key if ( $c->_page_cache_key );

    # override key if required, else use uri path
    my $keymaker = $c->config->{'Plugin::PageCache'}->{key_maker};
    my $key = $keymaker ? $keymaker->($c) : "/" . $c->req->path;
    
    # prepend language if I18N present.
    if ( $c->can('language') ) {
        $key = ':' . $c->language . ':' . $key;
    }

    # some caches have limits on the max key length (eg for memcached it's 250
    # minus the namespace length) so if the key is a non-trvial length then
    # replace the tail with a sha1. (We only replace the tail because it's
    # useful to be able to see the leading portion of the path in the debug logs)
    if (length($key) > 100) {
        substr($key, 100) = Digest::SHA1::sha1_hex($key); # 40 bytes
    }
    # Check for spaces as it's cheap insurance, just in case, for memcached
    $key =~ s/\s/~/g;

    # we always sha1 the parameters/query as they're typically long
    # and it also avoids issues like spaces in keys for memcached
    my $params_key;
    my $parameters = $c->req->parameters;
    if (%$parameters) {
        local $Storable::canonical = 1;
        $params_key = Storable::nfreeze($parameters);
    }
    elsif ( my $query = $c->req->uri->query ) {
        $params_key = $query;
    }
    # use sha1 to avoid problems with over-long params or params
    # containing values that can't be used as a key (eg spaces for memcached)
    $key .= '?' . Digest::SHA1::sha1_hex($params_key) # 40 bytes
        if $params_key;

    $c->_page_cache_key( $key );

    return $key;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::PageCache - Cache the output of entire pages

=head1 SYNOPSIS

    use Catalyst;
    MyApp->setup( qw/Cache::FileCache PageCache/ );

    __PACKAGE__->config(
        'Plugin::PageCache' => {
            expires => 300,
            set_http_headers => 1,
            auto_cache => [
                '/view/.*',
                '/list',
            ],
            debug => 1,

            # Optionally, a cache hook method to be called prior to dispatch to
            # determine if the page should be cached.  This is called both
            # before dispatch, and before finalize.
            cache_hook => 'some_method',

            # You may alternatively set different methods to be used as hooks
            # for dispatch and finalize. The dispatch method will determine
            # whether the currently cached page will be displayed to the user,
            # and the finalize hook will determine whether to save the newly
            # created page.
            cache_dispatch_hook => 'some_method_for_dispatch',
            cache_finalize_hook => 'some_method_for_finalize',
        }
    );
    
    sub some_method {
        my $c = shift;
        if ( $c->user_exists and $c->user->some_field ) {
            return 0; # Don't cache
        }
        return 1; # Cache
    }

    # in a controller method
    $c->cache_page( '3600' );

    $c->clear_cached_page( '/list' );

    # Expire at a specific time
    $c->cache_page( $datetime_object );


    # Fine control
    $c->cache_page(
        last_modified   => $last_modified,
        cache_seconds   => 24 * 60 * 60,    # once a day
        expires         => 300,             # allow client caching
    );

=head1 DESCRIPTION

Many dynamic websites perform heavy processing on most pages, yet this
information may rarely change from request to request.  Using the PageCache
plugin, you can cache the full output of different pages so they are served to
your visitors as fast as possible.  This method of caching is very useful for
withstanding a Slashdotting, for example.

This plugin requires that you also load a Cache plugin.  Please see the Known
Issues when choosing a cache backend.

=head1 WARNINGS

PageCache should be placed at the end of your plugin list.

You should only use the page cache on pages which have NO user-specific or
customized content.  Also, be careful if caching a page which may forward to
another controller.  For example, if you cache a page behind a login screen,
the logged-in version may be cached and served to unauthenticated users.

Note that pages that result from POST requests will never be cached.

=head1 PERFORMANCE

On my Athlon XP 1800+ Linux server, a cached page is served in 0.008 seconds
when using the HTTP::Daemon server and any of the Cache plugins.

=head1 CONFIGURATION

Configuration is optional.  You may define the following configuration values:

    expires => $seconds

This will set the default expiration time for all page caches.  If you do not
specify this, expiration defaults to 300 seconds (5 minutes).

    cache_headers => 1

Enable this value if you need your cached responses to include custom HTTP
headers set by your application.  This may be necessary if you operate behind
an edge cache such as Akamai.  This option is disabled by default.

    set_http_headers => 1

Enabling this value will cause Catalyst to set the correct HTTP headers to
allow browsers and proxy servers to cache your page.  This will further reduce
the load on your server.  The headers are set in such a way that the
browser/proxy cache will expire at the same time as your cache.  The
Last-Modified header will be preserved if you have already specified it.  This
option is disabled by default.

    auto_cache => [
        $uri,
    ]

To automatically cache certain pages, or all pages, you can specify auto-cache
URIs as an array reference.  Any controller within your application that
matches one of the auto_cache URIs will be cached using the default expiration
time.  URIs may be specified as absolute: '/list' or as a regex: '/view/.*'

    disable_index => 1

To support the L</clear_cached_page> method, PageCache attempts keep an index
of all cached pages. This adds overhead by performing extra cache reads and
writes to maintain the (possibly very large) page index. It's also not
reliable, see L</KNOWN ISSUES>.

If you don't intend to use C<clear_cached_page>, you should enable this config
option to avoid the overhead of creating and updating the cache index.  This
option is currently disabled (i.e. the page index is enabled) by default but
that may change in a future release.

    index_page_key => '...'

The key string used for the index, Defaults to a string that includes the name
of the Catalyst app class.

    busy_lock => 10

On a high traffic site where page re-generation may take many seconds, a common
problem encountered is the "dog-pile" effect, where many concurrent connections all
hit a page where the cache has expired and all perform the same expensive operation
to rebuild the cache.  To prevent this situation, you can set the busy_lock option
to the maximum number of seconds any of your pages can be expected to take to
rebuild the cache.  Then, when the cache expires, the first request will rebuild the
cache while also extending the expiration time by the number of seconds specified,
allowing other requests that arrive before the cache has been rebuilt to use the
previously cached page.  This option is disabled by default.

    debug => 1

This will print additional debugging information to the Catalyst log.  You will
need to have -Debug enabled to see these messages.

    auto_check_user => 1

If this option is enabled, automatic caching is disabled for logged in users
i.e., if the app class has a user_exists() method and it returns true.

    cache_hook => 'cache_hook_method'
    cache_finalize_hook => 'cache_finalize_hook_method'
    cache_dispatch_hook => 'cache_dispatch_hook_method'

Calls a method on the application that is expected to return a true or false.
This method is called before dispatch, and before finalize so you can short
circuit the pagecache behavior.  As an example, if you want to disable
PageCache while running under debug mode:
   
    package MyApp;
    
    ...
    
    sub cache_hook_method { return shift->debug; }

Or, if you want to not cache for certain roles, say "admin":
    
    sub cache_hook_method {
        my ( $c ) = @_;
        return !$c->check_user_roles('admin');
    }

Note that this is called BEFORE auto_check_user, so you have more flexibility
to determine what to do for not logged in users.

To override the generation of page keys:

    __PACKAGE__->config(
        'Plugin::PageCache' => {
            key_maker => sub {
                my $c = shift;
                return $c->req->base . '/' . $c->req->path;
            }
        }
    );

C<key_maker> can also be the name of a method, which will be invoked as C<<$c->$key_maker>>.

In most cases you would use a single cache_hook method for consistency.

It is possible to achieve background refreshing of content by disabling
caching in cache_dispatch_hook and enabling caching in cache_finalize_hook
for a specific IP address (say 127.0.0.1).

A cron of wget "http://localhost/foo.html" would cause the content to be
generated fresh and cached for future viewers. Useful for content which 
takes a very long time to build or pages which should be refreshed at
a specific time such as always rolling over content at midnight.

=head1 METHODS

=head2 cache_page

Call cache_page in any controller method you wish to be cached.

    $c->cache_page( $expire );

The page will be cached for $expire seconds.  Every user who visits the URI(s)
referenced by that controller will receive the page directly from cache.  Your
controller will not be processed again until the cache expires.  You can set
this value to a low value, such as 60 seconds, if you have heavy traffic, to greatly
improve site performance.

Pass in a DateTime object to make the cache expire at a given point in time.

    $two_hours = DateTime->now->add( hours => 2 );
    $c->cache_page( $two_hours );

The page will be stored in the page cache until this time.

If set_http_headers is set then Expires and Cache-Control headers will
also be set to expire at the given date as well.

Pass in a list or hash reference for finer control.

    $c->cache_page(
        last_modified   => $last_modified,
        cache_seconds   => 24 * 60 * 60,
        expires         => 30,
    );

This allows separate control of the page cache and the header cache
values sent to the client.

Possible options are:

=over 4

=item cache_seconds

This is the number of seconds to keep the page in the page cache, which may be
different (normally longer) than the time that client caches may store the page.
This is the value set when only a single parameter is passed.

=item expires

This is the length of time in seconds that a client may cache the page
before revalidating (by asking the server if the document has changed).

Unlike above, this is a fixed setting that each client will see.  Regardless of
how much longer the page will be cached in the page cache the client still sees
the same expires time.

Setting zero (0) for expires will result in the page being cached, but headers
will be sent telling the client to not cache the page.  Allows caching expensive
content to generate, but any changes will be seen right away.

=item last_modified

Last modified time in epoch seconds.  If not set will use either the
current Last-Modified header, or if not set, the current time.

=back

=head2 clear_cached_page

To clear the cached pages for a URI, you may call clear_cached_page.

    $c->clear_cached_page( '/view/userlist' );
    $c->clear_cached_page( '/view/.*' );
    $c->clear_cached_page( '/view/.*\?.*\bparam=value\b' );

This method takes an absolute path or regular expression.
Returns the number of matching entries found in the index.
A warning will be generated if the page index is disabled (see L</CONFIGURATION>).

The argument is matched against all the keys in the page index.
The page index keys include the request path and query string, if any.

Typically you'd call this from a different controller than the cached
controller. You may for example wish to build an admin page that lets you clear
page caches.

=head1 INTERNAL EXTENDED METHODS

=head2 dispatch

C<dispatch> decides whether or not to serve a particular request from the cache.

=head2 finalize

C<finalize> caches the result of the current request if needed.

=head2 setup

C<setup> initializes all default values.

=head1 I18N SUPPORT

If your application uses L<Catalyst::Plugin::I18N> for localization, a
separate cache key will be used for each language a page is displayed in.

=head1 KNOWN ISSUES

The page index, used to support the L</clear_cached_page> method is unreliable
because it uses a read-modify-write approach which will loose data if more than
one process attempts to update the page index at the same time.

It is not currently possible to cache pages served from the Static plugin.  If
you're concerned enough about performance to use this plugin, you should be
serving static files directly from your web server anyway.

Cache::FastMmap does not have the ability to specify different expiration times
for cached data.  Therefore, if your MyApp->config->{cache}->{expires} value is
set to anything other than 0, you may experience problems with the
clear_cached_page method, because the cache index may be removed.  For best
results, you may wish to use Cache::FileCache or Cache::Memcached as your cache
backend.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Cache::FastMmap>,
L<Catalyst::Plugin::Cache::FileCache>,
L<Catalyst::Plugin::Cache::Memcached>

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 THANKS

Bill Moseley, <mods@hank.org>, for many patches and tests.

Roberto Henríquez, <roberto@freekeylabs.com>, for i18n support.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
