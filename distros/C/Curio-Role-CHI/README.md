# NAME

Curio::Role::CHI - Build Curio classes around CHI.

# SYNOPSIS

Create a Curio class:

```perl
package MyApp::Service::Cache;

use Curio role => '::CHI';
use strictures 2;

export_function_name 'myapp_cache';
always_export;
export_resource;

add_key geo_ip => (
    chi => {
        driver => 'Memory',
        global => 0,
    },
);

1;
```

Then use your new Curio class elsewhere:

```perl
use MyApp::Service::Cache;

my $chi = myapp_cache('geo_ip');
```

# DESCRIPTION

This role provides all the basics for building a Curio class which
wraps around [CHI](https://metacpan.org/pod/CHI).

# REQUIRED ARGUMENTS

## chi

Holds the [CHI](https://metacpan.org/pod/CHI) object.

May be passed as either a hashref of arguments or a pre-created
object.

# FEATURES

This role turns on ["does\_caching" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#does_caching) and
["cache\_per\_process" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#cache_per_process), and sets
["resource\_method\_name" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#resource_method_name) to `chi` (as in ["chi"](#chi)).

You can of course revert these changes:

```
does_caching 0;
cache_per_process 0;
resource_method_name undef;
```

# SUPPORT

Please submit bugs and feature requests to the
Curio-Role-CHI GitHub issue tracker:

[https://github.com/bluefeet/Curio-Role-CHI/issues](https://github.com/bluefeet/Curio-Role-CHI/issues)

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/) for
encouraging their employees to contribute back to the open source
ecosystem.  Without their dedication to quality software development
this distribution would not exist.

# AUTHORS

```
Aran Clary Deltac <bluefeet@gmail.com>
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
