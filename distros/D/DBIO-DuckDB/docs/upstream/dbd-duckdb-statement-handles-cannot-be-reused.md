# DRAFT — NOT SENT

> **Status: draft. This report has not been filed anywhere.** It is prepared
> for `giterlizzi/perl-DBD-DuckDB` and is sent, if at all, by the DBIO
> maintainer. Origin: dbio-duckdb karr k33. Measured 2026-10-07.
>
> It overlaps with the other draft in this directory,
> `dbd-duckdb-prepared-statements-never-freed.md` (karr k25): both end in a
> patch to `DBD::DuckDB::st::finish`, and the one below contains the other.
> See *Relation to the other report* before sending either.

---

## Title

A statement handle cannot be used a second time: `finish` destroys the
statement, `execute` never sets `Active`, and `execute` keeps the rows of the
previous result

## Summary

In DBD::DuckDB 0.16 a statement handle works for exactly one
`execute` / fetch-to-the-end cycle. Anything that uses a handle again —
`prepare_cached`, a loop over `execute`, an ORM — runs into one of four
defects in `DBD::DuckDB::st`. They are independent: each has its own cause
and none is fixed by fixing another.

1. **`finish` destroys the prepared statement.** A finished handle cannot be
   bound or executed again. DBI documents `finish` as ending the fetch, with
   the handle free to be "executed again"; `prepare_cached` is built on that.
2. **`execute` never sets `Active`.** DBI and its callers cannot tell a handle
   that is being read from one that is free. `prepare_cached` with
   `$if_active = 3` hands a handle out a second time while its first user is
   still fetching.
3. **`execute` keeps the data chunk of the previous result.** A handle that is
   executed again before its result was read to the end returns rows of the
   **old** result. No error, no warning.
4. **`finish` on a handle that has no result is a segmentation fault** — a
   second `finish`, or the `finish` that cleanup code issues after an
   `execute` the engine refused.

The third is the serious one: it returns wrong data silently, and it needs no
statement cache — one handle and two `execute` calls are enough.

## Environment

| | |
|---|---|
| DBD::DuckDB | 0.16 |
| libduckdb | v1.5.3 (Alien::DuckDB 0.04, stock) |
| FFI::Platypus | 2.12 (`api => 2`) |
| DBI | 1.651 |
| perl | 5.40.1, x86_64-linux-gnu-thread-multi |
| OS | Linux 6.12 (Debian 13) |

## Reproduction

No dependencies beyond DBI and DBD::DuckDB. Run each variant in a fresh
process: three of them end in a segmentation fault.

