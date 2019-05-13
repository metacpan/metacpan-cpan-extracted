# NAME

Curio::Role::CHI - Build Curio classes around CHI.

# SYNOPSIS

Create a Curio class:

```perl
package MyApp::Service::Cache;

use Curio role => '::CHI';

use Exporter qw( import );
our @EXPORT = qw( myapp_cache );

add_key geo_ip => (
    driver => 'Memory',
    global => 0,
);

sub myapp_cache {
    return __PACKAGE__->fetch( @_ )->chi();
}

1;
```

Then use your new Curio class elsewhere:

```perl
use MyApp::Service::Cache;

my $chi = myapp_cache('geo_ip');
```

# DESCRIPTION

This role provides all the basics for building a Curio class
which wraps around [CHI](https://metacpan.org/pod/CHI).

Fun fact, this ["SYNOPSIS"](#synopsis) is functionally identical to
["SYNOPSIS" in Curio](https://metacpan.org/pod/Curio#SYNOPSIS).

# ATTRIBUTES

## chi

```perl
my $chi = MyApp::Service::Cache->fetch('geo_ip)->chi();
```

Holds the [CHI](https://metacpan.org/pod/CHI) object.

# CACHING

This role sets the ["does\_caching" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#does_caching) and
["cache\_per\_process" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#cache_per_process) features.

`cache_per_process` is important to set since there are
quite a few CHI drivers which do not like to be re-used
across processes.

You can of course disable these features.

```
does_caching 0;
cache_per_process 0;
```

# NO KEYS

If you'd like to create a CHI Curio class which exposes a
single CHI object and does not support keys then here's a
slightly altered version of the ["SYNOPSIS"](#synopsis) to get you
started.

Create a Curio class:

```perl
package MyApp::Service::GeoIPCache;

use Curio role => '::CHI';

use Exporter qw( import );
our @EXPORT = qw( myapp_geo_ip_cache );

default_arguments (
    driver => 'Memory',
    global => 0,
);

sub myapp_geo_ip_cache {
    return __PACKAGE__->fetch( @_ )->chi();
}

1;
```

Then use your new Curio class elsewhere:

```perl
use MyApp::Service::GeoIPCache;

my $chi = myapp_geo_ip_cache();
```

# SUPPORT

Please submit bugs and feature requests to the
Curio-Role-CHI GitHub issue tracker:

[https://github.com/bluefeet/Curio-Role-CHI/issues](https://github.com/bluefeet/Curio-Role-CHI/issues)

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# AUTHORS

```
Aran Clary Deltac <aran@bluefeet.dev>
```

# COPYRIGHT AND LICENSE

Copyright (C) 2019 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).
