# NAME

DBIx::Class::Helper::WindowFunctions - Add support for window functions and aggregate filters to DBIx::Class

# VERSION

version v0.6.0

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
        avg     => 'fingers',
        -filter => { hats => { '>', 1 } },
        -over   => {
            partition_by => 'hats',
            order_by     => 'age',
        },
    },
    '+as' => 'avg',
  }
);
```

# DESCRIPTION

This helper adds rudimentary support for window functions and aggregate filters to
[DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) resultsets.

It adds the following keys to the resultset attributes:

## -over

This is used for window functions, e.g. the following adds a row number columns

```perl
'+select' => {
    row_number => [],
    -over => {
       partition_by => 'class',
       order_by     => 'score',
    },
},
```

which is equivalent to the SQL

```
ROW_NUMBER() OVER ( PARTITION BY class ORDER BY score )
```

You can omit either the `partition_by` or `order_by` clauses.

## -filter

This is used for filtering aggregate functions or window functions, e.g. the following clause

```perl
'+select' => {
    count     => \ 1,
    -filter => { kittens => { '<', 10 } },
},
```

is equivalent to the SQL

```
COUNT(1) FILTER ( WHERE kittens < 10 )
```

You can apply filters to window functions, e.g.

```perl
'+select' => {
    row_number => [],
    -filter => { class => { -like => 'A%' } },
    -over => {
       partition_by => 'class',
       order_by     => 'score',
    },
},
```

which is equivalent to the SQL

```
ROW_NUMBER() FILTER ( WHERE class like 'A%' ) OVER ( PARTITION BY class ORDER BY score )
```

The `-filter` feature was added v0.6.0.

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
