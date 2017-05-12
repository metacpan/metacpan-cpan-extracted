[![Build Status](https://travis-ci.org/Maki-Daisuke/p5-AnyEvent-InMemoryCache.png?branch=master)](https://travis-ci.org/Maki-Daisuke/p5-AnyEvent-InMemoryCache)
# NAME

AnyEvent::InMemoryCache - Simple in-memory cache for AnyEvent applications

# SYNOPSIS

    use AnyEvent;
    use AnyEvent::InMemoryCache;
    

    my $cache = AnyEvent::InMemoryCache->new;
    

    $cache->set(immortal => "Don't expire!");  # It lasts forever by default
    say $cache->get("immortal");  # "Don't expire!"
    

    $cache->set(a_second => "Expire soon", "1s");  # Expires in one-second.
    say $cache->get('a_second');  # "Expires soon"
    AE::timer 2, 0, sub{  # 2 seconds later
        $cache->exists('a_second');  # false
    };
    

    # You can overwrite key, and it's mortal now.
    $cache->set(immortal => 'will die...', "10min");
    

    # If you want a key not to be expired, pass negative integer for the third parameter.
    $cache->set(immortal => 'Immortal again!', -1);
    

    # You can specify default lifetime of keys.
    my $cache = AnyEvent::InMemoryCache->new(expires_in => "1 hour");
    

    # You can also tie hash.
    tie my %hash, 'AnyEvent::InMomeryCache', expired_in => '30min';
    $hash{'key'} = "value";  # Automatically deleted 30 minutes later.

# DESCRIPTION

AnyEvent::InMemoryCache provides a really simple in-memory cache mechanism for AnyEvent applications.

# RATIONALE

There are already many cache modules, but many of those are checking whether cached values are still
valid or already expired when fetching the values. That is, every time a value is fetched from the cache,
it takes extra time to check the validity. It is not effective. Even worth, those modules cannot expires
values until they are fetched or explicitly purged by hand. In other words, they cannot free allocated
memory even when the values are already expired.

Thus, I wrote this module.

## ADVANTAGE

This module is completely event-driven. That is, it only checks and expires values when the expiration
time comes. That gives us performance advantage because it need not to check validity of values every
time it fetches values. Also, this can free allocated memory as soon as each value is expired.

## DISADVANTAGE

This module simply does not work unless you use AnyEvent framework correctly.

# METHODS

## `$class->new( expires_in => $duration )`

Creates new AnyEvent::InMemoryCache object.

- `expires_in` (optional)

    Specify default lifetime of cached values.
    You can specify any value that [Time::Duration::Parse](http://search.cpan.org/perldoc?Time::Duration::Parse) can recognize.
    If this parameter is omitted or negative value, it means unlimited lifetime.

## `$cache->set( $key, $value, $duration )`

Store `$value` as a value of `$key`.
`$duration` specifies lifetime of this key & value. It accepts any value
that [Time::Duration::Parse](http://search.cpan.org/perldoc?Time::Duration::Parse) can recognize as `new` does. If `$duration`
is omitted, it uses default value, which is specified by `new`. You can also
specify negative integer (e.g. -1) for unlimited lifetime.

## `$cache->get( $key )`

Fetches the value bound to `$key`.

## `$cache->exists( $key )`

Returns true if `$key` exists, otherwise returns false.

## `$cache->delete( $key )`

Explicitly expires (deletes) key and value indexed by `$key`.

# TIE INTERFACE

In addition to OOP interface, you can tie a hash to this module:

    tie my %hash, 'AnyEvent::InMemoryCache', expires_in => '30min';
    $hash{'foo'} = 'bar';  # expires in 30 minutes

Through the tie interface, you cannot specify lifetime for each value. Though, you can always access
backend AnyEvent::InMemoryCache object:

    (tied %hash)->set(foo => 'bar', -1);

# SEE ALSO

- [AnyEvent](http://search.cpan.org/perldoc?AnyEvent)
- [Time::Duration::Parse](http://search.cpan.org/perldoc?Time::Duration::Parse)

# LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Daisuke (yet another) Maki <maki.daisuke@gmail.com>
