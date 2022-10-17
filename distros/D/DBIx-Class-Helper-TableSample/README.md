# NAME

DBIx::Class::Helper::TableSample - Add support for tablesample clauses

# VERSION

version v0.3.2

# SYNOPSIS

In a resultset:

```perl
package MyApp::Schema::ResultSet::Wobbles;

use base qw/DBIx::Class::ResultSet/;

__PACKAGE__->load_components( qw/
    Helper::TableSample
/);
```

Using the resultset:

```perl
my $rs = $schema->resultset('Wobbles')->search_rs(
  undef,
  {
    columns     => [qw/ id name /],
    tablesample => {
      method   => 'system',
      fraction => 0.5,
    },
  }
);
```

This generates the SQL

```
SELECT me.id, me.name FROM table me TABLESAMPLE SYSTEM (0.5)
```

# DESCRIPTION

This helper adds rudimentary support for tablesample queries
to [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) resultsets.

The `tablesample` key supports the following options as a hash
reference:

- `fraction`

    This is the percentage or fraction of the table to sample,
    between 0 and 100, or a numeric expression that returns
    such a value.

    (Some databases may restrict this to an integer.)

    The value is not checked by this helper, so you can use
    database-specific extensions, e.g. `1000 ROWS` or `15 PERCENT`.

    Scalar references are dereferenced, and expressions or
    database-specific extensions should be specified has scalar
    references, e.g.

    ```perl
    my $rs = $schema->resultset('Wobbles')->search_rs(
      undef,
      {
        columns     => [qw/ id name /],
        tablesample => {
          fraction => \ "1000 ROWS",
        },
      }
    );
    ```

- `method`

    By default, there is no sampling method, e.g. you can simply use:

    ```perl
    my $rs = $schema->resultset('Wobbles')->search_rs(
      undef,
      {
        columns     => [qw/ id name /],
        tablesample => 5,
      }
    );
    ```

    as an equivalent of

    ```perl
    my $rs = $schema->resultset('Wobbles')->search_rs(
      undef,
      {
        columns     => [qw/ id name /],
        tablesample => { fraction => 5 },
      }
    );
    ```

    to generate

    ```
    SELECT me.id FROM table me TABLESAMPLE (5)
    ```

    If your database supports or requires a sampling method, you can
    specify it, e.g. `system` or `bernoulli`.

    ```perl
    my $rs = $schema->resultset('Wobbles')->search_rs(
      undef,
      {
        columns     => [qw/ id name /],
        tablesample => {
           fraction => 5,
           method   => 'system',
        },
      }
    );
    ```

    will generate

    ```
    SELECT me.id FROM table me TABLESAMPLE SYSTEM (5)
    ```

    See your database documentation for the allowable methods.  Note that some databases require it.

    Prior to version 0.3.0, this was called `type`. It is supported for
    backwards compatability.

- `repeatable`

    If this key is specified, then it will add a REPEATABLE clause,
    e.g.

    ```perl
    my $rs = $schema->resultset('Wobbles')->search_rs(
      undef,
      {
        columns     => [qw/ id name /],
        tablesample => {
          fraction   => 5,
          repeatable => 123456,
        },
      }
    );
    ```

    to generate

    ```
    SELECT me.id FROM table me TABLESAMPLE (5) REPEATABLE (123456)
    ```

    Scalar references are dereferenced, and expressions or
    database-specific extensions should be specified has scalar
    references.

# KNOWN ISSUES

Resultsets with joins or inner queries are not supported.

Delete and update queries are not supported.

Oracle has a non-standard table sampling syntax, so is not yet supported.

Not all databases support table sampling, and those that do may have
different restrictions.  You should consult your database
documentation.

# SEE ALSO

[DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass)

# SOURCE

The development version is on github at [https://github.com/robrwo/-DBIX-Class-Helper-TableSample](https://github.com/robrwo/-DBIX-Class-Helper-TableSample)
and may be cloned from [git://github.com/robrwo/-DBIX-Class-Helper-TableSample.git](git://github.com/robrwo/-DBIX-Class-Helper-TableSample.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/-DBIX-Class-Helper-TableSample/issues](https://github.com/robrwo/-DBIX-Class-Helper-TableSample/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2022 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
