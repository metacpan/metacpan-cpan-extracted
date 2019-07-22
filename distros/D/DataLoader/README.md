## perl-DataLoader [![Build Status](https://travis-ci.org/richardjharris/perl-DataLoader.svg?branch=master)](https://travis-ci.org/richardjharris/perl-DataLoader) [![Coverage Status](https://coveralls.io/repos/github/richardjharris/perl-DataLoader/badge.svg?branch=master)](https://coveralls.io/github/richardjharris/perl-DataLoader?branch=master)
DataLoader - automatically batch and cache repeated data loads

## Synopsis

```perl
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
```

## Description

[DataLoader](https://metacpan.org/pod/DataLoader) is a generic utility to be used as part of your application's data
fetching layer. It provides a consistent API over various backends and reduces requests
to those backends via automatic batching and caching of data.

It is primarily useful for GraphQL APIs where each resolver independently requests
the object(s) it wants, then this loader can ensure requests are batched together and
not repeated multiple times.

It is a port of the JavaScript version available at [https://github.com/graphql/dataloader](https://github.com/graphql/dataloader).

### Batching

To get started, create a batch loading function that maps a list of keys (typically
strings/integers) to a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise) that returns a list of values.

```perl
my $user_loader = DataLoader->new(\&myBatchGetUsers);
```

Then load individual values from the loader. All individual loads that occur within a
single tick of the event loop will be batched together.

```
$user_loader->load(1)
    ->then(fun($user) { $user_loader->load($user->invitedById) })
    ->then(fun($invitedBy) { say "User 1 was invited by ", $invitedBy->name });

# Somewhere else in the application
$user_loader->load(2)
    ->then(fun($user) { $user_loader->load($user->lastInvitedId) })
    ->then(fun($lastInvited) { say "User 2 last invited ", $lastInvited->name }); 
```

A naive application may have issued four round-trips to the backend for the required
information, but with DataLoader this application will make at most two.

#### Batch Function

The batch loading function takes a list of keys as input, and returns a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise)
that resolves to a list of values. The ordering of the values should correspond to the
ordering of the keys, with any missing values filled in with `undef`. For example, if
the input is `(2,9,6,1)` and the backend service (e.g. database) returns:

```perl
{ id => 9, name => 'Chicago' }
{ id => 1, name => 'New York' }
{ id => 2, name => 'San Francisco' }
```

The backend has returned results in a different order than we requested, and omitted a
result for key `6`, presumably because no value exists for that key.

We need to re-order these results to match the original input `(2,9,6,1)`, and include
an undef result for `6`:

```perl
[
  { id => 2, name => 'San Francisco' },
  { id => 9, name => 'Chicago' },
  undef,
  { id => 1, name => 'New York' },
]
```

There are two typical error cases in the batch loading function. One is you get an error
that invalidates the whole batch, for example you do a DB query for all input rows, and
the DB fails to connect. In this case, simply `die` and the error will be passed through
to all callers that are waiting for values included in this batch. In this case, the error
is assumed to be transient, and nothing will be cached.

The second case is where some of the batch succeeds but some fails. In this case, use
`DataLoader->error` to create error objects, and mix them in with the successful
values:

```perl
[
  { id => 2, name => 'San Francisco' },      # this succeeded
  DataLoader->error("no permission"),        # this failed (id 9)
  undef,                                     # this item is missing (id 6)
  { id => 1, name => 'New York' },           # this succeeded
]
```

Now callers that have called `load->(9)` will get an exception. Callers for id 6
will receive `undef` and callers for ids 1 and 2 will get hashrefs of data. Additionally,
these errors will be cached (see 'Caching Errors' below).

### Caching

DataLoader provides a simple memoization cache for all loads that occur within a single
request for your application. Multiple loads for the same value result in only one
backend request, and additionally, the same object in memory is returned each time,
reducing memory use.

```perl
my $user_loader = DataLoader->new(...);
my $promise1a = $user_loader->load(1);
my $promise1b = $user_loader->load(1);
is( refaddr($promise1a), refaddr($promise1b) );   # same object
```

#### Caching Per-Request

The suggested way to use DataLoader is to create a new loader when a request (for example
GraphQL request) begins, and destroy it once the request ends. This prevents duplicate
backend operations and provides a consistent view of data across the request.

Using the same loader for multiple requests is not recommended as it may result in cached
data being returned unexpectedly, or sensitive data being leaked to other users who should
not be able to view it.

