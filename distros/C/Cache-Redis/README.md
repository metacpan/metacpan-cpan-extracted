[![Build Status](https://travis-ci.org/Songmu/p5-Cache-Redis.svg?branch=master)](https://travis-ci.org/Songmu/p5-Cache-Redis) [![Coverage Status](https://img.shields.io/coveralls/Songmu/p5-Cache-Redis/master.svg)](https://coveralls.io/r/Songmu/p5-Cache-Redis?branch=master)
# NAME

Cache::Redis - Redis client specialized for cache

# SYNOPSIS

    use Cache::Redis;

    my $cache = Cache::Redis->new(
        server    => 'localhost:9999',
        namespace => 'cache:',
    );
    $cache->set('key', 'val');
    my $val = $cache->get('key');
    $cache->remove('key');

# DESCRIPTION

This module is for cache of Redis backend having [Cache::Cache](https://metacpan.org/pod/Cache::Cache) like interface.

**THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE**.

# INTERFACE

## Methods

### `my $obj = Cache::Redis->new(%options)`

Create a new cache object. Various options may be set in `%options`, which affect
the behaviour of the cache (defaults in parentheses):

- `redis`

    Instance of Redis class are used as backend. If this is not passed, [Cache::Redis](https://metacpan.org/pod/Cache::Redis) load from `redis_class` automatically.

- `redis_class ('Redis')`

    The class for backend.

- `default_expires_in (60*60*24 * 30)`

    The default expiration seconds for objects place in the cache.

- `namespace ('')`

    The namespace associated with this cache.

- `nowait (0)`

    If enabled, when you call a method that only returns its success status (like "set"), in a void context,
    it sends the request to the server and returns immediately, not waiting the reply. This avoids the
    round-trip latency at a cost of uncertain command outcome.

- `serializer ('Storable')`

    Serializer. 'MessagePack' and 'Storable' are usable. if \`serialize\_methods\` option
    is specified, this option is ignored.

- `serialize_methods (undef)`

    The value is a reference to an array holding two code references for serialization and
    de-serialization routines respectively.

- server (undef)

    Redis server information. You can use \`sock\` option instead of this and can specify
    all other [Redis](https://metacpan.org/pod/Redis) constructor options to `Cache::Cache->new` method.

### `$obj->set($key, $value, $expire)`

Set a stuff to cache.

### `$obj->set_multi([$key, $value, $expire], [$key, $value])`

Set multiple stuffs to cache. stuffs is array reference.

### `my $stuff = $obj->get($key)`

Get a stuff from cache.

### `my $res = $obj->get_multi(@keys)`

Get multiple stuffs as hash reference from cache. `@keys` should be array.
A key is not stored on cache don't be contain `$res`.

### `$obj->remove($key)`

Remove stuff of key from cache.

### `$obj->get_or_set($key, $code, $expire)`

Get a cache value for _$key_ if it's already cached. If it's not cached then,
run _$code_ and cache _$expiration_ seconds and return the value.

### `$obj->nowait_push`

Wait all response from Redis. This is intended for `$obj->nowait`.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[perl](https://metacpan.org/pod/perl)

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

# LICENSE AND COPYRIGHT

Copyright (c) 2013, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
