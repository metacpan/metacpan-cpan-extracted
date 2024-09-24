# NAME

DBIx::Class::Helper::WindowFunctions - Add support for window functions to DBIx::Class

# VERSION

version v0.5.0

# SYNOPSIS

In a resultset:

```perl
package MyApp::Schema::ResultSet::Wobbles;

use base qw/DBIx::Class::ResultSet/;

__PACKAGE__->load_components( qw/
    Helper::WindowFunctions
/);
```

Using the resultset:

```perl
my $rs = $schema->resultset('Wobbles')->search_rs(
  undef,
  {
    '+select' => {
        avg   => 'fingers',
        -over => {
            partition_by => 'hats',
            order_by     => 'age',
        },
    },
    '+as' => 'avg',
  }
);
```

# DESCRIPTION

This helper adds rudimentary support for window functions to
[DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) resultsets.

# CAVEATS

This module is experimental.

Not all databases support window functions.

# SUPPORT FOR OLDER PERL VERSIONS

Since v0.4.0, the this module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten years.

If you need this module on Perl v5.10, please use one of the v0.3.x
versions of this module.  Significant bug or security fixes may be
backported to those versions.

# SEE ALSO

[DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass)

# SOURCE

The development version is on github at [https://github.com/robrwo/DBIx-Class-Helper-ResultSet-WindowFunctions](https://github.com/robrwo/DBIx-Class-Helper-ResultSet-WindowFunctions)
and may be cloned from [git://github.com/robrwo/DBIx-Class-Helper-ResultSet-WindowFunctions.git](git://github.com/robrwo/DBIx-Class-Helper-ResultSet-WindowFunctions.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/DBIx-Class-Helper-ResultSet-WindowFunctions/issues](https://github.com/robrwo/DBIx-Class-Helper-ResultSet-WindowFunctions/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTOR

Peter Rabbitson <ribasushi@leporine.io>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2024 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
