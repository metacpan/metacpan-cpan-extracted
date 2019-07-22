package DataLoader;

=encoding utf8

=head1 NAME

DataLoader - automatically batch and cache repeated data loads

=head1 SYNOPSIS

 use DataLoader;
 my $user_loader = DataLoader->new(sub {
    my @user_ids = @_;
    return getUsers(@user_ids);  # a Mojo::Promise
 });

 # Now fetch your data whenever (asynchronously)
 my $data = Mojo::Promise->all(
    $loader->load(1),
    $loader->load(2),
    $loader->load(2),
 );

 # getUsers is called only once - with (1,2)

=head1 DESCRIPTION

L<DataLoader> is a generic utility to be used as part of your application's data
fetching layer. It provides a consistent API over various backends and reduces requests
to those backends via automatic batching and caching of data.

It is primarily useful for GraphQL APIs where each resolver independently requests
the object(s) it wants, then this loader can ensure requests are batched together and
not repeated multiple times.

It is a port of the JavaScript version available at L<https://github.com/graphql/dataloader>.

=head2 Batching

To get started, create a batch loading function that maps a list of keys (typically
strings/integers) to a L<Mojo::Promise> that returns a list of values.

 my $user_loader = DataLoader->new(\&myBatchGetUsers);

Then load individual values from the loader. All individual loads that occur within a
single tick of the event loop will be batched together.

 $user_loader->load(1)
     ->then(fun($user) { $user_loader->load($user->invitedById) })
     ->then(fun($invitedBy) { say "User 1 was invited by ", $invitedBy->name });
 
 # Somewhere else in the application
 $user_loader->load(2)
     ->then(fun($user) { $user_loader->load($user->lastInvitedId) })
     ->then(fun($lastInvited) { say "User 2 last invited ", $lastInvited->name }); 

A naive application may have issued four round-trips to the backend for the required
information, but with DataLoader this application will make at most two.

=head3 Batch function

The batch loading function takes a list of keys as input, and returns a L<Mojo::Promise>
that resolves to a list of values. The ordering of the values should correspond to the
ordering of the keys, with any missing values filled in with C<undef>. For example, if
the input is C<(2,9,6,1)> and the backend service (e.g. database) returns:

 { id => 9, name => 'Chicago' }
 { id => 1, name => 'New York' }
 { id => 2, name => 'San Francisco' }

The backend has returned results in a different order than we requested, and omitted a
result for key C<6>, presumably because no value exists for that key.

We need to re-order these results to match the original input C<(2,9,6,1)>, and include
an undef result for C<6>:

 [
   { id => 2, name => 'San Francisco' },
   { id => 9, name => 'Chicago' },
   undef,
   { id => 1, name => 'New York' },
 ]

There are two typical error cases in the batch loading function. One is you get an error
that invalidates the whole batch, for example you do a DB query for all input rows, and
the DB fails to connect. In this case, simply C<die> and the error will be passed through
to all callers that are waiting for values included in this batch. In this case, the error
is assumed to be transient, and nothing will be cached.

The second case is where some of the batch succeeds but some fails. In this case, use
C<< DataLoader->error >> to create error objects, and mix them in with the successful
values:

 [
   { id => 2, name => 'San Francisco' },      # this succeeded
   DataLoader->error("no permission"),        # this failed (id 9)
   undef,                                     # this item is missing (id 6)
   { id => 1, name => 'New York' },           # this succeeded
 ]

Now callers that have called C<< load->(9) >> will get an exception. Callers for id 6
will receive C<undef> and callers for ids 1 and 2 will get hashrefs of data. Additionally,
these errors will be cached (see 'Caching Errors' below).

=head2 Caching

DataLoader provides a simple memoization cache for all loads that occur within a single
request for your application. Multiple loads for the same value result in only one
backend request, and additionally, the same object in memory is returned each time,
reducing memory use.

 my $user_loader = DataLoader->new(...);
 my $promise1a = $user_loader->load(1);
 my $promise1b = $user_loader->load(1);
 is( refaddr($promise1a), refaddr($promise1b) );   # same object

=head3 Caching per-Request

The suggested way to use DataLoader is to create a new loader when a request (for example
GraphQL request) begins, and destroy it once the request ends. This prevents duplicate
backend operations and provides a consistent view of data across the request.

