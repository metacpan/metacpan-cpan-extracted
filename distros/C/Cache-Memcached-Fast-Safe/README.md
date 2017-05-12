# NAME

Cache::Memcached::Fast::Safe - Cache::Memcached::Fast with sanitizing keys and fork-safe

# SYNOPSIS

    use Cache::Memcached::Fast::Safe;
    
    my $memd = Cache::Memcached::Fast::Safe->new({
      servers => [..]
    });
    
    #This module supports all method that Cache::Memcached::Fast has.

# DESCRIPTION

Cache::Memcached::Fast::Safe is subclass of [Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast).
Cache::Memcached::Fast::Safe sanitizes all requested keys for against 
memcached injection problem. and call disconnect\_all automatically after fork 
for fork-safe.

# ADDITIONAL METHOD

- get\_or\_set($key:Str, $callback:CodeRef \[,$expires:Num\])

    Get a cache value for $key if it's already cached. If can not retrieve cache values, execute $callback and cache with $expires seconds.

        $memcached->get_or_set('key:941',sub {
          DB->retrieve(941)
        },10);

    callback can also return expires sec.

        $memcached->get_or_set('key:941',sub {
          my $val = DB->retrieve(941);
          return ($val, 10)
        });

# CUSTOMIZE Sanitizer

This module allow to change sanitizing behavior through $Cache::Memcached::Fast::Safe::SANITIZE\_METHOD.
Default sanitizer is

    local $Cache::Memcached::Fast::Safe::SANITIZE_METHOD = sub {
        my $key = shift;
        $key = uri_escape($key,"\x00-\x20\x7f-\xff");
        if ( length $key > 200 ) {
            $key = sha1_hex($key);
        }
        $key;
    };

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# SEE ALSO

[Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast), [http://gihyo.jp/dev/feature/01/memcached\_advanced/0002](http://gihyo.jp/dev/feature/01/memcached_advanced/0002) (Japanese)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
