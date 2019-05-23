# NAME

Code::Style::Kit - build composable bulk exporters

# DESCRIPTION

This package simplifies writing "code style kits". A kit (also known
as a "policy") is a module that encapsulates the common pragmas and
modules that every package in a project should use. For instance, it
might be a good idea to always `use strict`, enable method
signatures, and `use true`, but it's cumbersome to put that
boilerplate in every single file in your project. Now you can do that
with a single line of code.

`Code::Style::Kit` is _not_ to be `use`d directly: you must write a
package that inherits from it. Your package can (and probably should)
also inherit from one or more "parts". See [`Code::Style::Kit::Parts`](https://metacpan.org/pod/Code::Style::Kit::Parts) for information about the parts included
in this distribution.

*Please* don't use this for libraries you intend to distribute on
CPAN: you'd be forcing a bunch of dependencies on every user. These
kits are intended for applications, or "internal" libraries that don't
get released publicly.

# AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