```perl
#!/usr/bin/env perl
# repro.pl <variant> -- plain DBI + DBD::DuckDB, no DBIO. One variant per
# process: some of them end in a segmentation fault.
#   cached | execute-after-finish | bind-after-finish | refinish
#   finish-failed | bulk | active | shared | stale | badprepare
use strict;
use warnings;
use DBI;
use Scalar::Util qw(refaddr);

$| = 1;

my $variant = shift // 'cached';
my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 });
$dbh->do('CREATE SEQUENCE s');
$dbh->do(q{CREATE TABLE t (id INTEGER DEFAULT nextval('s'), g INTEGER, name VARCHAR)});
$dbh->do(q{INSERT INTO t (g, name) VALUES (1,'x1'),(1,'x2'),(1,'x3'),(2,'y1'),(2,'y2'),(2,'y3')});

my $by_group = 'SELECT name FROM t WHERE g = ? ORDER BY id';

sub try_it {
  my ($what, $code) = @_;
  my @got = eval { $code->() };
  (my $err = $@) =~ s/ at \S+ line \d+\.?\n?\z//;
  printf "%-12s %-34s %s\n", $variant, $what,
    $err ? "DIED: $err" : join(' ', map { $_ // 'undef' } @got);
}

if ($variant eq 'cached') {
  # the prepare_cached pattern: same SQL, new values, finish in between
  for my $round (1 .. 3) {
    try_it "round $round" => sub {
      my $sth = $dbh->prepare_cached('INSERT INTO t (g, name) VALUES (?, ?) RETURNING id', {}, 3);
      $sth->bind_param(1, 9);
      $sth->bind_param(2, "n$round");
      $sth->execute;
      my ($id) = $sth->fetchrow_array;
      $sth->finish;
      "id=$id";
    };
  }
}
elsif ($variant eq 'execute-after-finish') {
  my $sth = $dbh->prepare('SELECT 42');
  try_it 'execute'              => sub { $sth->execute; $sth->fetchrow_array };
  try_it 'finish'               => sub { $sth->finish };
  try_it 'execute after finish' => sub { $sth->execute; $sth->fetchrow_array };
}
elsif ($variant eq 'bind-after-finish') {
  my $sth = $dbh->prepare($by_group);
  try_it 'execute'            => sub { $sth->execute(1); $sth->fetchrow_array };
  try_it 'finish'             => sub { $sth->finish };
  try_it 'bind after finish'  => sub { $sth->bind_param(1, 2) };
  try_it 'execute after that' => sub { $sth->execute; $sth->fetchrow_array };
}
elsif ($variant eq 'refinish') {
  my $sth = $dbh->prepare('SELECT 42');
  try_it 'execute'       => sub { $sth->execute; $sth->fetchrow_array };
  try_it 'finish'        => sub { $sth->finish };
  try_it 'finish again'  => sub { $sth->finish };
}
elsif ($variant eq 'bulk') {
  # what a bulk insert does: execute_for_fetch, then finish -- twice
  for my $round (1 .. 2) {
    my @rows = map { [ 9, "b$round$_" ] } 1 .. 2;
    try_it "round $round execute_for_fetch" => sub {
      my $sth = $dbh->prepare_cached('INSERT INTO t (g, name) VALUES (?, ?)', {}, 3);
      my $rv = eval { $sth->execute_for_fetch(sub { shift @rows }, []) };
      my $err = $@;
      print "bulk         round $round about to finish\n";
      $sth->finish;
      die $err if $err;
      "tuples=$rv";
    };
  }
}
elsif ($variant eq 'active') {
  my $sth = $dbh->prepare($by_group);
  try_it 'Active after prepare'       => sub { $sth->{Active} ? 1 : 0 };
  $sth->execute(1);
  try_it 'Active after execute'       => sub { $sth->{Active} ? 1 : 0 };
  $sth->fetchrow_arrayref;
  try_it 'Active after 1 of 3 rows'   => sub { $sth->{Active} ? 1 : 0 };
}
elsif ($variant eq 'shared') {
  # two readers of one SQL text; if_active = 3 asks DBI for a new handle
  # when the cached one is still being read
  my $one = $dbh->prepare_cached($by_group, {}, 3);
  $one->execute(1);
  my @one = ($one->fetchrow_array);
  my $two = $dbh->prepare_cached($by_group, {}, 3);
  try_it 'same handle handed out twice' => sub { refaddr($one) == refaddr($two) ? 'yes' : 'no' };
  $two->execute(2);
  my @two = ($two->fetchrow_array);
  for (1 .. 3) {
    push @one, ($one->fetchrow_array)[0] // '-';
    push @two, ($two->fetchrow_array)[0] // '-';
  }
  try_it 'reader one (want x1 x2 x3 -)' => sub { @one };
  try_it 'reader two (want y1 y2 y3 -)' => sub { @two };
}
elsif ($variant eq 'stale') {
  # no cache at all: one handle, executed again before it was read to the end
  my $sth = $dbh->prepare($by_group);
  $sth->execute(1);
  try_it 'g=1, first row (want x1)' => sub { $sth->fetchrow_array };
  $sth->execute(2);
  try_it 'g=2, first row (want y1)' => sub { $sth->fetchrow_array };
  $sth->execute(2);
  try_it 'g=2, first row (want y1)' => sub { $sth->fetchrow_array };
  $sth->execute(2);
  try_it 'g=2, all rows (want y1 y2 y3)' => sub { map { $_->[0] } @{ $sth->fetchall_arrayref } };
}
elsif ($variant eq 'finish-failed') {
  # finish after an execute the engine refused: what cleanup code does
  my $sth = $dbh->prepare('INSERT INTO t (id) VALUES (CAST(? AS INTEGER))');
  try_it 'execute'              => sub { $sth->execute('not a number') };
  try_it 'finish after failure' => sub { $sth->finish };
}
elsif ($variant eq 'badprepare') {
  # control for a DESTROY in the driver: a failing prepare still says why
  try_it 'prepare of bad SQL' => sub { $dbh->prepare('SELEKT 1'); 'no error' };
}
else {
  die "unknown variant $variant\n";
}

print "$variant END\n";
```

