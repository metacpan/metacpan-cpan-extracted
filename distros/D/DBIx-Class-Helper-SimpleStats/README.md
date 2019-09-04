# NAME

DBIx::Class::Helper::SimpleStats - Simple grouping and aggregate functions for DBIx::Class

# VERSION

version v0.1.3

# SYNOPSIS

In a resultset class:

```perl
package My::Schema::ResultSet::Foo;

use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::SimpleStats');

...
```

In code

```perl
my @stats = $rs->simple_stats( 'name' )->all;
```

is roughly equivalent to

```perl
my @stats = $rs->search_rs(
  undef,
  {
    select   => [qw/ name /, { count => 'name' }],
    as       => [qw/ name name_count /],
    group_by => [qw/ name /],
    order_by => [qw/ name /],
  }
)->all;
```

# DESCRIPTION

This is a simple helper method for [DBIx::Class](https://metacpan.org/pod/DBIx::Class) resultsets to run
simple aggregate queries.

# METHODS

## `simple_stats`

```perl
my $stats_rs => $rs->simple_stats( @columns );
```

The simplest usage is to pass a single column name, and obtain a count
of rows for each value of that column.

However, you could specify multiple columns or functions, and optional
column names:

```perl
$rs->simple_stats(
  { min => 'cost' },
  { max => 'cost' },
  { sum => 'cost',   -as => 'total_cost' },
  { count => 'cost', -as => 'num_purchases' },
);
```

# SEE ALSO

[DBIx::Class](https://metacpan.org/pod/DBIx::Class)

# SOURCE

The development version is on github at [https://github.com/robrwo/DBIx-Class-Helper-SimpleStats](https://github.com/robrwo/DBIx-Class-Helper-SimpleStats)
and may be cloned from [git://github.com/robrwo/DBIx-Class-Helper-SimpleStats.git](git://github.com/robrwo/DBIx-Class-Helper-SimpleStats.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/DBIx-Class-Helper-SimpleStats/issues](https://github.com/robrwo/DBIx-Class-Helper-SimpleStats/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
