[![Actions Status](https://github.com/nukopian/DBIx-Squirrel/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/nukopian/DBIx-Squirrel/actions?workflow=test)
[![CPAN](https://img.shields.io/cpan/v/DBIx-Squirrel)](https://metacpan.org/release/DBIx-Squirrel) [![Kwalitee](https://cpants.cpanauthors.org/dist/DBIx-Squirrel.svg)](https://cpants.cpanauthors.org/dist/DBIx-Squirrel)
<img align="right" src="logo/dbix-squirrel-128.png" alt="DBIx::Squirrel logo" width="128">

# DBIx-Squirrel

You write the SQL; DBIx::Squirrel takes away the DBI machinery around
it, with placeholders in any common style, a list into `IN (...)` from
one placeholder, and results read through an iterator, and every
handle is still a DBI handle. Rows can also be changed as they're
read, by small functions written beside the query.

```perl
my $albums = $dbh->iterate(
    'SELECT title, year FROM album WHERE artist_id = :artist ORDER BY year',
    artist => 2,
    sub { "$_->[0] ($_->[1])" },    # each row made a string
);
while (my($album) = $albums->next) {
    say $album;
}
```

The iterator reads rows as you ask for them, so a large result is
never held in memory unless you ask for all of it.

It isn't an ORM. It never hides the SQL, and never runs a query you
didn't write. Where it and the DBI do the same thing, they give the
same result.

There are three things to learn: placeholders, the iterator, and
stages, the small functions that change rows. Each is useful without
the next, so you can stop at any of them.

## Part 1: DBIx::Squirrel

Everything in this part is DBIx::Squirrel's own. It's the whole
library: a query sent, and its rows read back. Part 2 is about
something else, data going to and from files, and you needn't read it
to use anything here.

## What it saves you

Each of these is work a DBI user does every week, shown first with the
DBI, then with DBIx::Squirrel. The DBI is the foundation;
DBIx::Squirrel does the chores around it.

### A list goes into `IN (...)` without building the SQL.

With the DBI, the statement is built for each list, with a `?` for
each value:

```perl
my $marks = join ', ', ('?') x @years;
my $rows  = $dbh->selectall_arrayref("SELECT title FROM album WHERE year IN ($marks)", undef, @years);
```

A placeholder prefixed with `...` takes an array reference, and the
SQL stays one string, the same whatever the list:

```perl
my $rows = $dbh->selectall_arrayref('SELECT title FROM album WHERE year IN (...:years)', years => \@years);
```

### Values bound in the wrong place are caught.

With `?`, values go in the order the marks appear, so two swapped run
without a word, and here update nothing:

```
$dbh->do('UPDATE track SET plays = ? WHERE id = ?', undef, $id, $plays);
```

Named values go in any order, and one used twice in the SQL is given
once. A name the statement doesn't have, or a placeholder given no
value, croaks before anything runs:

```perl
$dbh->do('UPDATE track SET plays = :plays WHERE id = :id', id => $id, plays => $plays);
$dbh->do('UPDATE track SET plays = :plays WHERE id = :id', id => $id, play => $plays);
# croaks: Expected a placeholder of the statement (play)
```

### Rows are shaped beside the query, and reading stops when it's done.

Say you want the ten most played tracks that aren't on your phone
already, which only your program knows. With the DBI, that's a loop:

```perl
my $sth = $dbh->prepare('SELECT name FROM track ORDER BY plays DESC');
$sth->execute;
my @next_ten;
while (my($name) = $sth->fetchrow_array) {
    next if $on_my_phone{$name};
    push @next_ten, $name;
    last if @next_ten == 10;
}
$sth->finish;
```

With DBIx::Squirrel, the steps are written after the query, each in a
line, and rows stop being read after the tenth:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Stages::Flow qw(drop_if take);

my @next_ten = $dbh->iterate(
    'SELECT name FROM track ORDER BY plays DESC',
    pluck,                           # each row's only column
    drop_if { $on_my_phone{$_} },    # already copied
    take(10),                        # the first ten of what's left
)->all;
```

A `LIMIT 10` in the SQL couldn't do this, as the test is in Perl.
What the SQL can say, it should: a condition or a limit in the query
lets the database use its indexes and send fewer rows.

### One row means one row.

`selectrow_hashref` gives the first row, and says nothing if there
were more:

```perl
my $album = $dbh->selectrow_hashref('SELECT * FROM album WHERE artist_id = ?', undef, 2);
say $album->{title};
```

`single` gives the only row, and warns if there's another. From
`results`, each row has a method for each column, so a misspelt
column dies, where a misspelt hash key gives `undef`:

```perl
my $album = $dbh->results('SELECT * FROM album WHERE artist_id = :artist', artist => 2)->single;
# warns: Expected only one item, but there were more
say $album->title;
```

## One step at a time

You can take it up a step at a time, and stop at any step. Each works
on its own, and code written for the DBI keeps working at every one.

### 1. Connect with it.

```perl
use DBIx::Squirrel;

my $dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', '', '');
```

Your DBI code runs as it did: `$dbh->isa('DBI::db')` is true, as
`$sth->isa('DBI::st')` is for its statements. `connect` and `prepare`
croak if they fail, so there's no `or die` to write.

### 2. Write placeholders in the style you like.

```perl
my $sth = $dbh->prepare('SELECT title FROM album WHERE artist_id = :artist AND year > :year');
$sth->execute(artist => 2, year => 1994);

my $album = $dbh->selectrow_hashref('SELECT * FROM album WHERE id = $1', 2);
```

`?`, `?1`, `:1`, `$1`, `:name` and `$name` are each rewritten as
`?` for the DBI. They work on any driver, whatever placeholders it
supports itself, so SQL written with PostgreSQL's `$1` runs unchanged
on SQLite. A numbered or named placeholder takes one value, wherever
it appears, and a list placeholder, written `...:name`, takes an array
reference.

`do` returns the number of rows changed, as the DBI's does, and
`0E0`, true but zero, when there were none:

```perl
my $changed = $dbh->do('UPDATE track SET plays = plays + 1 WHERE id = :id', id => $id);
say 'No such track' if $changed == 0;
```

### 3. Iterate over the results.

```perl
my $albums = $dbh->iterate('SELECT title, year FROM album ORDER BY year');
while (my($album) = $albums->next) {
    say "$album->[0] ($album->[1])";
}
```

`iterate` takes the SQL, then the bind values, and gives an iterator.
Rows are fetched in batches, so a large result is read a row at a
time, without holding all of it in memory, and the statement is
finished when the rows run out. The iterator's other methods take the
rest at once: `all`, nearly as quickly as plain DBI, as a list,
`all_arrayref` as an array reference, `first` the next, and
`single` the only one, warning if there's another.

Attributes, where you give them, come straight after the SQL, before
the values, as with `do`. Those whose names start `ekorn_` are
DBIx::Squirrel's own, such as `ekorn_slice`, which fetches rows as
hashes:

```perl
my $artists = $dbh->iterate(
    'SELECT id, name FROM artist WHERE id > :id ORDER BY id',
    {ekorn_slice => {}},
    id => 1,
);
say $_->{name} for $artists->all;
```

### 4. Add stages.

```perl
my @hits = $dbh->iterate(
    'SELECT name, plays FROM track WHERE plays >= 5000 ORDER BY plays DESC',
    sub { "$_->[0] ($_->[1])" },    # make each a string
)->all;
```

Stages come after the bind values. Each row goes through them in turn,
given as `$_`. A stage returns one value in the row's place, nothing
to drop the row, or several. `DBIx::Squirrel::Stop` lets a stage end
the run early. To change every row of a large result, `map` over
`all` is quicker; stages are for rows read one at a time, for runs
that stop early, and for steps that should stay with the query.

Ready-made stages come in four modules, each exporting the first it
names, and the rest on request:

- [DBIx::Squirrel::Stages::Rows](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AStages%3A%3ARows): `pluck`, a column of each
row, and `as_hash`, each row as a hash.
- [DBIx::Squirrel::Stages::Flow](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AStages%3A%3AFlow): `take` and `drop`, the first
so many rows or all but them, with `take_if`, `drop_if`,
`take_while`, `drop_while` and more.
- [DBIx::Squirrel::Stages::Batch](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AStages%3A%3ABatch): `batch`, rows in arrays of
so many, and `collect`, all of them in one.
- [DBIx::Squirrel::Stages::Taps](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AStages%3A%3ATaps): `peek`, to watch rows go by
without changing them, and `count_into`, to count them, with
`dump_to` on request.

While debugging, `peek { warn ... }` anywhere among the stages shows
the rows going by, with no change to the query.

### 5. Have rows as objects.

```perl
my $album = $dbh->results('SELECT * FROM album WHERE id = :id', id => 2)->single;
say $album->title, ' (', $album->year, ')';
```

Each row has a method for each column, and stages can work on the
objects.

### 6. If you like, give your databases and statements names.

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Sugar
    database  => {music => ['dbi:SQLite:dbname=music.db', '', '']},
    statement => {
        titles_by => [music => 'SELECT title FROM album WHERE artist_id = ?', pluck],
    };

my @titles = titles_by(2)->all;
my $first  = titles_by(2)->first;
```

[DBIx::Squirrel::Sugar](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3ASugar) makes each a function with its own name, and
a statement's stages are declared beside its SQL. Called, it gives an
iterator over the results. Stages given in the call run after the
statement's own, so code that uses a statement can add a step, such
as `take`, without changing the SQL other code shares.

## Where you can stop

That's DBIx::Squirrel: placeholders, the iterator and stages, on
handles that are still the DBI's. Rows as objects and named statements
are conveniences built on them. If it does what you need, you can stop
here, and nothing else is needed.

## Installing

```
cpanm DBIx::Squirrel
```

It needs Perl 5.36 or later.

## Part 2: With Ekorn::Pipeline

Part 1 is the round trip to the database: a query sent, and its rows
read back. Part 2 is data crossing the database's edge: query results
written to files, JSON and CSV, loaded from them in batches, or sent
to several places in one run. That's Ekorn::Pipeline's work, and
DBIx::Squirrel's iterator is one of its sources.

Stages began in DBIx::Squirrel, in 2024, as a way to change query
results as they're fetched. The pipeline behind them was useful, and
usable, well beyond database rows, so in 2026 it moved into a
distribution of its own,
[Ekorn::Pipeline](https://github.com/nukopian/Ekorn-Pipeline), as
[the guide's Part 2](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AManual%3A%3AHowTo#Part-2:-With-Ekorn::Pipeline)
tells.

With it, a query goes to a CSV file in one call, with its column names
as the header:

```perl
use DBIx::Squirrel::Tooling qw(to_csv);

$dbh->iterate('SELECT name, plays FROM track', to_csv(file => 'tracks.csv', header => 1));
```

[DBIx::Squirrel::Tooling](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3ATooling) imports DBIx::Squirrel's stages and
Ekorn::Pipeline's sources, sinks and words from one module, by tags.
The guide's Part 2 shows them at work with a database, and
[Ekorn::Pipeline](https://metacpan.org/pod/Ekorn%3A%3APipeline)'s own documents say the rest.

## Documentation

[The user guide](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AManual%3A%3AHowTo) is a tour, with recipes
that work: its Part 1 covers DBIx::Squirrel, and its Part 2 the work
it does with Ekorn::Pipeline. Its "When should I use it, and when
not?" says where the package helps, and where plain DBI or SQL is the
better choice. [The reference](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AManual%3A%3AReference)
describes every feature in detail, with examples, in the same two
parts. Each module's POD, starting with [DBIx::Squirrel](https://metacpan.org/pod/DBIx%3A%3ASquirrel), says the
same more briefly.

## Upgrading

This is version 4. Code written for 3.x runs as it did, but for one
change: `pipe`, in scalar context, gives what a pipeline gives, not
the first result, as
[Upgrading from 3.x](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AManual%3A%3AReference#Upgrading-from-3.x),
in the reference, says.

Version 3 built on Ekorn::Pipeline, and made one rule of what a call
with stages gives: an iterator, unless a sink given last says
otherwise. Most code written for 2.x runs as it did, and
[Upgrading from 2.x](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AManual%3A%3AReference#Upgrading-from-2.x)
lists what changes.

Version 2 was a rewrite. Code written for 1.x needs changes to run,
and
[Upgrading from 1.x](https://metacpan.org/pod/DBIx%3A%3ASquirrel%3A%3AManual%3A%3AReference#Upgrading-from-1.x)
lists them. To stay on 1.x, which also runs on older Perls, install
its last version:

```
cpanm DBIx::Squirrel@1.6.5
```

Its code is in the archived
[DBIx-Squirrel-1](https://github.com/nukopian/DBIx-Squirrel-1)
repository.

The repository was called DBIx-Squirrel-2 while version 2 was in
development. It took the original name, DBIx-Squirrel, before its
first release.

## Licence

Copyright (c) 2024-2026 by Iain Campbell. This is free software; you
can redistribute it and/or modify it under the same terms as the Perl
5 programming language system itself. See the file `LICENSE`.

## Acknowledgements

Designed and created by Iain Campbell, in collaboration with Claude,
Anthropic's AI model.
