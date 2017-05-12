package Dancer::Plugin::MemcachedFast;
$Dancer::Plugin::MemcachedFast::VERSION = '0.161360';
use strict;
use warnings;

# ABSTRACT: Dancer::Plugin::MemcachedFast - Cache things using Cache::Memcached::Fast

use Dancer::Plugin;

use Cache::Memcached::Fast;

my $default_timeout = 3600;
my $ok_to_compress  = 0;
my $cache           = do {
    my $config = plugin_setting;
    $config->{servers} = [$ENV{HAVE_TEST_MEMCACHED_SERVER_LOCALHOST}]
        if exists $ENV{HAVE_TEST_MEMCACHED_SERVER_LOCALHOST};
    $default_timeout = delete $config->{default_timeout}
        if exists $config->{default_timeout};
    $ok_to_compress =
        (       defined $config->{compress_threshold}
            and int($config->{compress_threshold}) > 1
            and defined $config->{compress_method});
    Cache::Memcached::Fast->new($config);
};

register memcached_compress => sub {
    unless ($ok_to_compress) {
        warn
            "Cannot compress. Check the 'compress_threshold' and 'compress_method' configuration options";
        return;
    }
    $cache->compress(!!$_[0]);
};

register memcached_get_or_set => sub {
    $cache->get($_[0]) or do {
        my $ret;
        $cache->set(
            $_[0],
            $ret = ref $_[1] eq 'CODE' ? $_[1]->() : $_[1],
            defined $_[2] ? $_[2] : $default_timeout
        );
        $ret;
        }
        or $_[1];
};

register memcached_get => sub {
    return $cache->get($_[0]) if $#_ == 0 and !ref $_[0];
    $cache->get_multi(map { ref $_ and ref $_ eq 'ARRAY' ? @$_ : $_ } @_);
};

register memcached_gets => sub {
    return $cache->gets($_[0]) if $#_ == 0 and !ref $_[0];
    $cache->gets_multi(map { ref $_ and ref $_ eq 'ARRAY' ? @$_ : $_ } @_);
};

register memcached_set => sub {
    return $cache->set(
        $_[0],
        ref $_[1] eq 'CODE' ? $_[1]->() : $_[1],
        defined $_[2]       ? $_[2]     : $default_timeout
    ) if ref $_[0] ne 'ARRAY';
    $cache->set_multi(
        map { [
                $_->[0],
                ref $_->[1] eq 'CODE' ? $_->[1]->() : $_->[1],
                defined $_->[2]       ? $_->[2]     : $default_timeout
            ]
        } grep { ref $_ eq 'ARRAY' } @_
    );
};

register memcached_add => sub {
    return $cache->add(
        $_[0],
        ref $_[1] eq 'CODE' ? $_[1]->() : $_[1],
        defined $_[2]       ? $_[2]     : $default_timeout
    ) if ref $_[0] ne 'ARRAY';
    $cache->add_multi(
        map { [
                $_->[0],
                ref $_->[1] eq 'CODE' ? $_->[1]->() : $_->[1],
                defined $_->[2]       ? $_->[2]     : $default_timeout
            ]
        } grep { ref $_ eq 'ARRAY' } @_
    );
};

register memcached_replace => sub {
    return $cache->replace(
        $_[0],
        ref $_[1] eq 'CODE' ? $_[1]->() : $_[1],
        defined $_[2]       ? $_[2]     : $default_timeout
    ) if ref $_[0] ne 'ARRAY';
    $cache->replace_multi(
        map { [
                $_->[0],
                ref $_->[1] eq 'CODE' ? $_->[1]->() : $_->[1],
                defined $_->[2]       ? $_->[2]     : $default_timeout
            ]
        } grep { ref $_ eq 'ARRAY' } @_
    );
};

register memcached_delete => sub {
    return $cache->delete($_[0]) if $#_ == 0 and !ref $_[0];
    $cache->delete_multi(map { (ref $_ and ref $_ eq 'ARRAY') ? @$_ : $_ } @_);
};

