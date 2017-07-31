# Overview

Each database has:

* sqlite3 database handle
* a (system-level) thread
* eventfd filehandle

Threads are not exposed as Perl threads, but instead are created and maintained
in the background.

You create a dbh from a filename. If open/creation succeeds, an eventfd is created,
and the database thread starts.

Any information from the database thread is propagated to the main thread via
eventfd - a notification is sent when there is a pending data from sqlite,
typically a new row of data to be read or an SQL operation which has completed.

Acccess to this vector is protected by a mutex.

# Database methods

## prepare

`my $sth = $dbh->prepare(q{select * from whatever});`

Prepares the given SQL statement. Returns a handle.

## do

`$dbh->do(q{...})->get;`

## commit

## rollback

# Statement handle methods

## execute

`$sth->execute()`

Combines parameter binding with step.

Effectively this:

```
$sth->bind($_ => $param[$_]) for 0..$#param;
Future::Utils::repeat_until_done {
	$sth->step
}
```

## step

Steps the given statement.

## reset

Reset state.

## `bind`

Binds a numeric parameter value.

## `bind_named`


