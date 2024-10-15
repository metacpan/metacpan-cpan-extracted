[![ci](https://github.com/paultcochrane/DBIx-Class-ResultSet-PrettyPrint/actions/workflows/ci.yml/badge.svg)](https://github.com/paultcochrane/DBIx-Class-ResultSet-PrettyPrint/actions/workflows/ci.yml)

# DBIx-Class-ResultSet-PrettyPrint - pretty print DBIC result sets

This is a very simple module to pretty print [DBIx::Class::ResultSet
objects](https://metacpan.org/pod/DBIx::Class::ResultSet).

## SYNOPSIS

```perl
use DBIx::Class::ResultSet::PrettyPrint;
use Schema;  # load your DBIx::Class schema

# load your database and fetch a result set
my $schema = Schema->connect( 'dbi:SQLite:books.db' );
my $books = $schema->resultset( 'Book' );

# pretty print the result set
my $pp = DBIx::Class::ResultSet::PrettyPrint->new();
$pp->print_table( $books );

+----+---------------------+---------------+------------+-----------+---------------+
| id | title               | author        | pub_date   | num_pages | isbn          |
+----+---------------------+---------------+------------+-----------+---------------+
| 2  | Perl by Example     | Ellie Quigley | 1994-01-01 | 200       | 9780131228399 |
| 4  | Perl Best Practices | Damian Conway | 2005-07-01 | 517       | 9780596001735 |
+----+---------------------+---------------+------------+-----------+---------------+
```

## DESCRIPTION

Ever wanted to quickly visualise what a `DBIx::Class` result set looks like
(for instance, in tests) without having to resort to reproducing the query
in SQL in a DBMS REPL?  This is what this module does: it pretty prints
result sets wherever you are, be it in tests or within a debugging session.

While searching for such a solution, I stumbled across [an answer on
StackOverflow](https://stackoverflow.com/a/4072923/10874800) and thought:
that would be nice as a module.  And so here it is.

## INSTALLATION

To install this module, run the following commands:

```shell
$ perl Makefile.PL
$ make
$ make test
$ make install
```

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

```
$ perldoc DBIx::Class::ResultSet::PrettyPrint
```

Bug reports and pull requests are welcome.  Please submit these to the
[project's GitHub
repository](https://github.com/paultcochrane/DBIx-Class-ResultSet-PrettyPrint).

## LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Paul Cochrane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
