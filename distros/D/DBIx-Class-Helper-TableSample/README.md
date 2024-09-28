# NAME

DBIx::Class::Helper::TableSample - Add support for tablesample clauses

# VERSION

version v0.7.0

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

# METHODS

## search\_rs

This adds a `tablesample` key to the search options, for example

```perl
$rs->search_rs( undef, { tablesample => 10 } );
```

or

```perl
$rs->search_rs( undef, { tablesample => { fraction => 10, method => 'system' } } );
```

Normally the value is a fraction, or a hash reference with the following options:

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

    The `fraction` and `method` options are not restricted, so they can be used with a variety of databases or
    extensions. For example, if you have the PostgreSQL `tsm_system_rows` extension:

    ```perl
    my $rs = $schema->resultset('Wobbles')->search_rs(
      undef,
      {
        columns     => [qw/ id name /],
        tablesample => {
           fraction => 200,
           method   => 'system_rows',
        },
      }
    );
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

## tablesample

```perl
my $rs = $schema->resultset('Wobbles')->tablesample( $fraction, \%options );

my $rs = $schema->resultset('Wobbles')->tablesample( 10, { method => 'system' } );
```

This is a helper method.

It was added in v0.4.1, since v0.6.1 you can use a method name instead of an options hash reference:

```perl
my $rs = $schema->resultset('Wobbles')->tablesample( 10, 'system' );
```

# KNOWN ISSUES

Delete and update queries are not supported.

Oracle has a non-standard table sampling syntax, so is not yet supported.

Not all databases support table sampling, and those that do may have
different restrictions.  You should consult your database
documentation.

# SUPPORT FOR OLDER PERL VERSIONS

Since v0.4.0, the this module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten years.

If you need this module on Perl v5.10, please use one of the v0.3.x
versions of this module.  Significant bug or security fixes may be
backported to those versions.

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

This software is Copyright (c) 2019-2023 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