### Output, DBD::DuckDB 0.16

The process exit status is added after each variant; 139 is SIGSEGV. The
engine's multi-line error text is cut to its first line.

```
cached       round 1                            id=7
cached       round 2                            DIED: DBD::DuckDB::st bind_param failed: duckdb_bind_double failed at 1
cached       round 3                            DIED: DBD::DuckDB::st bind_param failed: duckdb_bind_double failed at 1
cached END
                                                                        exit 0
execute-after-finish execute                            42
execute-after-finish finish                             1
execute-after-finish execute after finish               DIED: DBD::DuckDB::st execute failed: duckdb_execute_prepared failed
execute-after-finish END
                                                                        exit 0
bind-after-finish execute                            x1
bind-after-finish finish                             1
bind-after-finish bind after finish                  DIED: DBD::DuckDB::st bind_param failed: duckdb_bind_double failed at 1
bind-after-finish execute after that                 DIED: DBD::DuckDB::st execute failed: duckdb_execute_prepared failed
bind-after-finish END
                                                                        exit 0
refinish     execute                            42
refinish     finish                             1
                                                                        exit 139
finish-failed execute                            DIED: DBD::DuckDB::st execute failed: Conversion Error: Could not convert string 'not a number' to INT32
                                                                        exit 139
bulk         round 1 about to finish
bulk         round 1 execute_for_fetch          tuples=2
bulk         round 2 about to finish
                                                                        exit 139
active       Active after prepare               0
active       Active after execute               0
active       Active after 1 of 3 rows           0
active END
                                                                        exit 0
shared       same handle handed out twice       yes
shared       reader one (want x1 x2 x3 -)       x1 x3 - -
shared       reader two (want y1 y2 y3 -)       x2 y1 - -
shared END
                                                                        exit 0
stale        g=1, first row (want x1)           x1
stale        g=2, first row (want y1)           x2
stale        g=2, first row (want y1)           x3
stale        g=2, all rows (want y1 y2 y3)      y1 y2 y3
stale END
                                                                        exit 0
badprepare   prepare of bad SQL                 DIED: DBD::DuckDB::db prepare failed: Parser Error: syntax error at or near "SELEKT"
badprepare END
                                                                        exit 0
```

## Defect 1 — `finish` destroys the prepared statement

Variants `cached`, `execute-after-finish`, `bind-after-finish`.

`lib/DBD/DuckDB.pm`, `DBD::DuckDB::st::finish`:

```perl
my $res  = delete $sth->{duckdb_res};
my $stmt = delete $sth->{duckdb_stmt};

duckdb_destroy_result($res);
duckdb_destroy_prepare($stmt);
```

After this the handle has no statement. `bind_param` hands libduckdb `undef`
and reports `duckdb_bind_... failed at 1`; `execute` reports
`duckdb_execute_prepared failed`. The handle is still in
`$dbh->{CachedKids}`, so `prepare_cached` keeps returning it: the first
round works, every later round of the same SQL fails.

DBI's contract for `finish` is "no more data will be fetched from this
statement handle before it is either executed again or destroyed". The
statement belongs to the handle and should go with it, in `DESTROY`.

