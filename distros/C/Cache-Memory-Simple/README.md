# NAME

Cache::Memory::Simple - Yet another on memory cache

# SYNOPSIS

    use Cache::Memory::Simple;
    use feature qw/state/;

    sub get_stuff {
        my ($class, $key) = @_;

        state $cache = Cache::Memory::Simple->new();
        $cache->get_or_set(
            $key, sub {
                Storage->get($key) # slow operation
            }, 10 # cache in 10 seconds
        );
    }

# DESCRIPTION

Cache::Memory::Simple is yet another on memory cache implementation.

# METHODS

- `my $obj = Cache::Memory::Simple->new()`

    Create a new instance.

- `my $stuff = $obj->get($key);`

    Get a stuff from cache storage by `$key`

- `$obj->set($key, $val, $expiration)`

    Set a stuff for cache.

- `$obj->get_or_set($key, $code, $expiration)`

    Get a cache value for _$key_ if it's already cached. If it's not cached then, run _$code_ and cache _$expiration_ seconds
    and return the value.

- `$obj->delete($key)`

    Delete key from cache.

- `$obj->remove($key)`

    Alias for 'delete' method(Net::DNS::Lite require this method name).

- `$obj->purge()`

    Purge expired data.

    This module does not purge expired data automatically. You need to call this method if you need.

- `$obj->delete_all()`

    Remove all data from cache.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
