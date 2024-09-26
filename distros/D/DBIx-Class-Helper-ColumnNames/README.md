# NAME

DBIx::Class::Helper::ColumnNames - Retrieve column names from a resultset

# VERSION

version v0.1.1

# SYNOPSIS

In a resultset:

```perl
package MyApp::Schema::ResultSet::Wobbles;

use base qw/DBIx::Class::ResultSet/;

__PACKAGE__->load_components( qw/
    Helper::ColumnNames
/);
```

This adds a ["get\_column\_names"](#get_column_names) method to the resultset.

# DESCRIPTION

This method is useful for simple applications that extract a column header from arbitrary result sets, to display an
HTML table or to export as a spreadsheet, for example.

# METHODS

## get\_column\_names

```perl
my @header = $rs->get_column_names;
```

This method attempts to return the column names of the resultset.

If no columns are specified using the `columns` or `select` attributes, then it will return the default columns names.

# CAVEATS

This module is experimental, and relies on some internals from [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass).

# SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.20 or later.

Future releases may only support Perl versions released in the last ten years.

# SEE ALSO

[DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass)

# SOURCE

The development version is on github at [https://github.com/robrwo/DBIx-Class-Helper-ResultSet-ColumnNames](https://github.com/robrwo/DBIx-Class-Helper-ResultSet-ColumnNames)
and may be cloned from [git://github.com/robrwo/DBIx-Class-Helper-ResultSet-ColumnNames.git](git://github.com/robrwo/DBIx-Class-Helper-ResultSet-ColumnNames.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/DBIx-Class-Helper-ResultSet-ColumnNames/issues](https://github.com/robrwo/DBIx-Class-Helper-ResultSet-ColumnNames/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
