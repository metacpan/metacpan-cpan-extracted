# NAME

App::Memcached::Roaster - Random data generator for Memcached

# SYNOPSIS

    use App::Memcached::Roaster;
    my $params = App::Memcached::Roaster->parse_args(@ARGV);
    App::Memcached::Roaster->new(%$params)->run;

# DESCRIPTION

This module is used by &lt;memcached-roaster> script to generates random data for
Memcached.
Depends on [Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast).

# LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[memcached-roaster](https://metacpan.org/pod/memcached-roaster),
[Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast),

# AUTHOR

YASUTAKE Kiyoshi &lt;yasutake.kiyoshi@gmail.com>
