# DBD::Firebird: statements the application still holds are destroyed without a mark, and unlinked a second time when freed

DRAFT, not sent. Target: DBD::Firebird issue tracker. Context: DBIO::Firebird
karr k48 and k49, ADR 0011.

Everything below: DBD::Firebird 1.39, Firebird 5.0.4, dialect 3, raw DBI, no
other module involved. Source references are to `dbdimp.c` of 1.39.

## 1. A statement destroyed by a DDL commit answers without an error

```perl
my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1, AutoCommit => 1 });
$dbh->do('CREATE TABLE t (id INTEGER)');
$dbh->do('INSERT INTO t VALUES (1)');

my $sth = $dbh->prepare('SELECT id FROM t');
$dbh->do('CREATE TABLE other (id INTEGER)');   # DDL: commit

$sth->execute;                                  # true, no error
my @row = $sth->fetchrow_array;                 # warning "no statement
                                                # executing"; @row is empty
```

`ib_commit_transaction` (when `sth_ddl > 0`) and `ib_rollback_transaction`
(when `sth_ddl > 0`, or with AutoCommit off) call `dbd_st_finish` and
`dbd_st_destroy` for every statement on the connection's list. The Perl
handles are not marked (`DBIc_IMPSET` stays on), so they go on being handed
out, by `prepare_cached` among others. Afterwards `bind_param` answers false,
`execute` of a SELECT answers `0E0`, and `execute` of an INSERT or UPDATE
answers `undef` (no error) **and writes nothing**. `RaiseError` does not fire. Only
`INSERT ... RETURNING` dies (`invalid statement handle`).

Expected: the handle is marked unusable and `execute` dies, or the statement is
prepared again, or the statements are not destroyed while the application
holds them.

## 2. `dbd_st_destroy` unlinks unconditionally, and runs twice

Perl calls `dbd_st_destroy` for the handle that case 1 has already destroyed,
once more, when the handle is freed. For a statement that is no longer on the
list (`prev_sth = next_sth = NULL`) the unlink sets `first_sth = last_sth =
NULL`, i.e. empties the list, whatever else is on it.

```perl
my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1, AutoCommit => 1 });
$dbh->do('CREATE TABLE t (id INTEGER)');
my $first = $dbh->prepare('SELECT id FROM t');
$dbh->do('CREATE TABLE o (id INTEGER)');        # destroys $first
my $held = $dbh->prepare('SELECT id FROM t');   # alive, on the list
$held->execute;
undef $first;                                    # second destroy: list emptied
$dbh->do('ALTER TABLE o ADD x INTEGER');         # DDL commit: $held is not on
                                                 # the list, not destroyed
$dbh->do('DROP TABLE t');
# dies:  object TABLE "T" is in use
```

Without `undef $first` the last statement succeeds. Same effect for anyone who
holds a cursor over DDL or a rollback and frees it afterwards, and for
`disable_sth_caching` users.

## 3. A DDL commit the server refuses leaves the handle failing for good

Continuing the case above (the DROP TABLE refused at commit):

```perl
$dbh->do('select 1 from rdb$database');   # dies:  object TABLE "T" is in use
$dbh->rollback;                           # warns "rollback ineffective with
                                          # AutoCommit enabled", does nothing
$dbh->do('select 1 from rdb$database');   # dies again, the same error
```

The failed commit is not rolled back, the next statement retries the commit and
fails the same way, indefinitely. What clears it (measured):
`$dbh->begin_work; $dbh->rollback;`. `$dbh->commit` and
`ib_set_tx_param` do not.

A caller that pings with a `select` therefore concludes that the connection is
dead. (DBIO's `dbh_do` did: it reconnected and ran the DROP again on the new
connection, reporting success for the statement the server had refused --
karr k49.)

Expected: a refused commit is rolled back by the DBD, so the handle is usable
afterwards, or the error is raised once and the transaction is closed.

## Workaround in DBIO::Firebird

`Storage::InterBase::_prepare_sth` asks a cached handle whether it is alive
(`bind_param` one past the last placeholder) and empties the cache when it is
not (ADR 0011); `Storage::InterBase::_ping` clears a refused commit with
`begin_work` + `rollback` when AutoCommit is on (t/32).
