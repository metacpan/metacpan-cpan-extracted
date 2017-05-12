# NAME

Cache::Method - Cache the execution result of your method.

# SYNOPSIS

## Cache on memory

    use Cache::Method;

    Cache::Method->new->set('foo');

    sub foo { ... }

    print foo(); #=> Execute foo
    print foo(); #=> Cached result

## Cache on SQLite

    use Cache::Method;

    my $cache = Cache::Method->new( dbfile => 'cache.db' );
    $cache->set('foo');

    sub foo { ... }

# DESCRIPTION

Cache::Method caches the execution result of your method.
You are able to store cache data to SQLite.

# LICENSE

Copyright (C) Hoto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hoto <hoto@cpan.org>
