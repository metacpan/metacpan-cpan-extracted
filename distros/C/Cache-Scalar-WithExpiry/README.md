# NAME

Cache::Scalar::WithExpiry - Cache one scalar value with expiry

# SYNOPSIS

    use Cache::Scalar::WithExpiry;
    use feature qw/state/;
    

    state $cache = Cache::Scalar::WithExpiry->new();
    my ($value, $expiry_epoch) = $cache->get_or_set(sub {
        my $val          = Storage->get;
        my $expiry_epoch = time + 20;
        return ($val, $expiry_epoch); # cache in 20 seconds
    });

DSL interface

    use Cache::Scalar::WithExpiry;
    

    my ($value, $expiry_epoch) = cache_with_expiry {
        my $val          = Storage->get;
        my $expiry_epoch = time + 20;
        return ($val, $expiry_epoch); # cache in 20 seconds
    };

# DESCRIPTION

Cache::Scalar::WithExpiry is cache storage for one scalar value with expiry epoch.

# METHODS

- `my $obj = Cache::Scalar::WithExpiry->new()`

    Create a new instance.

- `my $stuff, [$expiry_epoch:Num] = $obj->get();`

    Get a stuff from cache storage. It returns value in scalar context, and returns
    value and expiry epoch in array context.

- `$obj->set($val, $expiry_epoch)`

    Set a stuff for cache. `$expiry_epoch` is required.

- `$obj->get_or_set($code)`

    Get a cache value if it's already cached. If it's not cached, run `$code` which should
    return two value, `$value_to_be_cached` and `$expiry_epoch`, and cache the value
    until the expiry epoch.

- `$obj->delete($key)`

    Delete the cache.

# EXPORT FUNCTION

- `my $stuff, [$expiry_epoch:Num] = cache_with_expiry {BLOCK};`

    \[EXPERIMENTAL\] It is equivalent process with doing `new` and `set_or_get` at a time.

# THANKS TO

tokuhirom. Most code of this module is steal from his [Cache::Memory::Simple::Scalar](http://search.cpan.org/perldoc?Cache::Memory::Simple::Scalar).

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