Using the same loader for multiple requests is not recommended as it may result in cached
data being returned unexpectedly, or sensitive data being leaked to other users who should
not be able to view it.

The default cache used by DataLoader is a simple hashref that stores all values for all
keys loaded during the lifetime of the request; it is useful when request lifetime is
short. If other behaviour is desired, see the C<cache_hashref> constructor parameter.

=head3 Clearing Cache

It is sometimes necessary to clear values from the cache, for example after running an
SQL UPDATE or similar, to prevent out of date values from being used. This can be done
with the C<clear> method.

=head3 Caching Errors

If the batch load fails (throws an exception or returns a rejected Promise), the requested
values will not be cached. However, if the batch function returns a C<DataLoader::Error>
instance for individual value(s), those errors will be cached to avoid frequently loading
the same error.

If you want to avoid this, you can catch the Promise error and clear the cache immediately
afterwards, e.g.

 $user_loader->load(1)->catch(fun ($error) {
    if ($should_clear_error) {
        $user_loader->clear(1);
    }
    die $error;   # or whatever
 });

=head1 METHODS

=over

=cut

use v5.14;
use warnings;

use Carp qw(croak);
use Data::Dump qw(dump);
use Mojo::IOLoop;
use Mojo::Promise;
use Scalar::Util qw(blessed);

use DataLoader::Error;

our $VERSION = '0.01';

=item new ( batch_load_function, %options )

Creates a public API for loading data from a particular back-end with unique keys,
such as the C<id> column of an SQL table. You must provide a batch loading function
(described above).

Each instance gets, by default, a unique memoized cache of all loads made during the
lifetime of the object. Consider a different cache for long-lived applications, and
consider a new instance per request if each request has users with different access
permissions or where fresh data is desired for each request.

Options:

=over

=item batch (true)

Set to false to disable batching: the batch load function will be invoked once for
each key.

=item max_batch_size (Infinity)

If set, limit the maximum number of items to pass to the batch load function at once.

=item cache (true)

Set to false to disable caching, which will create a new Promise and new key in the
batch load function for every load of the same key. (This means the batch loda function
may be called with duplicate keys).

=item cache_key_func (identity function)

Maps a load key C<$_> to a cache key. Useful when using objects as keys and two
different objects should be considered equivalent, or to handle case-
insensitivity, etc.

For example: C<< cache_key_func => sub { lc } >> for case-insensitive comparisons

Compare objects as long as their id is the same:

 ... cache_key_func => sub { $_->{id} }

Compare the content of objects:

 use Storable;
 ... cache_key_func => sub { thaw($_) }

=item cache_hashref ({})

Pass a custom hashref for caching. You can tie this hashref to any tie module to get
custom behaviour (such as LRU). (L<CHI> support will be considered if there is interest)

=back

=cut

sub new {
    my ($class, $batch_load_func, %opts) = @_;

    my $do_batch = delete $opts{batch} // 1;
    my $max_batch_size = delete $opts{max_batch_size} // undef;
    my $do_cache = delete $opts{cache} // 1;
    my $cache_key_func = delete $opts{cache_key_func} // undef;
    my $cache_map = delete $opts{cache_hashref} // {};

    if (keys %opts) {
        croak "unknown option " . join(', ', sort keys %opts);
    }

    if ((ref $batch_load_func || '') ne 'CODE') {
        croak "batch_load_func must be a function that accepts a list of keys"
            . " and returns a Mojo::Promise resolving to a list of values, but"
            . " got: " . dump($batch_load_func);
    }
    if (defined $cache_key_func && (ref $cache_key_func || '') ne 'CODE') {
        croak "cache_key_func must be a function that returns the cache key for key=\$_";
    }
    if (!ref $cache_map || ref $cache_map ne 'HASH') {
        croak "cache_hashref must be a HASH ref (tied or plain)";
    }
    if (defined $max_batch_size) {
        $max_batch_size =~ /^\d+$/ or croak "max_batch_size must be a positive integer";
        $max_batch_size > 0 or croak "max_batch_size cannot be zero";
    }

    return bless {
        batch_load_func => $batch_load_func,
        do_batch => $do_batch,
        max_batch_size => $max_batch_size,
        do_cache => $do_cache,
        cache_key_func => $cache_key_func,
        promise_cache => $cache_map,
        queue => [],
    }, $class;
}