register memcached_append => sub {
    return $cache->append(@_) if ($#_ == 1 and !ref $_[0] and !ref $_[1]);
    $cache->append_multi(grep { ref $_ eq 'ARRAY' } @_);
};

register memcached_prepend => sub {
    return $cache->prepend(@_) if ($#_ == 1 and !ref $_[0] and !ref $_[1]);
    $cache->prepend_multi(grep { ref $_ eq 'ARRAY' } @_);
};

register memcached_incr => sub {
    return $cache->incr(@_) if ($#_ <= 2 and scalar grep { !ref $_ } @_);
    $cache->incr_multi(grep { ref $_ eq 'ARRAY' } @_);
};

register memcached_decr => sub {
    return $cache->decr(@_) if ($#_ <= 2 and scalar grep { !ref $_ } @_);
    $cache->decr_multi(grep { ref $_ eq 'ARRAY' } @_);
};

register memcached_flush_all => sub {
    $cache->flush_all(@_);
};

register memcached_nowait_push => sub {
    $cache->nowait_push;
};

register memcached_server_versions => sub {
    $cache->server_versions;
};

register memcached_disconnect_all => sub {
    $cache->disconnect_all;
};

register memcached_namespace => sub {
    $cache->namespace($_[0]);
};

register_plugin;

1;

__END__

=head1 NAME

Dancer::Plugin::MemcachedFast - Cache things using Cache::Memcached::Fast

=head1 SYNOPSIS

This plugin allows Dancer to use L<Cache::Memcached::Fast> to get and store content
on a number of memcached servers.

Add the following to your configuration file to enable the plugin:

    plugins:
        MemcachedFast:
            servers:
                - "127.0.0.1:11211"
                - "127.0.0.1:22122"
            default_timeout: 3600
            namespace: "myapp:"

The options that can be used are the same as the parameters to the C<new>
constructor of L<Cache::Memcached::Fast>, apart from C<default_timeout>.

The C<default_timeout> parameter defaults to 3600 seconds. It allows you to
specify a time, in seconds, after which you would like keys to expire from the
cache.

It accepts the same options that L<Cache::Memcached::Fast> accepts.

In your app:

    package MyApp;
    use Dancer;
    use Dancer::Plugin::MemcachedFast;

    # Simply fetch the index from memcached if found,
    # or set the cache to the parsed index template
    get '/' => sub {
        memcached_get_or_set('index', sub {
            template 'index';
        });
    };

    # The login page can be shown from the cache,
    # whereas if a user is logged in the cache is
    # user-specific
    get '/admin' => sub {
        unless (session->{username}) {
            return memcached_get_or_set('admin_login', sub {
                template 'admin_login';
            });
        };
        memcached_get_or_set('admin-home-' . session->{username}, sub {
            template 'admin_home';
        });
    };

    # Use memcache to cache bits of information only,
    # for a specific amount of seconds
    get '/articles' => sub {
        my $articles = memcached_get_or_set('articles-list', sub {
            # use DBI to fetch last 10 articles
            my @last_10_articles = ...;
            return \@last_10_articles
        }, 300);
        template 'articles_list' => { articles => $articles };
    };

    # forcibly delete a number of keys from the cache
    get '/admin/PANIC' => {
        return redirect '/admin'
            unless session->{username};
        memcached_delete(
            qw/articles_list admin_login/,
            'admin-home-' . session->{username},
        );
        redirect '/admin';
    };

    # set a cache to a specified value unconditionally
    get '/admin/meaningoflife' => sub {
        return redirect '/admin'
            unless session->{username};
        memcached_set('meaning', 42);
        redirect '/admin';
    };

    # get a value from the cache, who cares if it isn't there?!
    get '/admin/maybe' => sub {
        my $meaning = memcached_get('meaningoflife');
        template 'meaning' => { meaning => $meaning };
    };

=head1 DESCRIPTION

This plugin allows Dancer to use L<Cache::Memcached::Fast> to get and store content
on a number of memcached servers.

=head1 TIMEOUTS

You can set the default timeout via the configuration, as explained in the
L<SYNOPSIS> section. The default is 3600 seconds.

If you want to cache a value for as long as there is memory available to
Memcache, you can achieve that by passing C<0> as the expiration parameter (not
C<undef>, as that just uses the C<default_timeout>).

=head1 KEYWORDS

=head2 memcached_get_or_set

Will check whether the specified key is found in the cache and
return it where available. Otherwise it will set it to either the
value given, or will call the coderef given ans set it to the value
returned by the coderef. It will be cached either for the default
number of seconds, or the number of seconds given.

    # returns the value on memcached for 'keyname' if found, or
    # sets the 'keyname' to the value 42 and its expiration to 300 seconds
    memcached_get_or_set('key name', sub { 42 }, 300);
    memcached_get_or_set('key name', 42, 300);
    memcached_get_or_set('key name', [42], 300);

=head2 memcached_get

Attempts to get a value from memcached, and returns it. Uses C<get_multi>
if given more than one value to get. Expands arrayrefs where needed.

    my $maybe  = memcached_get('key');
    my $values = memcached_get(qw/keya keyb keyc/);
    $values = memcached_get([qw/keya keyb keyc/], 'keyd', ['keye','keyf']);

=head2 memcached_gets

Retries the value and its CAS for the key given. Uses C<gets_multi>
if given more than one value to get. Expands arrayrefs where needed.

=head2 memcached_set

Sets unconditionally a key to a given value. A coderef may be used also,
and its return value will be used. Alternatively, provide an arrayref
for it to use C<set_multi> on it. Takes an optional third value indicating
the number of seconds the key will be cached for, or the default number
of seconds. You can use an expiration value of C<0> to mean that the value
should never expire from the cache.

    memcached_set('meaningoflife', 42);
    memcached_set('meaningoflife', sub { 21 * 2 });
    # "meaningoflife" will be cached for the default number of seconds:
    memcached_set(['meaningoflife',42],['test',1234,300]);
    memcached_set(['test',sub{42},123],['abc','def']);

=head2 memcached_add

Similar to C<memcached_set>, but only operates if the key is B<not> already
stored in memcached.

=head2 memcached_replace

Similar to C<memcached_set>, but only operates if the key B<is> already stored
in memcached.

=head2 memcached_delete

Forcibly expunges one or more keys from the cache.

    memcached_delete('meaningoflife');
    memcached_delete('meaningoflife','test');
    memcached_delete( [ 'abc', 'def' ], [ 'xyz' ] );
    memcached_delete( [ 'abc', 'def' ], 'xyz' );

=head2 memcached_append

Appends the given string to the already stored scalar value.  See
L<Cache::Memcached::Fast>'s method C<append> and C<append_multi>. C<append> is
used if the two given parameters are scalars, C<append_multi> will be used if
they are arrayrefs.

    memcached_set( 'meaningoflife', '4' );
    memcached_append( 'meaningoflife', '2' );
    my $fourtytwo = memcached_get('meaningoflife');
    memcached_append(['meaningoflife',42],['answer','whoknows']);

=head2 memcached_prepend

Same as C<append_multi>, but works at the beginning of the string.

=head2 memcached_incr

Increments the key given by 1 or the optional value given. Can operate
on arrayrefs, using C<incr_multi>.

=head2 memcached_decr

Same as C<memcached_incr> but decrements.

=head2 memcached_flush_all

Invalidates all caches the client knows about. See L<Cache::Memcached::Fast>'s
C<flush_all> method.

=head2 memcached_nowait_push

Pushes all the pending request to the server(s), see L<Cache::Memcached::Fast>'s
C<nowait_push> method.

=head2 memcached_server_versions

Returns the versions of the servers the plugin is connected to.

=head2 memcached_disconnect_all

Just in case your program forks and needs to disconnect them

=head2 memcached_compress

Needs a boolean, to enable or disable the compression.  In order to work, the
configuration options C<compress_threshold> and C<compress_methods> need to be
pgiven. See L<Cache::Memcached::Fast> for the options.

    memcached_compress(42); # true, starts compressing
    memcached_compress(1);  # true, starts compressing
    memcached_compress(''); # false, stops compressing
    memcached_compress(0);  # false, stops compressing

=head2 memcached_namespace

Either returns the current namespace prefix, or sets it to the given value and
returns the old value.

    my $current_prefix = memcached_namespace;
    my $old_prexix     = memcached_namespace('test:');
    # $current_prefix eq $old_prefix
    $current_prefix = memcached_namespace;
    # $current_prefix eq 'test:'

=head1 CONTRIBUTORS

Nikolay Mishin <mi@ya.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Marco FONTANI.
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
