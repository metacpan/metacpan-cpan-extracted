# Cloudflare::API::Resource #

# NAME #

Cloudflare::API::Resource - shared base class for Cloudflare resource objects

# SYNOPSIS #

```perl
my $r2=$api->r2();
my $client=$r2->api();
```

# DESCRIPTION #

`Cloudflare::API::Resource` holds the parent `Cloudflare::API` client used by the resource modules. Applications normally obtain a concrete resource object through a parent accessor such as `r2()` or `workers()`. The base class does not make requests on its own.

# METHODS #

* **new($api)** — Construct a resource object retaining a `Cloudflare::API` instance. Throws if the argument is not a `Cloudflare::API` object. Subclasses inherit this constructor; it returns an object of the invoked class.
* **api()** — Return the retained `Cloudflare::API` object. Resource methods use it for authenticated requests and account context.

# SEE ALSO #

[Cloudflare::API](../API.pm.md)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