**Fix:** `finish` releases the result only. The statement is destroyed in a
`DESTROY`.

(That the `duckdb_destroy_prepare($stmt)` call does not in fact free anything
— it passes the handle by value where a pointer is expected — is the subject
of the other report. For this defect only the `delete` matters.)

## Defect 2 — `execute` never sets `Active`

Variants `active`, `shared`.

`execute` stores the result and returns; `Active` is only ever written by
`fetchrow_arrayref`, which sets it to 0 at the end of the result. So it is 0
at every moment of a handle's life.

Callers rely on it. `prepare_cached($sql, \%attr, 3)` is documented to
replace a cached handle that is still active with a fresh one, so that two
readers of the same SQL text do not disturb each other; with `Active` stuck
at 0 both get the same handle, and the second `execute` pulls the result out
from under the first reader. Code of the form
`$sth->finish if $sth->{Active}` never calls `finish`.

**Fix:** set `Active` in `execute` when the statement produced a result set
(`duckdb_result_return_type` is `DUCKDB_RESULT_TYPE_QUERY_RESULT`), and clear
it wherever the result is released.

## Defect 3 — `execute` keeps the data chunk of the previous result

Variant `stale`. This one needs neither `prepare_cached` nor `finish`.

`fetchrow_arrayref` reads from `$sth->{duckdb_chunk}` at position
`$sth->{duckdb_chunk_row}` and fetches a new chunk only when
`duckdb_chunk` is undefined. It undefines it only after the last row of a
chunk. `execute` resets `duckdb_res`, `duckdb_rows` and `duckdb_index` — and
not the chunk:

```perl
$sth->{duckdb_res}   = $res;
$sth->{duckdb_cols}  = duckdb_column_count($res) || 0;
$sth->{duckdb_rows}  = duckdb_row_count($res)    || 0;
$sth->{duckdb_index} = 0;
```

So after one row of a three-row result, a new `execute` leaves the old chunk
at row 1 in place, and the next fetch returns the second row of the **old**
result. In the output above the query for `g = 2` answers `x2`, then `x3`,
both of which belong to `g = 1`; only once the old chunk is used up does the
handle return its own rows. The row count comes from the new result, so the
two can also disagree in length.

**Fix:** release the previous result — chunk, position, logical types,
result — at the start of `execute`.

Seen while reading the same lines, not measured: the chunk that
`fetchrow_arrayref` has finished is never destroyed. It is stored under
`duckdb_chunk`, and the cleanup reads `$sth->{chunk}`:

```perl
my $tmp = $sth->{chunk};
duckdb_destroy_data_chunk(\$tmp);
$sth->{duckdb_chunk} = undef;
```

## Defect 4 — `finish` on a handle without a result is a segmentation fault

Variants `refinish`, `finish-failed`, `bulk`.

`finish` calls `duckdb_destroy_result($res)` unconditionally. Without a
result `$res` is `undef`, which reaches C as `NULL`, and libduckdb does not
survive it. A handle has no result when it was never executed, when `finish`
already ran, or when its only `execute` failed — `execute` returns before it
stores one.

The last case is the one applications meet. Cleanup code calls `finish`
precisely when something went wrong:

```perl
my $ok = eval { $sth->execute(@values); 1 };
$sth->finish;                 # SIGSEGV if the execute was refused
die $@ unless $ok;
```

and so does a bulk insert that runs `execute_for_fetch` and then `finish`:
when every tuple is refused — or, on a cached handle, in the second round,
where defect 1 makes every `execute` fail — the `finish` afterwards crashes
the process. The process ends without a Perl error, and whatever output it
had buffered is lost.

Binding or executing a finished handle is **not** a crash; both return an
error (variants `bind-after-finish`, `execute-after-finish`).

**Fix:** `duckdb_destroy_result($res) if $res`.

## Proposed patch

Against 0.16. One helper releases whatever a result left behind; `execute`,
`finish` and a new `DESTROY` call it.

