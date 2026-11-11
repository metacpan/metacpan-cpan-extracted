[![Actions Status](https://github.com/nukopian/DBIx-Squirrel/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/nukopian/DBIx-Squirrel/actions?workflow=test)
[![CPAN](https://img.shields.io/cpan/v/DBIx-Squirrel)](https://metacpan.org/release/DBIx-Squirrel) [![Kwalitee](https://cpants.cpanauthors.org/dist/DBIx-Squirrel.svg)](https://cpants.cpanauthors.org/dist/DBIx-Squirrel)

# DBIx-Squirrel

DBI, minus the boilerplate, plus a pipeline.

With DBIx::Squirrel, you still write SQL, as you do with the DBI. It
takes away the friction around it: placeholders in whatever style you
like, iterators over results, and a pipeline of transformations written
beside the query. It never hides the SQL, and it isn't an ORM.

    my @names = $dbh->iterate(
        'SELECT name FROM track WHERE plays > :plays ORDER BY plays DESC',
        plays => 6000,
        sub { $_->[0] },    # each row's name
        sub { uc },         # in capitals
    )->all;

It's a subclass of the DBI, so everything the DBI does still works.
Where the two do the same thing, they give the same result.

## Why use it

The DBI is the right foundation, and it's low-level on purpose. Most
code written around it does the same few chores, by hand, each time.
DBIx::Squirrel does them for you.

- **Placeholders you can read.**

    With `?`, values go in the order the marks appear. A value used twice
    is passed twice, and changing the SQL can mean changing the code that
    calls it. Named placeholders bind by name, with each value given once.
    They work on any driver, whatever placeholders it supports itself, so
    SQL written with PostgreSQL's `$1` runs unchanged on SQLite. Values
    that don't match the placeholders croak, rather than being bound in
    the wrong place.

- **Rows that come out ready to use.**

    There's no fetch loop to write, and no array to push onto. The stages
    that map, filter and expand the rows sit beside the query. You can
    read what a result holds next to the SQL that makes it. Rows are
    fetched in batches, so you can work through a large result a row at
    a time without holding all of it in memory. Ready-made stages do the
    common jobs, such as taking the first few rows, picking out a column,
    or handing rows out in batches.

- **Queries with names.**

    A statement and its stages can become a function with a name of its
    own. The SQL is written in one place, and the code that uses it reads
    as plainly as `titles_by 2`.

- **Nothing to unlearn, and nothing to undo.**

    Your handles, attributes, drivers and existing code all still work,
    because it's still the DBI. Use as much as helps, and stop there. It
    isn't an ORM. You write the SQL, so everything your database can do is
    still there, and it never runs a query you didn't write.

## One step at a time

You can take it up a step at a time, and stop at any step. Each works
on its own, and code written for the DBI keeps working at every one.

### 1. Connect with it.

    use DBIx::Squirrel;

    my $dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', '', '');

Your DBI code runs as it did. `connect` and `prepare` croak if they
fail, so there's no `or die` to write.

### 2. Write placeholders in the style you like.

    my $sth = $dbh->prepare('SELECT title FROM album WHERE artist_id = :artist AND year > :year');
    $sth->execute(artist => 2, year => 1994);

    my $album = $dbh->selectrow_hashref('SELECT * FROM album WHERE id = $1', 2);

`?`, `?1`, `:1`, `$1`, `:name` and `$name` are each rewritten
as `?` for the DBI. A numbered or named placeholder takes one value,
wherever it appears. `do` and the select methods need no `undef`
before the values.

    my $of_years = $dbh->selectall_arrayref('SELECT * FROM album WHERE year IN (...:years)',
        years => [1967, 1994]);

A placeholder with `...` before it takes a list. It's written as a
`?` for each value in the array reference given.

### 3. Iterate over the results.

    my $albums = $dbh->iterate('SELECT title, year FROM album ORDER BY year');
    while (my($row) = $albums->next) {
        say "$row->[0] ($row->[1])";
    }

Rows are fetched in batches, and the statement is finished when they run
out. `all` takes the rest at once, nearly as quickly as plain DBI.
`single` takes the only one.

### 4. Add stages.

    my @hits = $dbh->iterate(
        'SELECT name, plays FROM track ORDER BY plays DESC',
        sub { $_->[1] >= 5000 ? $_ : () },    # leave out the rest
        sub { "$_->[0] ($_->[1])" },          # make each a string
    )->all;

Each row goes through the stages, given as `$_`. A stage returns
nothing to drop the row, one value in its place, or several. It can
also stop the iteration early. A stage made with `gather` can hold
rows, and give them out at the end, in batches or as one value. `pipe`
runs anything else through stages the same way.

Ready-made stages come with it, for jobs that come up again and again.
They're in four modules: `take` and `drop` in
[DBIx::Squirrel::Stages::Flow](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AStages%3A%3AFlow), `pluck` and `as_hash` in
[DBIx::Squirrel::Stages::Rows](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AStages%3A%3ARows), `batch` and `collect` in
[DBIx::Squirrel::Stages::Batch](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AStages%3A%3ABatch), and `peek` and `count_into` in
[DBIx::Squirrel::Stages::Taps](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AStages%3A%3ATaps):

    use DBIx::Squirrel::Stages::Flow;
    use DBIx::Squirrel::Stages::Rows;

    my @top_ten = $dbh->iterate(
        'SELECT name, plays FROM track ORDER BY plays DESC',
        sub { $_->[1] >= 5000 ? $_ : () },    # leave out the rest
        pluck('name'), take(10),
    )->all;

The reference says how to write your own stages to work alongside
them.

The pipeline is [Ekorn::Pipeline](https://github.com/nukopian/Ekorn-Pipeline).
It began here, and is now a distribution of its own, so that any
function can take stages from its caller. DBIx::Squirrel keeps its own
names for the modules. The stages that need a database, such as
`pluck`, are DBIx::Squirrel's own.

### 5. Have rows as objects.

    my $album = $dbh->results('SELECT * FROM album WHERE id = :id', id => 2)->single;
    say $album->title, ' (', $album->year, ')';

Each row has a method for each column, and stages can work on the
objects.

### 6. Give your databases and statements names.

    use DBIx::Squirrel::Sugar
        database  => {music => ['dbi:SQLite:dbname=music.db', '', '']},
        statement => {
            titles_by => [music => 'SELECT title FROM album WHERE artist_id = ?', sub { $_->[0] }],
        };

    my @titles = titles_by 2;

[DBIx::Squirrel::Sugar](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3ASugar) makes each a function with its own name. A
statement's stages are declared beside its SQL.

## Documentation

[The reference](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AManual%3A%3AReference) describes every
feature in detail, with examples.
[The how-to](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AManual%3A%3AHowTo) shows how to do common
tasks, one recipe at a time. Each module's POD, starting with
[DBIx::Squirrel](https://metacpan.org/pod/DBIx%3A%3ASquirrel), says the same more briefly.

## Installing

    cpanm DBIx::Squirrel

It needs Perl 5.36 or later.

## Upgrading from 1.x

Version 2 is a rewrite. Code written for 1.x needs changes to run, and
[Upgrading from 1.x](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AManual%3A%3AReference#Upgrading-from-1.x),
in the reference, lists them. To stay on 1.x, which also runs on older
Perls, install its last version:

    cpanm DBIx::Squirrel@1.6.5

Its code is in the archived
[DBIx-Squirrel-1](https://github.com/nukopian/DBIx-Squirrel-1)
repository.

The repository was called DBIx-Squirrel-2 while version 2 was in
development. It took the original name, DBIx-Squirrel, before its first
release.

## Licence

Copyright (c) 2024-2026 by Iain Campbell. This is free software; you can
redistribute it and/or modify it under the same terms as the Perl 5
programming language system itself. See the file `LICENSE`.

## Acknowledgements

Written by Iain Campbell, with Claude, Anthropic's AI model. Claude
reviews the code, and writes parts of it where Iain asks, often from
his code for version 1. It also helps with the Git Ops, the
repository's setup, and the tests and documentation.
