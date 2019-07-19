# NAME

Curio - Procurer of fine resources and services.

# SYNOPSIS

Create a Curio class:

```perl
package MyApp::Service::Cache;

use CHI;
use Types::Standard qw( InstanceOf HashRef );
use Type::Utils -all;

use Curio;
use strictures 2;

does_caching;
cache_per_process;
export_function_name 'myapp_cache';

add_key geo_ip => (
    chi => {
        driver => 'Memory',
        global => 0,
    },
);

my $chi_type = declare as InstanceOf[ 'CHI::Driver' ];
coerce $chi_type, from HashRef, via { CHI->new( %$_ ) };

has chi => (
    is       => 'ro',
    isa      => $chi_type,
    required => 1,
    coerce   => 1,
);

1;
```

Then use your new Curio class elsewhere:

```perl
use MyApp::Service::Cache qw( myapp_cache );

my $chi = myapp_cache('geo_ip')->chi();
```

# DESCRIPTION

Curio is a toolbox for building a class which holds a resource (or
many resources) of your making.  Then, in your applications, you can
access the resource(s) from anywhere.

# INTRODUCTION

Curio is a library for creating [Moo](https://metacpan.org/pod/Moo) classes which encapsulate the
construction and retrieval of arbitrary resources.  As a user of this
library you've got two jobs.

First, you create classes in your application which use Curio.  You'll
have one class for each type of resource you want available to your
application as a whole.  So, for example, you'd have a Curio class for
your database connections, another for your graphite client, and perhaps
a third for your CRM client.

Your second job is to then modify your application to use your Curio
classes.  If your application uses an existing framework, such as
[Catalyst](https://metacpan.org/pod/Catalyst), then you may want to take a look at the available
["INTEGRATIONS"](#integrations).

Keep in mind that Curio doesn't just have to be used for connections
to remote services.  It can be used to make singleton classes, as a
ready to go generic object factory, a place to put global application
context information, etc.

# MOTIVATION

The main drive behind creating Curio is threefold.

1. To avoid the extra complexity of passing around references of shared
resources, such as connections to services.  Often times you'll see
code which passes a connection to a function, which then passes that
on to another function, which then creates an object with the connection
passed as an argument, etc.  This is what is being avoided; it's a messy
way to write code and prone to error.
2. To have a central place to put object creation logic.  When there is
no central place to put this sort of logic it tends to be haphazardly
copy-pasted and sprinkled all over a codebase making it difficult to
find and change.
3. To not be tied into any single framework as is commonly done today.
There is no reason this sort of logic needs to be framework dependent,
and once it is it makes all sorts of things more difficult, such as
migrating frameworks and writing in-house libraries that are framework
independent.  Yes, Curio is a sort framework itself, but it is a very
slim framework which gets out of your way quickly and is designed for
this one purpose.

These challenges can be solved, and using Curio can support you in
doing so.

# IMPORT ARGUMENTS

## role

```perl
use Curio role => '::CHI';
use Curio role => 'Curio::Role::CHI';
```

Set this to change the role that is applied to your Curio class.

If the role you specify has a leading `::` it is assumed to be
relative to the `Curio::Role` namespace and will have that appended
to it.  So, if you set the role to `::CHI` it will be automatically
converted to `Curio::Role::CHI`.

See ["ROLES"](#roles) for a list of existing Curio roles.

The default role is [Curio::Role](https://metacpan.org/pod/Curio::Role).

# BOILERPLATE

Near the top of most Curio classes is this line:

```perl
use Curio;
```

Which is exactly the same as:

```perl
use Moo;
use Curio::Declare;
use namespace::clean;
with 'Curio::Role';
__PACKAGE__->initialize();
```

If you're not into the declarative interface, or have some
other reason to switch around this boilerplate, you may copy the
above and modify to fit your needs rather than using this module
directly.

Read more about [Moo](https://metacpan.org/pod/Moo) and [namespace::clean](https://metacpan.org/pod/namespace::clean) if you are not
familiar with them.

# TOPICS

## Exporting the Fetch Function

To get at a Curio object's resource takes a lot of typing by default.

```perl
my $chi = MyApp::Service::Cache->fetch( $key )->chi();
```

Creating an export function that wraps this all up is a great way to
simplify things.  In your Curio class you can set
["export\_function\_name" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#export_function_name) which will create a function,
create the `@EXPORT_OK` package variable, and add the new function
to it.

```perl
# In your Curio class.
export_function_name 'myapp_cache';

# Elsewhere.
use MyApp::Service::Cache qw( myapp_cache );
my $chi = myapp_cache()->chi();
```

If you'd like the function to be always exported (use `@EXPORT`) then
set ["always\_export" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#always_export).

```perl
# In your Curio class.
export_function_name 'myapp_cache';
always_export;

# Elsewhere.
use MyApp::Service::Cache;
my $chi = myapp_cache()->chi();
```

If you'd like the exported function to return the resource object
instead of the curio object set ["export\_resource" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#export_resource).

```perl
# In your Curio class.
export_function_name 'myapp_cache';
export_resource;
resource_method_name 'chi';

# Elsewhere.
use MyApp::Service::Cache qw( myapp_cache );
my $chi = myapp_cache();
```

The generated function can be overriden with your own custom function.

```perl
# In your Curio class.
export_function_name 'myapp_cache';

sub myapp_cache {
    return __PACKAGE__->factory->fetch_curio( @_ )->chi();
}
```

## Caching

Caching is enabled with ["does\_caching" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#does_caching).

```
does_caching;
```

When enabled, all curio objects will be cached so that future fetches
for a curio object will return the same one as before.  This option
should almost always be set as it usually provides a huge performance
increase.

["cache\_per\_process" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#cache_per_process) extends the
caching to handle process/thread changes gracefully.

```
cache_per_process;
```

## Keys

Curio supports fetching curio objects by key.  This is an optional
feature and by default is turned off.  To turn it on you set
["does\_keys" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#does_keys) or just start adding keys
with ["add\_key" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#add_key) which will automatically turn
on `does_keys`.

When keys are enabled a curio class is able to produce different
objects based on the key.  For example, lets say you have two
databases, you could create two curio classes, or you could just
enable keys.

```perl
add_key db1 => ( host => 'db1.example.com' );
add_key db2 => ( host => 'db2.example.com' );
```

When keys are enabled calling fetch requires that you pass a key.

```perl
my $dbh1 = MyApp::Service::DB->fetch(
    'db1', # <-- key
)->dbh();
```

Passing a key that has not yet been declared with `add_key` will
throw an error.  This can be changed by setting
["allow\_undeclared\_keys" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#allow_undeclared_keys).

```
allow_undeclared_keys;
```

You can also set ["default\_key" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#default_key).

```
default_key 'db1';
```

Curio objects, by default, have no way of knowing what key was used
to make them.  If you need to know what key was used to fetch a curio
object you can set ["key\_argument" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#key_argument).

```perl
key_argument 'key';
has key => ( is=>'ro' );
```

The ["default\_arguments" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#default_arguments) option can
be useful when you are not using Moo attributes but still need to set
defaults for arguments.

```perl
default_arguments ( username => 'dbuser' );
```

## The Registry

The registry is a lookup table holding memory addresses of resource
objects pointing at references to curio objects.  What this means
is, if ["does\_registry" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#does_registry) is set, you can use
["find\_curio" in Curio::Role](https://metacpan.org/pod/Curio::Role#find_curio) to retrieve the curio object for a given
resource object.

```
does_registry;
resource_method_name 'chi';
```

In the ["SYNOPSIS"](#synopsis) ["resource\_method\_name" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#resource_method_name) is set to
`chi`, which is a Moo attribute.  When the curio object is created
this resource method will be called to get the resource object and,
along with the curio object, register them in the registry.

```perl
my $curio = MyApp::Service::Cache->find_curio( $chi );
```

Setting ["installs\_curio" in Curio::Factory](https://metacpan.org/pod/Curio::Factory#installs_curio) will install a `curio`
method in resource object classes.

```perl
# In your curio class:
does_registry;
resource_method_name 'chi';
installs_curio;

# Elsewhere:
my $curio = $chi->curio();
```

## Injecting Mock Objects

Use ["inject" in Curio::Role](https://metacpan.org/pod/Curio::Role#inject) to force fetch to return a custom curio
object.

```perl
my $mock = MyApp::Service::Cache->new(
    driver => 'Memory',
    global => 0,
);
MyApp::Service::Cache->inject( 'geo_ip', $mock );

my $chi = myapp_cache( 'geo_ip' );

MyApp::Service::Cache->uninject( 'geo_ip' );
```

Instead of having to call ["uninject" in Curio::Role](https://metacpan.org/pod/Curio::Role#uninject) directly you may
instead use ["inject\_with\_guard" in Curio::Role](https://metacpan.org/pod/Curio::Role#inject_with_guard).

```perl
my $guard = MyApp::Service::Cache->inject_with_guard(
    'geo_ip', $mock,
);
```

When the guard object goes out of scope `uninject` will be
called automatically.

## Singletons

Creating a singleton class is super simple.

```perl
package MyApp::Context;

use Curio;

use Exporter qw( import );
our @EXPORT = qw( myapp_cache );

sub myapp_context {
    return __PACKAGE__->fetch( @_ );
}

has user_id => ( is=>'rw' );

# Elsewhere:
my $current_user_id = myapp_context()->user_id();
```

## Handling Arguments

## Migrating and Merging Keys

## Introspection

## Custom Curio Roles

## Secrets

## Configuration

# IMPORTANT PRACTICES

## Avoid Holding onto Curio Objects and Resources

Curio is designed to make it cheap to retrieve Curio objects
and the underlying resources.  Take advantage of this.  Don't
pass around your resource objects or put them in attributes.
Instead, when you need them, get the from your Curio classes.

If your Curio class supports keys, then passing around the
key that you want particular code to be using, rather than the
Curio object or the resource, is a much better way of handling
things.

Read more of the reasoning for this in ["MOTIVATION" in Curio](https://metacpan.org/pod/Curio#MOTIVATION).

## Use Curio Directly

It is tempting to use the ["INTEGRATIONS" in Curio](https://metacpan.org/pod/Curio#INTEGRATIONS) such as
[Catalyst::Model::Curio](https://metacpan.org/pod/Catalyst::Model::Curio), and sometimes it is necessary to do so.
Most of the time there is no need to add that extra layer of complexity.

Using Catalyst as an example, there are few reasons you can't
just use your Curio classes directly from your Catalyst controllers.

At ZipRecruiter, where we have some massive Catalyst applications, we
only use Catalyst models in the few cases where other parts of
Catalyst demand that models be setup.  For the most part we bypass the
model system completely and it makes everything much cleaner and
easier to deal with.

## Appropriate Uses of Key Aliases

Key aliases are meant as a tool for migrating and merging keys.
They are meant to be something you temporarily setup as you change
your code to use the new keys, and then once done you remove the
aliases.

It can be tempting to use key aliases to provide simpler or alternative
names for existing keys.  The problem with doing this is now you've
introduced multiple keys for the same Curio class which in practice
causes unnecessary confusion.

# ROLES

These roles, available on CPAN, provide a base set of functionality
for your Curio classes to wrap around specific resource types.

- [Curio::Role::CHI](https://metacpan.org/pod/Curio::Role::CHI)
- [Curio::Role::DBIx::Class](https://metacpan.org/pod/Curio::Role::DBIx::Class)
- [Curio::Role::DBIx::Connector](https://metacpan.org/pod/Curio::Role::DBIx::Connector)
- [Curio::Role::GitLab::API::v4](https://metacpan.org/pod/Curio::Role::GitLab::API::v4)

# INTEGRATIONS

The CPAN modules listed here integrate Curio with other things
such as web frameworks.

- [Catalyst::Model::Curio](https://metacpan.org/pod/Catalyst::Model::Curio)

On a related note, take a look at ["Use Curio Directly" in Curio](https://metacpan.org/pod/Curio#Use-Curio-Directly).

# SEE ALSO

It is hard to find anything out there on CPAN which is similar to
Curio.

There is [Bread::Board](https://metacpan.org/pod/Bread::Board) but it has a very different take and solves
different problems.

[Catalyst](https://metacpan.org/pod/Catalyst) has its models, but that doesn't really apply since they
are baked into the framework.  The idea is similar though.

Someone started something that looks vaguely similar called [Trinket](https://metacpan.org/pod/Trinket)
(this was one of the names I was considering and found it by accident)
but it never got any love since initial release in 2012 and is incomplete.

Since Curio can do singletons, you may want to check out
[MooX::Singleton](https://metacpan.org/pod/MooX::Singleton) and [MooseX::Singleton](https://metacpan.org/pod/MooseX::Singleton).

# SUPPORT

Please submit bugs and feature requests to the
Curio GitHub issue tracker:

[https://github.com/bluefeet/Curio/issues](https://github.com/bluefeet/Curio/issues)

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
