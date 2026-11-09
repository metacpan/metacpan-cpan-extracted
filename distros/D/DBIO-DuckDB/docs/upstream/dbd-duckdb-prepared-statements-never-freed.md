# DRAFT — NOT SENT

> **Status: draft. This report has not been filed anywhere.** It is prepared
> for `giterlizzi/perl-DBD-DuckDB` and is sent, if at all, by the DBIO
> maintainer. Origin: dbio-duckdb karr k25. Measured 2026-10-04.

---

## Title

Prepared statements are never freed: the database file stays locked after
`$dbh->disconnect` until the process exits

## Summary

In DBD::DuckDB 0.16 no prepared statement is ever destroyed. A leaked
statement keeps the DuckDB database instance alive, so `duckdb_close()` in
`disconnect` does not drop the last reference, and the exclusive lock on the
database file survives `disconnect` — and `undef $dbh` — for the rest of the
process. No other process can open the file in the meantime, read-only
included.

A handle that has prepared anything is enough: one `$dbh->do(...)`.

There are two independent causes, and fixing only the first leaves the most
common path (`do`) broken:

1. `st::finish` passes the statement **by value** to a function that takes a
   **pointer** to it. The call is a silent no-op.
2. `DBD::DuckDB::st` has no `DESTROY`, and nothing else calls `finish` for a
   handle the application did not finish itself.

## Environment

| | |
|---|---|
| DBD::DuckDB | 0.16 |
| libduckdb | v1.5.3 (Alien::DuckDB 0.04, stock) |
| FFI::Platypus | 2.11 (`api => 2`) |
| DBI | 1.651 |
| perl | 5.40.1, x86_64-linux-gnu-thread-multi |
| OS | Linux 6.12 (Debian 13); same result on tmpfs and ext4 |

## Reproduction

No dependencies beyond DBI and DBD::DuckDB. Run each variant in a fresh
process.

```perl
#!/usr/bin/env perl
# repro.pl <variant> -- run each variant in a fresh process:
#   noquery | do | finish | nofinish | prepare
use strict;
use warnings;
use DBI;
use File::Temp ();

my $variant = shift // 'do';
my $dir     = File::Temp->newdir;
my $file    = "$dir/repro.duckdb";

# Two probes. Neither opens the database file in THIS process: an advisory
# lock does not stop open(), and close() on any descriptor of a file drops
# the process's own POSIX locks on it.
sub report {
  my ($when) = @_;

  my $inode = (stat $file)[1];
  my $held  = 'n/a';
  if (open my $fh, '<', '/proc/locks') {    # Linux
    my ($mine) = grep { (split)[4] == $$ and /:$inode\s/ } <$fh>;
    $held = $mine ? join(' ', (split ' ', $mine)[1 .. 3]) : 'none';
  }

  my $rc = system $^X, '-MDBI', '-e',
    q{exit(DBI->connect("dbi:DuckDB:dbname=$ARGV[0]", "", "", { PrintError => 0 }) ? 0 : 1)},
    $file;

  printf "%-8s %-17s /proc/locks: %-20s second process: %s\n",
    $variant, $when, $held, $rc == 0 ? 'opens the file' : 'REFUSED';
}

my $dbh = DBI->connect("dbi:DuckDB:dbname=$file", '', '', { RaiseError => 1 });
report('after connect');

if ($variant eq 'do') {
  $dbh->do('CREATE TABLE t (i INTEGER)');
}
elsif ($variant eq 'finish') {
  my $sth = $dbh->prepare('SELECT 42');
  $sth->execute;
  1 while $sth->fetchrow_arrayref;
  $sth->finish;
  undef $sth;
}
elsif ($variant eq 'nofinish') {
  my $sth = $dbh->prepare('SELECT 42');
  $sth->execute;
  undef $sth;
}
elsif ($variant eq 'prepare') {
  my $sth = $dbh->prepare('SELECT 42');
  undef $sth;
}

$dbh->disconnect;
report('after disconnect');
undef $dbh;
report('after undef $dbh');
```

### Output, DBD::DuckDB 0.16

```
noquery  after connect     /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
noquery  after disconnect  /proc/locks: none                 second process: opens the file
noquery  after undef $dbh  /proc/locks: none                 second process: opens the file
do       after connect     /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
do       after disconnect  /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
do       after undef $dbh  /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
finish   after connect     /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
finish   after disconnect  /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
finish   after undef $dbh  /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
nofinish after connect     /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
nofinish after disconnect  /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
nofinish after undef $dbh  /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
prepare  after connect     /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
prepare  after disconnect  /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
prepare  after undef $dbh  /proc/locks: POSIX ADVISORY WRITE second process: REFUSED
```