```diff
--- a/lib/DBD/DuckDB.pm
+++ b/lib/DBD/DuckDB.pm
@@ -348,6 +348,10 @@
 
         my $dbh = shift;
 
+        # Cached statement handles hold prepared statements, and a prepared
+        # statement keeps the database open.
+        %{$dbh->{CachedKids}} = () if $dbh->{CachedKids};
+
         my $conn = delete $dbh->{duckdb_conn};
         my $db   = delete $dbh->{duckdb_db};
 
@@ -875,6 +879,9 @@
 
         my $duckdb_stmt = $sth->{duckdb_stmt};
 
+        # A handle may be executed again: drop what the previous run left.
+        _release_result($sth);
+
         for my $i (0 .. $#bind) {
             my $rc = $sth->bind_param($i + 1, $bind[$i]);
             return $rc if !defined $rc;
@@ -916,27 +923,57 @@
             }
         }
 
+        $sth->STORE(Active => 1) if $res_type == DUCKDB_RESULT_TYPE_QUERY_RESULT;
+
         return '0E0';
 
     }
 
+    # finish ends the cursor. The prepared statement stays: DBI allows a
+    # finished handle to be executed again, and prepare_cached relies on it.
     sub finish {
 
         my $sth = shift;
 
-        my $res  = delete $sth->{duckdb_res};
+        _release_result($sth);
+
+        return 1;
+
+    }
+
+    sub DESTROY {
+
+        my $sth = shift;
+
+        _release_result($sth);
+
         my $stmt = delete $sth->{duckdb_stmt};
+        duckdb_destroy_prepare(\$stmt) if $stmt;
+
+    }
+
+    sub _release_result {
+
+        my $sth = shift;
 
-        duckdb_destroy_result($res);
-        duckdb_destroy_prepare($stmt);
+        if (my $chunk = delete $sth->{duckdb_chunk}) {
+            duckdb_destroy_data_chunk(\$chunk);
+        }
+
+        delete @$sth{qw(duckdb_chunk_row duckdb_chunk_size)};
 
-        foreach my $lt (@{$sth->{duckdb_col_logical_types}}) {
+        foreach my $lt (@{$sth->{duckdb_col_logical_types} || []}) {
             duckdb_destroy_logical_type(\$lt);
         }
 
         $sth->{duckdb_col_logical_types} = [];
 
-        return 1;
+        my $res = delete $sth->{duckdb_res};
+        duckdb_destroy_result($res) if $res;
+
+        $sth->STORE(Active => 0);
+
+        return;
 
     }
 
@@ -1574,7 +1611,7 @@
 
 
         if ($sth->{duckdb_chunk_row} >= $sth->{duckdb_chunk_size}) {
-            my $tmp = $sth->{chunk};
+            my $tmp = $sth->{duckdb_chunk};
             duckdb_destroy_data_chunk(\$tmp);
             $sth->{duckdb_chunk} = undef;
         }
```

What each part is for:

- **`_release_result` at the start of `execute`** — defect 3.
- **`STORE(Active => 1)` in `execute`, `STORE(Active => 0)` in
  `_release_result`** — defect 2. `Active` has to be cleared in `DESTROY`
  too, which is why it sits in the helper: with it only in `finish`, DBI
  warned `DBI st handle ... cleared whilst still active` for every handle
  that went out of scope unread.
- **`finish` no longer touches `duckdb_stmt`; `DESTROY` destroys it, by
  reference** — defect 1, and the leak of the other report.
- **`if $res`** — defect 4.
- **`$sth->{duckdb_chunk}` in `fetchrow_arrayref`** — the chunk leak read in
  the source. Not measured as a leak; included because the line cannot do
  what it says.
- **Clearing `CachedKids` in `db::disconnect`** — follows from moving the
  statement into `DESTROY`. A cached handle lives until the cache is cleared
  or the `$dbh` is destroyed, and its statement with it. Measured without
  this hunk: after `prepare_cached` / `execute` / fetch / `finish`, the
  database file stayed locked from `$dbh->disconnect` until `undef $dbh`.
  With it, `disconnect` releases the file.

