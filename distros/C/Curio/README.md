# NAME

Curio - Procurer of fine resources and services.

# SYNOPSIS

Create a Curio class:

```perl
package MyApp::Service::Cache;

use CHI;
use Types::Standard qw( InstanceOf );

use Curio;
use strictures 2;

with 'MooX::BuildArgs';

use Exporter qw( import );
our @EXPORT = qw( myapp_cache );

does_caching;
cache_per_process;

add_key geo_ip => (
    driver => 'Memory',
    global => 0,
);

has chi => (
    is  => 'lazy',
    isa => InstanceOf[ 'CHI::Driver' ],
);

sub _build_chi {
    my ($self) = @_;
    my $chi = CHI->new( %{ $self->build_args() } );
    $self->clear_build_args();
    return $chi;
}

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
[Catalyst](https://metacpan.org/pod/Catalyst) or [Dancer2](https://metacpan.org/pod/Dancer2), then you may want to take a look at the
available ["INTEGRATIONS"](#integrations).

Keep in mind that Curio doesn't just have to be used for connections
to remote services.  It can be used to make singleton classes, as a
ready to go generic object factory, a place to put global application
context information, etc.

# BEWARE OF EARLY RELEASES

The first versions of Curio that are hitting CPAN are early releases
and may see major interface changes before things settle down.  This
notice will be removed when that point is reached.

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

See ["AVAILABLE ROLES"](#available-roles) for a list of existing Curio roles.

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

# MOTIVATION

The main drive behind using Curio is threefold.

1. To avoid the extra complexity of passing around references of shared
resources, such as connections to services.  Often times you'll see
code which passes a connection to a function, which then passes that
on to another function, which then creates an object with the connection
passed as an argument, etc.  This is what is being avoided; it's a messy
way to writer code and prone to error.
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

These challenges can be solved by Curio and, by solving them,
your applications will be more robust and resilient to change.

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

Read more of the reasoning for this in ["MOTIVATION"](#motivation).

## Use Curio Directly

It is tempting to use the ["INTEGRATIONS"](#integrations) such as
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
does cause unnecessary confusion.

# AVAILABLE ROLES

These roles, available on CPAN, provide a base set of functionality
for your Curio classes to wrap around specific resource types.

- [Curio::Role::CHI](https://metacpan.org/pod/Curio::Role::CHI)

Roles for [DBI](https://metacpan.org/pod/DBI) and [DBIx::Class](https://metacpan.org/pod/DBIx::Class) are in the works.

# INTEGRATIONS

The CPAN modules listed here integrate Curio with other things
such as web frameworks.

- [Catalyst::Model::Curio](https://metacpan.org/pod/Catalyst::Model::Curio)

On a related note, take a look at ["Use Curio Directly"](#use-curio-directly).

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
