# NAME

DBIx::Class::Relationship::ManyToMany::Async - many\_to\_many for DBIx::Class::Async — generates Future-returning

# VERSION

version 0.01

# SYNOPSIS

    # In MySchema::Result::User.pm
    __PACKAGE__->has_many(
        'user_group',
        'MySchema::Result::UserGroup',
        'user_id',
    );

    use DBIx::Class::Relationship::ManyToMany::Async;
    __PACKAGE__->many_to_many_async('groups', 'user_group', 'group');

    # In MySchema::Result::UserGroup.pm (the pivot)
    __PACKAGE__->belongs_to(
        'user',
        'MySchema::Result::User',
        { 'foreign.id' => 'self.user_id' },
    );
    __PACKAGE__->belongs_to(
        'group',
        'MySchema::Result::Group',
        { 'foreign.id' => 'self.group_id' },
    );

    # Usage from a controller
    my @groups = @{ $schema->await($user->groups) };
    say $_->name for @groups;

# DESCRIPTION

Unlike [DBIx::Class::Relationship::ManyToMany](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ARelationship%3A%3AManyToMany), the standard
`many_to_many` helper, this module generates accessor methods that
return [Future](https://metacpan.org/pod/Future) objects instead of blocking. This makes them
compatible with [DBIx::Class::Async](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AAsync) worker pools.

The generated methods are named after the first argument passed to
`many_to_many_async`. For example, with `'groups'` as the first
argument, the following methods are created:

- `groups`

    Read accessor. Fetches all related target objects via a single JOIN
    (prefetch on the pivot relationship). Returns a Future resolving to
    an arrayref of target objects.

- `add_to_groups($target)`

    Links a target object to the source row by inserting a pivot row.
    Returns a Future resolving to the target object.

- `remove_from_groups($target)`

    Unlinks a target object by deleting the corresponding pivot row.
    Returns a Future.

- `set_groups(\\@targets)`

    Replaces all links: deletes existing pivot rows, then inserts new ones.
    Returns a Future.

The underlying `has_many` (pivot) and `belongs_to` (target)
relationships must be declared in the Result classes before calling
`many_to_many_async`. The method does not create them automatically.

## Arguments

- `$meth`

    Accessor name. Generates `${meth}`, `add_to_${meth}`,
    `remove_from_${meth}`, and `set_${meth}` methods.
    Example: `'groups'` produces `groups`, `add_to_groups`, etc.

- `$rel`

    The `has_many` relationship name from the source table to the pivot.
    Example: `'user_group'`.

- `$f_rel`

    The `belongs_to` relationship name from the pivot to the target table.
    Example: `'group'`.

## Limitations

The foreign table's primary key is assumed to be named `id`.
Tables with custom PK names (e.g. `idgroup`) are not yet supported.

SQL reserved words (`group`, `order`, etc.) used as the third argument
(`$f_rel`) cause `DBD::SQLite` errors in JOINs. Set `quote_char` in
both the DBI attributes and the async options (value depends on the
database: `\"` for SQLite/PostgreSQL, `` ` `` for MySQL):

    DBIx::Class::Async::Schema->connect(
        $dsn, $user, $pass,
        { quote_char => '\"', name_sep => '.' },
        { workers => 2, dbi_attrs => { quote_char => '\"' }, ... },
    );

Or use a non-reserved relationship name.

# STATUS

**EXPERIMENTAL.** This is a first release extracted from
[Mojolicious::Plugin::Fondation::Model::DBIx::Async](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AModel%3A%3ADBIx%3A%3AAsync). The API may
change. Feedback and bug reports welcome.

# ACKNOWLEDGMENTS

This module was developed with significant assistance from an AI coding
agent. It is quite possible that I got lost in the intricacies of
[DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) and [DBIx::Class::Async](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AAsync) — please be indulgent. All
remarks and observations are welcome.

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