=item load ( key )

Loads a key, returning a L<Mojo::Promise> for the value represented by that key.

=cut

sub load {
    my ($self, $key) = @_;

    @_ >= 2 or croak "load: key is required";
    defined $key or croak "load: key must be defined";
    @_ == 2 or croak "load: too many arguments, expected 1";

    my $cache_key = $self->_cache_key($key);

    # If caching and there is a cache-hit, return cached promise
    if ($self->{do_cache} && (my $promise = $self->{promise_cache}{$cache_key})) {
        return $promise;
    }

    # Otherwise, produce a new Promise for this value
    my $promise = Mojo::Promise->new;

    # JS code calls new Promise((resolve, reject) => ...) with the below code
    # but this should be equivalent.
    push @{$self->{queue}}, [$key, $promise];

    # Determine if a dispatch of this queue should be scheduled.
    # A single dispatch should be scheduled per queue at the time when the queue
    # changes from 'empty' to 'full'
    if (@{$self->{queue}} == 1) {
        if ($self->{do_batch}) {
            # Schedule next tick, to allow all batch calls this frame to be batched
            # together.

            # We prefer an idle watcher as it will execute after all Promises are
            # resolved (batching as much as possible). But Mojo::IOLoop's API does
            # not provide this. And we cannot assume AnyEvent can be used.
            # The best we can do is detect the EV backend and use EV::idle.
            if (Mojo::IOLoop->singleton->reactor->isa('Mojo::Reactor::EV')) {
                # Capture the lexical inside the coderef to keep it alive until
                # the callback is finished.
                my $w; $w = EV::idle(sub {
                    $self->_dispatch_queue;
                    undef $w;
                });
            }
            else {
                # We fall back to next_tick, which is less efficient.
                Mojo::IOLoop->next_tick(sub { $self->_dispatch_queue });
            }
        }
        else {
            # Dispatch immediately
            $self->_dispatch_queue;
        }
    }

    # If caching, cache this cv
    if ($self->{do_cache}) {
        $self->{promise_cache}{$cache_key} = $promise;
    }

    return $promise;
}

=item load_many ( @keys )

Loads multiple keys, returning a Promise that resolves a list of values.

Equivalent to C<< DataLoader->all(map { $loader->load($_) } @keys) >>.

=cut

sub load_many {
    my ($self, @keys) = @_;

    return $self->all(map { $self->load($_) } @keys);
}

=item clear ( key )

Clear the value at C<key> from the cache, if it exists. Returns itself for method
chaining.

=cut

sub clear {
    my ($self, $key) = @_;

    my $cache_key = $self->_cache_key($key);
    delete $self->{promise_cache}{$cache_key};

    return $self;
}

=item clear_all ()

Clears the entire cache. To be used when some event results in unknown invalidations
across this particular L<DataLoader>. Returns itself for method chaining.

=cut

sub clear_all {
    my ($self) = @_;

    %{$self->{promise_cache}} = ();

    return $self;
}

=item prime ( key, value )

Primes the cache with the provided key and value. If the key already exists, no
change is made. (To forcefully prime the cache, clear the key first with
C<< $loader->clear($key)->prime($key, $value) >>.) Returns itself for method chaining.

If you want to prime an error value, use C<< DataLoader->error($message) >> as the
second argument.

=cut

sub prime {
    my ($self, $key, $value) = @_;

    my $cache_key = $self->_cache_key($key);

    # (Test coverage) There is no situation where the cache is unprimed AND we
    # fail to populate it with a Promise, so mark uncoverable.
    # uncoverable condition false
    $self->{promise_cache}{$cache_key} //= (
        _is_error_object($value) ? Mojo::Promise->reject($value->message)
                                 : Mojo::Promise->resolve($value)
    );

    return $self;
}

=item DataLoader->error( @message )

Shorthand for C<< DataLoader::Error->new(@message) >>. Should be used by the batch
loading function to indicate particular items of data that could not be loaded. The
error will be propogated to the C<load> caller(s) for the data. Can also be used
with C<prime>.

=cut

