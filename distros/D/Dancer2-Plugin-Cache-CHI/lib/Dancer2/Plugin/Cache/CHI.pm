package Dancer2::Plugin::Cache::CHI;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Dancer plugin to cache response content (and anything else)
$Dancer2::Plugin::Cache::CHI::VERSION = '2.0.0';
use strict;
use warnings;
use Carp;
use CHI;
use List::MoreUtils qw/ any /;

use Dancer2::Plugin;

plugin_hooks 'before_create_cache';

# actually hold the ref to the args
has _cache_page => (
    is        => 'rw',
    clearer   => 'clear_cache_page',
    predicate => 'has_cache_page',
);

has cache_page_key_generator => (
    is             => 'rw',
    lazy           => 1,
    plugin_keyword => 1,
    default        => sub {
        sub { $_[0]->app->request->path }
    },
);

sub BUILD {
    my $plugin = shift;

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub {
                return unless $plugin->has_cache_page;

                my $resp = shift;
                $plugin->cache->set( $plugin->cache_page_key_generator->($plugin),
                    {
                        status      => $resp->status,
                        headers     => $resp->headers_to_array,
                        content     => $resp->content
                    },
                    @{$plugin->_cache_page},
                );

                $plugin->clear_cache_page;
            }
    ));

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                $plugin->clear_cache_page;
            }
    ));
};

has _caches => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        {}
    },
);

has caches_with_honor => (
    is      => 'ro',
    default => sub{ {} },
);

plugin_keywords 'cache';

sub cache {
    my( $self, $namespace ) = @_;
    $namespace //= '';
    return $self->_caches->{$namespace} ||= _create_cache( $self, $namespace, @_ );
};

sub _create_cache {
    my( $dsl, $namespace, $args ) = @_;
    $args ||= {};

    $dsl->execute_hook( 'plugin.cache_chi.before_create_cache' );

    my %setting = ( %{ $dsl->config }, %$args );

    $setting{namespace} //= $namespace;

    $dsl->caches_with_honor->{$namespace} = delete $setting{honor_no_cache};

    return CHI->new(%setting);
}


plugin_keywords check_page_cache => sub {
    my $dsl = shift;

    my $hook = sub {
        my $context = shift;

        # Instead halt() now we use a more correct method - setting of a
        # response to Dancer2::Core::Response object for a more correct returning of
        # some HTTP headers (X-Powered-By, Server)

        my $cached = cache($dsl)->get( $dsl->cache_page_key_generator->($dsl) )
            or return;

        if ( $dsl->caches_with_honor->{''} ) {

            my $req =  $dsl->app->request;

            no warnings 'uninitialized';

            return if any {
                $req->header($_) eq 'no-cache'
            } qw/ Cache-Control Pragma /;
        }

        $context->set_response(
        	Dancer2::Core::Response->new(
                is_halted => 1,
                ref $cached eq 'HASH'
                ?
                ( map { $_ => $cached->{$_} } qw/ status headers content / )
                :
                ( content => $cached )
            )
		);
    };

    $dsl->app->add_hook( Dancer2::Core::Hook->new(
        name => 'before',
        code => $hook,
    ));
};

plugin_keywords cache_page => sub {
    my ( $plugin, $content, @args ) = @_;

    $plugin->_cache_page(\@args);

    return $content;
};

plugin_keywords cache_page_key => sub { $_[0]->cache_page_key_generator->($_[0]) };

for my $method ( qw/ set get remove clear compute / ) {
    plugin_keywords "cache_$method" => sub {
        my $plugin = shift;
        $plugin->cache->$method(@_);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Cache::CHI - Dancer plugin to cache response content (and anything else)

=head1 VERSION

version 2.0.0

=head1 SYNOPSIS

In your configuration:

    plugins:
        'Cache::CHI':
            driver: Memory
            global: 1

In your application:

    use Dancer2;
    use Dancer2::Plugin::Cache::CHI;

    # caching pages' response

    check_page_cache;

    get '/cache_me' => sub {
        cache_page template 'foo';
    };

    # using the helper functions

    get '/clear' => sub {
        cache_clear;
    };

    put '/stash' => sub {
        cache_set secret_stash => request->body;
    };

    get '/stash' => sub {
        return cache_get 'secret_stash';
    };

    del '/stash' => {
        return cache_remove 'secret_stash';
    };

    # using the cache directly

    get '/something' => sub {
        my $thingy = cache->compute( 'thingy', sub { compute_thingy() } );

        return template 'foo' => { thingy => $thingy };
    };

=head1 DESCRIPTION

This plugin provides Dancer2 with an interface to a L<CHI> cache. Also, it
includes a mechanism to easily cache the response of routes.

=head1 CONFIGURATION

Unrecognized configuration elements are passed directly to the L<CHI> object's
constructor. For example, the configuration given in the L</SYNOPSIS>
will create a cache object equivalent to

    $cache = CHI->new( driver => 'Memory', global => 1, );

=head2 honor_no_cache

If the parameter 'C<honor_no_cache>' is set to true, a request with the http
header 'C<Cache-Control>' or 'C<Pragma>' set to 'I<no-cache>' will ignore any
content cached via 'C<cache_page>' and will have the page regenerated anew.

=head1 KEYWORDS

=head2 cache

Returns the L<CHI> cache object.

=head2 cache $namespace, \%args

L<CHI> only allows one namespace per object. But you can create more caches by
using I<cache $namespace, \%args>. The new cache uses the arguments as defined in
the configuration, which values can be overriden by the optional arguments
(which are only used on the first invocation of the namespace).

    get '/memory' => sub {
        cache('elephant')->get( 'stuff' );
    };

    get '/goldfish' => sub {
        cache( 'goldfish' => { expires_in => 300 } )->get( 'stuff' );
    };

Note that all the other keywords (C<cache_page>, C<cache_set>, etc) will still
use the main cache object.

=head2 check_page_cache

If invoked, returns the cached response of a route, if available.

The C<path_info> attribute of the request is used as the key for the route,
so the same route requested with different parameters will yield the same
cached content. Caveat emptor.

=head2 cache_page($content, $expiration)

Caches the I<$content> to be served to subsequent requests.
The headers and http status of the response are also cached.

The I<$expiration> parameter is optional.

=head2 cache_page_key

Returns the cache key used by 'C<cache_page>'. Defaults to
to the request's I<path_info>, but can be modified via
I<cache_page_key_generator>.

=head2 cache_page_key_generator( \&sub )

Sets the function that generates the cache key for I<cache_page>.

For example, to have the key contains both information about the request's
hostname and path_info (useful to deal with multi-machine applications):

    cache_page_key_generator sub {
        return join ':', request()->host, request()->path_info;
    };

=head2 cache_set, cache_get, cache_remove, cache_clear, cache_compute

Shortcut to the cache's object methods.

    get '/cache/:attr/:value' => sub {
        # equivalent to cache->set( ... );
        cache_set $params->{attr} => $params->{value};
    };

See the L<CHI> documentation for further info on these methods.

=head1 HOOKS

=head2 before_create_cache

Called before the creation of the cache, which is lazily done upon
its first use.

Useful, for example, to change the cache's configuration at run time:

    use Sys::Hostname;

    # set the namespace to the current hostname
    hook before_create_cache => sub {
        config->{plugins}{'Cache::CHI'}{namespace} = hostname;
    };

=head1 SEE ALSO

Dancer2 Web Framework - L<Dancer2>

L<CHI>

L<Dancer::Plugin::Memcached> - plugin that heavily inspired this one.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