The default cache used by DataLoader is a simple hashref that stores all values for all
keys loaded during the lifetime of the request; it is useful when request lifetime is
short. If other behaviour is desired, see the `cache_hashref` constructor parameter.

#### Clearing Cache

It is sometimes necessary to clear values from the cache, for example after running an
SQL UPDATE or similar, to prevent out of date values from being used. This can be done
with the `clear` method.

#### Caching Errors

If the batch load fails (throws an exception or returns a rejected Promise), the requested
values will not be cached. However, if the batch function returns a `DataLoader::Error`
instance for individual value(s), those errors will be cached to avoid frequently loading
the same error.

If you want to avoid this, you can catch the Promise error and clear the cache immediately
afterwards, e.g.

```
$user_loader->load(1)->catch(fun ($error) {
   if ($should_clear_error) {
       $user_loader->clear(1);
   }
   die $error;   # or whatever
});
```

## Methods

- new ( batch\_load\_function, %options )

    Creates a public API for loading data from a particular back-end with unique keys,
    such as the `id` column of an SQL table. You must provide a batch loading function
    (described above).

    Each instance gets, by default, a unique memoized cache of all loads made during the
    lifetime of the object. Consider a different cache for long-lived applications, and
    consider a new instance per request if each request has users with different access
    permissions or where fresh data is desired for each request.

    Options:

    - batch (true)

        Set to false to disable batching: the batch load function will be invoked once for
        each key.

    - max\_batch\_size (Infinity)

        If set, limit the maximum number of items to pass to the batch load function at once.

    - cache (true)

        Set to false to disable caching, which will create a new Promise and new key in the
        batch load function for every load of the same key. (This means the batch loda function
        may be called with duplicate keys).

    - cache\_key\_func (identity function)

        Maps a load key `$_` to a cache key. Useful when using objects as keys and two
        different objects should be considered equivalent, or to handle case-
        insensitivity, etc.

        For example: `cache_key_func => sub { lc }` for case-insensitive comparisons

        Compare objects as long as their id is the same:

        ```perl
        ... cache_key_func => sub { $_->{id} }
        ```

        Compare the content of objects:

        ```perl
        use Storable;
        ... cache_key_func => sub { thaw($_) }
        ```

    - cache\_hashref ({})

        Pass a custom hashref for caching. You can tie this hashref to any tie module to get
        custom behaviour (such as LRU). ([CHI](https://metacpan.org/pod/CHI) support will be considered if there is interest)

- load ( key )

    Loads a key, returning a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise) for the value represented by that key.

- load\_many ( @keys )

    Loads multiple keys, returning a Promise that resolves a list of values.

    Equivalent to `DataLoader->all(map { $loader->load($_) } @keys)`.

- clear ( key )

    Clear the value at `key` from the cache, if it exists. Returns itself for method
    chaining.

- clear\_all ()

    Clears the entire cache. To be used when some event results in unknown invalidations
    across this particular [DataLoader](https://metacpan.org/pod/DataLoader). Returns itself for method chaining.

- prime ( key, value )

    Primes the cache with the provided key and value. If the key already exists, no
    change is made. (To forcefully prime the cache, clear the key first with
    `$loader->clear($key)->prime($key, $value)`.) Returns itself for method chaining.

    If you want to prime an error value, use `DataLoader->error($message)` as the
    second argument.

- DataLoader->error( @message )

    Shorthand for `DataLoader::Error->new(@message)`. Should be used by the batch
    loading function to indicate particular items of data that could not be loaded. The
    error will be propogated to the `load` caller(s) for the data. Can also be used
    with `prime`.

- DataLoader->all( @promises )

    Alternative to Mojo::Promise's `all` that assumes all promises return a single
    argument only, and will return a list of single return values for all promises,
    in the same order as the promises.

    For example:

    ```
    Mojo::Promise->all( Mojo::Promise->resolve(1), Mojo::Promise->resolve(2) );
    ```

    resolves to `[[1], [2]]`, but:

    ```
    DataLoader->all( Mojo::Promise->resolve(1), Mojo::Promise->resolve(2) );
    ```

    resolves to `[1, 2]`.

    Additionally, `Mojo::Promise->all()` will die with "unable to call 'clone' on
    undefined value" (or similar), while `DataLoader->all()` returns a Promise that
    resolves to the empty list.

    Throws an exception if any promise passed as an argument resolves to a list of more
    than one return value.