`DESTROY` calls the helper as a plain function, not `$sth->finish`. The
other report measured why: with a method call there, a failing `prepare`
returned `undef` with no error at all, because the handle created inside
`prepare` is destroyed on the way out. The `badprepare` variant is the
control, and it reports the parser error as before.

The patch was measured as a whole. Apart from the `CachedKids` hunk, its
parts were not applied one at a time.

### Output with the patch applied

```
cached       round 1                            id=7
cached       round 2                            id=8
cached       round 3                            id=9
cached END
                                                                        exit 0
execute-after-finish execute                            42
execute-after-finish finish                             1
execute-after-finish execute after finish               42
execute-after-finish END
                                                                        exit 0
bind-after-finish execute                            x1
bind-after-finish finish                             1
bind-after-finish bind after finish                  1
bind-after-finish execute after that                 y1
bind-after-finish END
                                                                        exit 0
refinish     execute                            42
refinish     finish                             1
refinish     finish again                       1
refinish END
                                                                        exit 0
finish-failed execute                            DIED: DBD::DuckDB::st execute failed: Conversion Error: Could not convert string 'not a number' to INT32
finish-failed finish after failure               1
finish-failed END
                                                                        exit 0
bulk         round 1 about to finish
bulk         round 1 execute_for_fetch          tuples=2
bulk         round 2 about to finish
bulk         round 2 execute_for_fetch          tuples=2
bulk END
                                                                        exit 0
active       Active after prepare               0
active       Active after execute               1
active       Active after 1 of 3 rows           1
active END
                                                                        exit 0
shared       same handle handed out twice       no
shared       reader one (want x1 x2 x3 -)       x1 x2 x3 -
shared       reader two (want y1 y2 y3 -)       y1 y2 y3 -
shared END
                                                                        exit 0
stale        g=1, first row (want x1)           x1
stale        g=2, first row (want y1)           y1
stale        g=2, first row (want y1)           y1
stale        g=2, all rows (want y1 y2 y3)      y1 y2 y3
stale END
                                                                        exit 0
badprepare   prepare of bad SQL                 DIED: DBD::DuckDB::db prepare failed: Parser Error: syntax error at or near "SELEKT"
badprepare END
                                                                        exit 0
```

No warnings in any variant.

Against the patched module, DBIO::DuckDB with its statement cache switched
back on passes every one of its statement-reuse tests
(`t/49-statement-reuse.t`: repeated insert with `RETURNING`, repeated lookups,
bulk insert twice, abandoned cursors, two cursors read in turn), which all
fail or crash against 0.16. Your own test suite was not run against it — we
have no checkout.

## Relation to the other report

`dbd-duckdb-prepared-statements-never-freed.md` reports that no prepared
statement is ever destroyed and the database file therefore stays locked
after `disconnect`. Its patch makes `finish` destroy the statement
*effectively* (`\$stmt`) and adds a `DESTROY` that calls `finish`. It left
"should `finish` destroy the statement at all?" as a separate question.

This report answers that question — no — and its patch **replaces** the other
one instead of adding to it: the statement is destroyed in `DESTROY` only.
Applying the other patch alone would turn defect 1 from an accident (the
`delete`) into the design.

The patch above also fixes the lock. Run against it, the reproduction script
of the other report gives, after `disconnect`:

```
noquery  after disconnect  /proc/locks: none                 second process: opens the file
do       after disconnect  /proc/locks: none                 second process: opens the file
finish   after disconnect  /proc/locks: none                 second process: opens the file
nofinish after disconnect  /proc/locks: none                 second process: opens the file
prepare  after disconnect  /proc/locks: none                 second process: opens the file
```

and for a handle from `prepare_cached` that was executed, read and finished:

```
cached   after disconnect  /proc/locks: none                 second process: opens the file
```