`noquery` is the control: a connection that prepared nothing releases the
lock on `disconnect`, as it should. Every other variant keeps it. The refused
second process reports

```
IO Error: Could not set lock on file "...": Conflicting lock is held in
/usr/bin/perl (PID ...) by user ...
```

and it is refused with `access_mode => 'READ_ONLY'` as well.

### A note on how to observe this

An earlier attempt to reproduce this concluded "not reproducible" because it
probed with `open(my $fh, '>>', $file)` from the same process. That probe
cannot work: an advisory lock does not stop `open()`, so it always succeeds —
and `close()` on any descriptor of the file releases the process's own POSIX
locks on it (`fcntl(2)`), so the probe removes the lock it was meant to
detect. Measured: after such an `open`/`close` in the connected process,
`/proc/locks` shows no lock on the file while the connection is still open.
Only a second process, or `/proc/locks`, sees the real state.

## Measurements

One fresh process per cell; lock state **after `$dbh->disconnect`**. Both
probes (`/proc/locks` and a second process opening the file) agreed in every
cell, and the state after `undef $dbh` was the same as after `disconnect` in
every cell.

| what the handle did | calls `finish`? | 0.16 | only cause 1 fixed | patch below |
|---|---|---|---|---|
| nothing (`noquery`) | — | released | released | released |
| `$dbh->do(...)` | no | **held** | **held** | released |
| `prepare`, handle dropped | no | **held** | **held** | released |
| `prepare` / `execute` / fetch / `finish` | yes | **held** | released | released |
| `prepare` / `execute`, handle dropped | no | **held** | **held** | released |
| `prepare` / `execute` / fetch to end, handle dropped | no | **held** | **held** | released |
| `selectrow_array` | yes (DBI does) | **held** | released | released |
| `selectall_arrayref` | no | **held** | **held** | released |
| `prepare_cached` / `execute` / fetch / `finish` | yes | **held** | released | released |

"held" = `POSIX ADVISORY WRITE` in `/proc/locks` and the second process
refused; "released" = no lock line and the second process opens the file.

The middle column is what makes the second cause matter: with the by-value
call corrected and nothing else, `do`, `selectall_arrayref` and every handle
that is simply dropped still leak.

## Cause 1 — `duckdb_destroy_prepare` is called with a value

`lib/DBD/DuckDB.pm`, `DBD::DuckDB::st::finish`:

```perl
my $res  = delete $sth->{duckdb_res};
my $stmt = delete $sth->{duckdb_stmt};

duckdb_destroy_result($res);
duckdb_destroy_prepare($stmt);          # <-- by value
```

`lib/DBD/DuckDB/FFI.pm` declares the function, correctly, as taking a pointer
to the handle, and the handle type as `opaque`:

```perl
duckdb_destroy_prepare => [['duckdb_prepared_statement*'] => 'void'],
...
$ffi->type(opaque => 'duckdb_prepared_statement');
```

For an `opaque*` argument FFI::Platypus expects a scalar **reference**. Given
a plain value it passes `NULL` and says nothing. Shown with a libc function
that returns its argument, attached with the same parameter type:

```perl
$ffi->type(opaque => 'duckdb_prepared_statement');
$ffi->attach([llabs => 'see_ptr'] => ['duckdb_prepared_statement*'] => 'sint64');
```

```
FFI::Platypus 2.11, api 2
by value  see_ptr($stmt)   -> C receives 0x0
by value  see_ptr(undef)   -> C receives 0x0
by ref    see_ptr(\$stmt)  -> C receives 0x7ffcf02320a0 (address of an 8-byte slot holding 0x557bb8d68030)
by ref    see_ptr(\undef)  -> C receives 0x7ffcf02320a0 (address of a slot holding NULL)
warnings/exceptions raised: 0
```

libduckdb accepts the `NULL` without complaint and the statement stays
alive — nothing is destroyed. The other destroy calls in the same file already pass references —
`duckdb_disconnect(\$conn)`, `duckdb_close(\$db)`,
`duckdb_destroy_logical_type(\$lt)` — and `duckdb_destroy_result($res)` is
right as it stands, because `$res` is a record object, not an opaque handle.

## Cause 2 — no `DBD::DuckDB::st::DESTROY`

`finish` is the only place a statement would be released, and it runs only
when something calls it:

- DBI's default `do` (`prepare`, `execute`, `rows`) never calls `finish`.
- `execute` never sets `Active`, so the usual `$sth->finish if $sth->{Active}`
  in DBI itself and in callers never fires.
- A handle that goes out of scope, or that sits in `CachedKids`, is dropped
  without any cleanup because the class defines no `DESTROY`.

Counted in the measurements above: `finish` ran for 3 of the 8 variants that
prepare a statement.

## Proposed patch

```diff
--- a/lib/DBD/DuckDB.pm
+++ b/lib/DBD/DuckDB.pm
@@ -927,8 +927,8 @@
         my $res  = delete $sth->{duckdb_res};
         my $stmt = delete $sth->{duckdb_stmt};
 
-        duckdb_destroy_result($res);
-        duckdb_destroy_prepare($stmt);
+        duckdb_destroy_result($res)    if $res;
+        duckdb_destroy_prepare(\$stmt) if $stmt;
 
         foreach my $lt (@{$sth->{duckdb_col_logical_types}}) {
             duckdb_destroy_logical_type(\$lt);
@@ -940,6 +940,15 @@
 
     }
 
+    sub DESTROY {
+        my $sth = shift;
+
+        # Plain call, not $sth->finish: a method dispatched through DBI
+        # clears the error state the handle shares with its parent, which
+        # would swallow the error of a prepare() that has just failed.
+        finish($sth);
+    }
+
     sub _fetch_vector_value {
 
         my ($vector, $row_idx, $logical_type) = @_;
```

Three things in it, each measured:

- **`\$stmt`** — cause 1.
- **`DESTROY`** — cause 2. The call is deliberately `finish($sth)` and not
  `$sth->finish`. With `$sth->finish`, a failing `prepare` returns `undef`
  with **no error at all** — `$@` empty under `RaiseError`, `errstr` undef —
  because the handle created inside `prepare` is destroyed on the way out and
  the dispatched method resets the shared error state. With the plain call the
  error is reported as before
  (`DBD::DuckDB::db prepare failed: Parser Error: syntax error at or near ...`).
- **`if $res`** — needed once `DESTROY` exists, and a fix in its own right:
  `duckdb_destroy_result(undef)` passes `NULL`, and libduckdb crashes on it.
  On 0.16 this already happens without any patch (see below).

Output of the reproduction with the patch applied:

```
noquery  after disconnect  /proc/locks: none                 second process: opens the file
do       after disconnect  /proc/locks: none                 second process: opens the file
finish   after disconnect  /proc/locks: none                 second process: opens the file
nofinish after disconnect  /proc/locks: none                 second process: opens the file
prepare  after disconnect  /proc/locks: none                 second process: opens the file
```

The DBIO::DuckDB test suite passes against the patched module. Your own test
suite was not run against it — we have no checkout.

## Separate questions

These came up while measuring. They are not needed for the fix above; they
are listed so they do not get lost.

### 1. Should `finish` destroy the statement at all?

DBI documents `finish` as "no more data will be fetched from this statement
handle before it is either executed again or destroyed". In 0.16 `finish`
removes `duckdb_stmt` from the handle, so a handle cannot be executed again
after it. Measured on 0.16, `prepare` / `execute` / `finish` / `execute`:

```
DBD::DuckDB::st execute failed: duckdb_execute_prepared failed
```

That is the `prepare_cached` pattern. An alternative split would be: `finish`
destroys the result only, `DESTROY` destroys the result and the statement.
The patch above keeps the existing behaviour and only makes it effective.

### 2. `finish` on a handle with no result is a segmentation fault (0.16)

Both of these crash the process on 0.16 (exit by SIGSEGV), independently of
the lock issue:

```perl
my $sth = $dbh->prepare('SELECT 42');
$sth->finish;                      # never executed

$sth->execute; $sth->finish;
$sth->finish;                      # second finish
```

DBI allows both. The `if $res` guard in the patch fixes them; both survive
with the patch applied.

### 3. Data chunks are not destroyed — read in the source, not measured

`fetchrow_arrayref` ends a chunk with

```perl
my $tmp = $sth->{chunk};
duckdb_destroy_data_chunk(\$tmp);
$sth->{duckdb_chunk} = undef;
```

The chunk is stored under `duckdb_chunk`, so `$sth->{chunk}` is `undef` and
the chunk is not destroyed. This does not keep the file locked — the lock is
released with the patch above — so it looks like a memory leak only. We did
not measure it.