sub error {
    my ($class, @data) = @_;
    return DataLoader::Error->new(@data);
}

=item DataLoader->all( @promises )

Alternative to Mojo::Promise's C<all> that assumes all promises return a single
argument only, and will return a list of single return values for all promises,
in the same order as the promises.

For example:

 Mojo::Promise->all( Mojo::Promise->resolve(1), Mojo::Promise->resolve(2) );

resolves to C<[[1], [2]]>, but:

 DataLoader->all( Mojo::Promise->resolve(1), Mojo::Promise->resolve(2) );

resolves to C<[1, 2]>.

Additionally, C<< Mojo::Promise->all() >> will die with "unable to call 'clone' on
undefined value" (or similar), while C<< DataLoader->all() >> returns a Promise that
resolves to the empty list.

Throws an exception if any promise passed as an argument resolves to a list of more
than one return value.

=cut

sub all {
    my ($class, @promises) = @_;

    if (!@promises) {
        return Mojo::Promise->resolve();
    }
    else {
        my $all = $promises[0]->clone;
        my @results;
        my $remaining = @promises;
        for my $i (0..$#promises) {
            $promises[$i]->then(
                sub {
                    # Only consider first argument
                    @_ > 1 && $all->reject("all: got promise with multiple return values");
                    $results[$i] = $_[0];
                    $all->resolve(@results) if --$remaining <= 0;
                },
                sub { $all->reject(@_) }
            );
        }
        return $all;
    }
}

=back

=cut

# ---------------
# Private methods
# ---------------

# Schedule a data load for all items in the queue, splitting up if needed.
# The schedule is async; no return value.
sub _dispatch_queue {
    my $self = shift;

    my @queue = @{$self->{queue}};
    $self->{queue} = [];

    my $max_batch_size = $self->{max_batch_size};
    if ($max_batch_size && @queue > $max_batch_size) {
        # Need to split the queue into multiple batches
        while(my @batch = splice @queue, 0, $max_batch_size) {
            $self->_dispatch_queue_batch(@batch);
        }
    }
    else {
        $self->_dispatch_queue_batch(@queue);
    }
}

# Schedule a data load for a batch of items. Returns nothing.
sub _dispatch_queue_batch {
    my ($self, @queue) = @_;

    my @keys = map { $_->[0] } @queue;

    # Actually schedule the data load
    my $batch_promise = eval { $self->{batch_load_func}->(@keys) };
    if ($@) {
        return $self->_failed_dispatch(\@queue, $@);
    }
    elsif (!$batch_promise || !blessed $batch_promise || !$batch_promise->can('then')) {
        return $self->_failed_dispatch(\@queue,
            "DataLoader batch function did not return a Promise!");
    }

    # Await the resolution of the call of batch_load_func
    $batch_promise->then(sub {
        my @values = @_;

        if (@values != @keys) {
            die "DataLoader batch function returned the wrong number of keys:"
                . " returned " . @values . ", expected " . @keys . "\n"
                . "values: " . dump(@values) . "\n"
                . "keys: " . dump(@keys) . "\n";
        }

        # Step through each value, resolving or rejecting each Promise
        for my $i (0..$#queue) {
            my (undef, $promise) = @{$queue[$i]};
            my $value = $values[$i];
            if (_is_error_object($value)) {
                $promise->reject($value->message);
            }
            else {
                $promise->resolve($value);
            }
        }
    })->catch(sub {
        my $error = shift;
        $self->_failed_dispatch(\@queue, $error);
    });
}

# Called when a batch fails. Clear all items from the queue (so we don't cache the error
# response) and reject the Promise so callers get an exception.
sub _failed_dispatch {
    my ($self, $queue, $error) = @_;
    for my $job (@$queue) {
        my ($key, $promise) = @$job;
        $self->clear($key);
        $promise->reject($error);
    }
}

# Indicates if the value is a dataloader error object.
sub _is_error_object {
    my ($object) = @_;
    return blessed($object) && $object->isa('DataLoader::Error');
}

# Returns the cache_key for a key
sub _cache_key {
    my ($self, $key) = @_;
    return $key if !defined $self->{cache_key_func};
    return do { local $_ = $key; $self->{cache_key_func}->() };
}

1;
