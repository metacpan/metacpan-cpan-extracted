package Attribute::Cached;
our $VERSION = 0.02;

=head1 NAME

Attribute::Cached - easily cache subroutines results using a :Cached attribute

=head1 SYNOPSIS

    sub getCache { return $global_cache }

    sub foo :Cached(60) { ... }
    sub bar :Cached(time=>30, key=>\&keygen) { ... }

    # or supply a specific cache
    sub baz :Cached(time=>20, cache=>$cache) { ... }

=head1 DESCRIPTION

In many applications, including web apps, caching data is used to help scale
the sites, trading a slight lack of immediacy in results with a lower load on
DB and other resources.

Usually we'll do something like this

    sub my_query {
        my ($self, %pars) = @_;
         # get a cache
        my $cache = $self->get_cache;
         # generate a key: for example with %pars (foo=>1), we might use
         #                 the key "my_query:foo=1";
        my $key = $self->get_key( %pars ); 
        my $result;
         # check if we've already cached this call, and return if so
        if ($result = $cache->get($key)) {
            warn "Cache hit for $key";
            return $result;
        }
         # The next lines are what this subroutine is /actually/ doing
        $result = $self->expensive_operation;
        # ... additional processing as required

         # set the result in the cache for future accesses
        $cache->set($key, $result, 20); # hard code a cache time here

        return $result;
    }

The caching logic is repeated boilerplate and, worse, really has nothing
to do with what we're trying to achieve here.  With L<Attribute::Cached>
we'd write this as:

    sub getCache { my $self = shift; return $self->get_cache(@_) }

    sub my_query :Cached(time=>20, key=>\&get_key) {

        my $result = $self->expensive_operation;
        # ... additional processing as required

        return $result;
    }

=head1 ATTRIBUTE VALUES

The C<:Cached> attribute takes the following parameters

=over 4

=item C<time>

The cache time.  This is often a value in seconds.  But some cache interfaces
require a string like "5 secs".  Either an integer or any expression parseable
by L<Attribute::Handlers> can be passed in (for example a constant).

If time is the only attribute required, the shortcut form C<:Cached(CACHE_TIME)>
is supported too.  Alternatively, see the hook C<getCacheTime> to set this
dynamically.

=item C<cache>

The cache must be a "standard" type, conforming to the same interface
as C<Cache::Cache>.  That is, it should have the usual C<get> and C<set>
methods.  Specifics can vary (like Cachetime handling, which is specified
differently for memcached).

If there is a default cache set in a global variable, you can pass it
in like so

    :Cached(cache=>$cache)

Most likely you will want to define the hook C<getCache> instead.

=item C<key>

This is a method name or subroutine reference that will generate the
appropriate key.  There is a default behaviour for this, but it is
to join all arguments with commas (including the stringified $self,
which is likely not what you want.  So this default behaviour may
be subject to change in future versions.)

The method is dispatched via the package name, and will be passed

    - package name
    - subroutine name
    - original args passed (including $self if this is an OO method)

If you wanted a single cache key, you could always use 
C<:Cached(key=>sub{'foo'}})>.

If all the methods in your package use the same keygen, you could
define the L<getCacheKey> hook instead.

=item C<transform>

Usually caches set and return a single scalar value.  The subroutine
you want to clean up using this module might have had logic with
C<wantarray> for example.  Setting a transform subroutine lets you do
this.

    sub refOrArray { wantarray ? @$_[0] : $_[0]; }
    sub foo :Cached(time=>20, transform=>\&refOrArray) { ... }

You cannot pass a method name to be dispatched (for what seemed like
good reasons at the time: patches welcome if that's sufficiently annoying
to anyone).  However you can define a global hook C<cacheTransform> 
for your package.

=back

=head2 Hooks

You can define several methods in your class or base class to
avoid having to type repeated code.

=over 4

=item C<getCacheTime>

Define this method to return a cache time dynamically.  The package
and subroutine name are prepended to the original arguments.

    sub getCacheTime {
        my ($package, $subname, %args) = @_;
        return 20 if $subname eq 'query';
        return 60;
    }

=item C<getCache>

