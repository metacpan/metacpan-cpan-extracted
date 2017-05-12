# NAME

Cache::Escalate - cache engine bundler

# SYNOPSIS

    use Cache::Escalate;

    my $ce = Cache::Escalate->new( caches => [ $cache1, $cache2 ] );

    # Set value into all cache engines.
    $ce->set("foo", 1);

    # Get value from cache.
    # If cache missed,  Cache::Escalate reference next cache engine.
    $ce->get("foo");

    # Delete value from all cache engines.
    $ce->delete("foo");

# DESCRIPTION

Cache::Escalate is cache engine bundler.
On get value through Cache::Escalate and cache misses,
next cache engine will be used automatically.

# LICENSE

Copyright (C) handlename.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

handlename &lt;handle@cpan.org>
