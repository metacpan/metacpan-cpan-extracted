# NAME

Cache::File::Simple - Dead simple file based caching meachanism

# SYNOPSIS

```perl
use Cache::File::Simple;

my $ckey = "cust:1234";

# Get data from the cache
my $data = cache($ckey);

# Store a scalar
cache($ckey, "Jason Doolis");
cache($ckey, "Jason Doolis", time() + 7200);

# Store an arrayref
cache($ckey, [1, 2, 3]);

# Store a hashref
cache($ckey, {'one' => 1, 'two' => 2});

# Delete an item from the cache
cache($ckey, undef);
```

# DESCRIPTION

`Cache::File::Simple` exports a single `cache()` function automatically.

Store Perl data structures in an on-disk file cache. Cache entries can be given
an expiration time to allow for easy clean up.

# METHODS

- **cache($key)**

    Get cache data for `$key` from the cache

- **cache($key, $obj)**

    Store data in the cache for `$key`. `$obj` can be a scalar, listref, or hashref.

- **cache($key, $obj, $expires)**

    Store data in the cache for `$key` with an expiration time. `$expires` is a
    unixtime after which the cache entry will be removed.

- **cache($key, undef)**

    Delete an entry from the cache.

- **Cache::File::Simple::cache\_clean()**

    Manually remove expired entries from the cache. Returns the number of items
    expired from the cache;

- **$Cache::File::Simple::CACHE\_ROOT**

    Change where the cache files are stored. Default `/tmp/cacheroot`

- **$Cache::File::Simple::DEFAULT\_EXPIRES**

    Change the default time entries are cached for. Default 3600 seconds
