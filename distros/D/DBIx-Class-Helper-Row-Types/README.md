# NAME

DBIx::Class::Helper::Row::Types - Use Types to define rows

# VERSION

version v0.2.0

# SYNOPSIS

In result class:

```perl
 use Types::SQL -types;

__PACKAGE__->load_components('Helper::Row::Types');

__PACKAGE__->add_column(

   id   => Serial,

   name => {
     isa => Maybe[ Varchar[64] ],
   },
);
```

# DESCRIPTION

This helper allows you to specify column information by passing a
[Type::Tiny](https://metacpan.org/pod/Type::Tiny) object.

Note that this _does not_ enforce that the data is of that type,
unless you specify the `strict` option (See ["set\_column"](#set_column)).  The
main purpose of this is to allow you to use types as a shorthand for
specifying the column type.

You can use types from [Types::SQL](https://metacpan.org/pod/Types::SQL) or supported types from
[Types::Standard](https://metacpan.org/pod/Types::Standard).

# METHODS

## `add_column`

## `add_columns`

These methods are modified to allow you to specify the column info
using the `isa` attribute and a [Type::Tiny](https://metacpan.org/pod/Type::Tiny) type.

Note that in no way does this enforce that type.

## `set_column`

If the `strict` attribute is true for the column, then the type
constraint will be enforced when the column is explicitly set.

If the `coerce` attribute is true, then the type's coercion will be
applied before checking the constraint.

Note that type constraints will not be enforced if you use the
`insert` or resultset `create` methods.

This is entirely separate from database-level constraints.

Enabling `strict` for an inflated column is strongly discouraged.

# KNOWN ISSUES

Strict type constraints are only applied when explicitly setting a
column value.

# ROADMAP

Support for Perl versions earlier than 5.10 will be removed sometime
in 2019.

# SEE ALSO

[DBIx::Class](https://metacpan.org/pod/DBIx::Class)

[Types::SQL](https://metacpan.org/pod/Types::SQL)

[Types::SQL::Util](https://metacpan.org/pod/Types::SQL::Util) provides a list of "standard" types that are
supported.

# SOURCE

The development version is on github at [https://github.com/robrwo/DBIx-Class-Helper-Row-Types](https://github.com/robrwo/DBIx-Class-Helper-Row-Types)
and may be cloned from [git://github.com/robrwo/DBIx-Class-Helper-Row-Types.git](git://github.com/robrwo/DBIx-Class-Helper-Row-Types.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/DBIx-Class-Helper-Row-Types/issues](https://github.com/robrwo/DBIx-Class-Helper-Row-Types/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
