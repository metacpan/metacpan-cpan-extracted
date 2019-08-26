# NAME

Catalyst::Model::Curio - Curio Model for Catalyst.

# SYNOPSIS

Create your model class:

```perl
package MyApp::Model::Cache;

use Moo;
use strictures 2;
use namespace::clean;

extends 'Catalyst::Model::Curio';

__PACKAGE__->config(
    class  => 'MyApp::Service::Cache',
);

1;
```

Then use it in your controllers:

```perl
my $chi = $c->model('Cache::geo_ip');
```

# DESCRIPTION

This module glues [Curio](https://metacpan.org/pod/Curio) classes into Catalyst's model system.

This distribution also comes with [Catalyst::Helper::Model::Curio](https://metacpan.org/pod/Catalyst::Helper::Model::Curio)
which makes it somewhat simpler to create your Catalyst model class.

You may want to check out ["Use Curio Directly" in Curio](https://metacpan.org/pod/Curio#Use-Curio-Directly) for an
alternative viewpoint on using Catalyst models when you are
already using Curio.

# CONFIG ARGUMENTS

## class

```perl
class => 'MyApp::Service::Cache',
```

The Curio class that this model wraps around.

This is required to be set, otherwise Catalyst will throw
and exception when trying to load your model.

## key

```perl
key => 'geo_ip',
```

If your Curio class supports keys then, if set, this forces
your model to interact with one key only.

## method

```perl
method => 'connect',
```

By default Catalyst's `model()` will call the `fetch()`
method on your ["class"](#class) which will return a Curio object.
If you'd like, you can change this to call a different
method, returning something else of your choice.

You could, for example, have a method in your Curio class
which returns the the resource that your Curio object makes:

```perl
sub connect {
    my $class = shift;
    return $class->fetch( @_ )->chi();
}
```

Then set the `method` to `connect` causing `model()` to
return the CHI object instead of the Curio object.

# HANDLING KEYS

## No Keys

A Curio class which does not support keys just means you don't
set the ["key"](#key) config argument.

## Single Key

If your Curio class does support keys you can choose to create a model
for each key you want exposed in catalyst by specifying the ["key"](#key)
config argument in each model for each key you want available in Catalyst.
Each model would have the same ["class"](#class).

## Multiple Keys

If your Curio class supports keys and you do not set the ["key"](#key)
config argument then the model will automatically create pseudo
models for each key.

This is done by appending each declared key to your model name.
You can see this in the ["SYNOPSIS"](#synopsis) where the model name is
`Cache` but since ["key"](#key) is not set, and the Curio class does
have declared keys then the way you get the model is by appending
`::geo_ip` to the model name, or whatever key you want to access.

# SUPPORT

Please submit bugs and feature requests to the
Catalyst-Model-Curio GitHub issue tracker:

[https://github.com/bluefeet/Catalyst-Model-Curio/issues](https://github.com/bluefeet/Catalyst-Model-Curio/issues)

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

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
