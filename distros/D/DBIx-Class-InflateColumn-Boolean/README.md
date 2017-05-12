# DBIx::Class::InflateColumn::Boolean [![Build Status](https://travis-ci.org/augensalat/DBIx-Class-InflateColumn-Boolean.svg?branch=master)](https://travis-ci.org/augensalat/DBIx-Class-InflateColumn-Boolean)

Perl does not have a native boolean data type by itself, it takes certain
several scalar values as `false` (like '', 0, 0.0) as well as empty lists
and `undef`, and everything else is `true`. It is also possible to set the
boolean value of an object instance.

As in most program code you have boolean data in nearly every database.
But for a database it is up to the designer to decide what is `true` and
what is `false`.

This module maps such "database booleans" into "Perl booleans" and back by
inflating designated columns into objects, that store the original value,
but also evaluate as true or false in boolean context.  Therefore - if
"Yes" in the database means `true` and "No" means `false` in the
application the following two lines can virtually mean the same:


```perl
if ($table->field eq "No") { ... }
if (not $table->field) { ... }
```

That means that `$table->field` has the scalar value "No", but is taken as
`false` in a boolean context, whereas Perl would normally regard the string
"No" as `true`.

When writing to the database, of course `$table->field` would be deflated
to the original value "No" and not some Perlish form of a boolean.

## Installation

Stable releases are available from the
[CPAN](https://metacpan.org/release/DBIx-Class-InflateColumn-Boolean).

You can use [cpanm](https://metacpan.org/pod/App::cpanminus) to install from
the command line:

```
$ cpanm DBIx::Class::InflateColumn::Boolean
```

## More Information

Please look at the
[manpage](https://metacpan.org/pod/DBIx::Class::InflateColumn::Boolean).