Define this method to return a cache (of the sort specified under L<cache>
above.

Only the original arguments are passed.  (This behaviour may change).
For example, for a Catalyst method which is passed ($self, $c, %args) you might
do:

    sub getCache {
        my ($self, $c) = @_;
        return $c->model('Cache');
    }

=item C<getCacheKey>

Define this method to determine the cache key for the method call.
As we don't know whether we're dealing with a sub or a method call,
the default implementation doesn't try to do anything clever.  For
now you'd probably want to define something like this:

    sub getCacheKey {
        my ($package, $subname, $self, %args) = @_;
        return join ':', $package, $subname,
            map { "$_=$args{$_}" } keys %args;
    }

The default behaviour may change.

=item C<cacheTransform>

This is the analogue to the C<transform> parameter above.

=back

=cut

use warnings;
use strict;
use Attribute::Handlers;

use constant DEBUG=>0;

sub UNIVERSAL::Cached :ATTR(CODE) {
    my ($pkg, $symbol, $options) = @_[0,1,4];

    my %config;
    if (ref $options eq 'ARRAY') {
        %config = @$options
    } else {
        %config = (time => $options);
    }
    my $name = *{$symbol}{NAME};
    my $code = *{$symbol}{CODE};

    my $sub = encache($pkg, $name, $code, %config);
    my $subname = "${pkg}::${name}";
    warn "Installing into $subname" if DEBUG;
    no strict 'refs';
    no warnings 'redefine';
    *{$subname} = $sub;
}

sub encache {
    my ($pkg, $name, $code, %config) = @_;
    return unless my $ct 
        = $config{time} || $pkg->can('getCacheTime');

    warn "code is $name, $code" if DEBUG;

    my $getCache      = $config{cache}     || $pkg->can('getCache');
    my $getCacheKey   = $config{key}       
                     || $pkg->can('getCacheKey') 
                     || \&getCacheKeyDefault;
    my $transform     = $config{transform} || $pkg->can('cacheTransform');

    my $sub = sub {
        # give the anonymous sub a name
        # (alternatively, use Sub::Named, as suggested by Ash)
        local *__ANON__ = "Cached($name)";
        my $cache = literalOrCall($getCache, @_);
        my $key   = $pkg->$getCacheKey( $name, @_ );

        my $result = $cache->get( $key );
        if ($result) {
            warn "Cache($name) hit for $key => $result" if DEBUG;
        } else {
            warn "Cache($name) miss for $key" if DEBUG;
            $result = $code->(@_);
            # we could have been passed a subroutine!
            my $cachetime = literalOrCall($ct, $pkg, $name, @_);
            warn "Cache($name) Setting $key => $result ($cachetime)" if DEBUG;
            $cache->set( $key, $result, $cachetime );
        }
        return $result unless $transform;
        return $transform->($result, @_);
    };
    return $sub;
}

sub getCacheKeyDefault {
    return join ';' => @_;
}
sub literalOrCall {
    my $what = shift;
    return $what unless ref $what eq 'CODE';
    return $what->(@_);
}

1;

=head1 PERFORMANCE

Automatically wrapping the caching logic requires a slightly generic approach
which may not be optimal.  The bundled C<attr_bench.pl> program tries to
quantify this.  In a sample run of 1,000,000 iterations, it can be seen that
the additional work requires approximately 10 millionths of a second per
iteration.  This is likely to be fast enough for most requirements.  

Using the Attribute::Handling (instead of manually using the C<encache>
subroutine which does the actual work) appears to be a tiny fraction of the
total overhead (1 millionth of a second per iteration).

(Benchmark results on my machine, please give me a shout if you get wildly
different results).

=head1 SEE ALSO

The attribute code is "inspired" by L<Attribute::Memoize>, and uses the very
funky L<Attribute::Handlers>.  This latter seems to be full of very tasty
crack, but is also much nicer than doing the attribute parsing ourselves.

You'll need a caching module like L<Cache::Cache> or L<Cache::Memcached>.

The wrapping might be done better with L<Hook::LexWrap>

=head1 STATUS and BUGS

This is version 0.01, in alpha.  The interface is likely to
change, as indicated in several places in comments in the above
POD.  Please get in touch if you have suggestions or concerns
about the public API.

Please report via RT on cpan, or to L<mailto:osfameron@cpan.org>.  

Or grab osfameron on IRC, for example on C<irc.perl.org #london.pm>

=head1 AUTHOR and LICENSE

By osfameron, for Thermeon Ltd.

(C)2007 Thermeon Europe

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
