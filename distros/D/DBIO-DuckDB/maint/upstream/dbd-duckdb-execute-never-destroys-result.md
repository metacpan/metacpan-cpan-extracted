# DRAFT — NOT SENT

> **Status: draft. This report has not been filed anywhere.** It is prepared
> for `giterlizzi/perl-DBD-DuckDB` and is sent, if at all, by the DBIO
> maintainer. Origin: dbio-duckdb karr k39. Measured 2026-10-17.
>
> It adds to the drafts in `docs/upstream/`
> (`dbd-duckdb-prepared-statements-never-freed.md`, karr k25, and
> `dbd-duckdb-statement-handles-cannot-be-reused.md`, karr k33). Those
> concern prepared *statements* and handle reuse; this one concerns the
> *result* object. See *Relation to the other reports* before sending.

---

## Title

`execute` never destroys a `duckdb_result` it replaces or abandons: a refused
`execute` leaks its error result, and a second `execute` on a handle leaks the
first result

## Summary

In DBD::DuckDB 0.16, `DBD::DuckDB::st::execute` allocates a
`DBD::DuckDB::FFI::Result` (a by-value `duckdb_result` record) and hands it to
`duckdb_execute_prepared`. `DBD::DuckDB::FFI::Result` has no destructor, and
`duckdb_destroy_result` is called from `finish` only. Two paths therefore
drop a live result without destroying it:

1. **A refused execute.** `duckdb_execute_prepared` returns `DUCKDB_ERROR`,
   `execute` calls `set_err` and returns. The error result — it owns the
   message that `duckdb_result_error` reads — is never freed.
2. **A second execute on the same handle.** `execute` stores the new result in
   `$sth->{duckdb_res}` and overwrites the previous one without destroying it.
   `finish` only ever destroys the last result.

Both were found by reading the source, then **measured**: memory that is
never given back grows linearly with the number of calls, in proportion to
the size of the error message or of the result. A normal
`execute` / fetch / `finish` cycle is not affected: `finish` does destroy the
current result (see the control row below).

Severity is low. There is no crash and no wrong result. It matters for a
long-running process that makes many refused executes (constraint
violations, say), or one that runs many `execute_for_fetch` rows through one
handle.

## Environment

| | |
|---|---|
| DBD::DuckDB | 0.16 |
| libduckdb | v1.5.3 (Alien::DuckDB 0.04, stock) |
| DBI | 1.651 |
| perl | 5.40.1, x86_64-linux-gnu-thread-multi |
| OS | Linux 6.12 (Debian 13) |

## Method

One child process per scenario. RSS is `VmRSS` from `/proc/self/status`, read
after 50 warm-up repetitions and again after N further repetitions. The N=0
run is the control: it shows that the read itself moves nothing. Each run is
capped (`systemd-run --user --scope -p MemoryMax=1G -p MemorySwapMax=0`
and `timeout 120`). Every repetition prepares a **fresh** handle: reuse of a
handle is its own set of defects (see the other drafts).

The prepared *statement* is leaked by DBD::DuckDB 0.16 as well (karr k25), and
that would swamp the signal. The script therefore destroys each statement
itself, through the same call the patch for k25 would make
(`duckdb_destroy_prepare(\$stmt)`), so that only results remain.

To make the signal visible the error message and the result are large
(about 200 kB each): a refused execute is `SELECT error(repeat('x',200000))`,
a result is `SELECT repeat('x',200000)`.

## Reproduction

No dependencies beyond DBI and DBD::DuckDB. Run each scenario in a fresh
process, e.g. `perl repro.pl reject 1000`.

```perl
#!/usr/bin/env perl
# repro.pl <scenario> <N>
#   reject | ok_small | ok_nofinish | ok_finish | overwrite | overwrite_finish
# With FIXED=1 the two-line fix below is applied at run time, so the
# difference can be measured without patching the installed module.
use strict;
use warnings;
use DBI;

BEGIN {
  if ($ENV{FIXED}) {
    require DBD::DuckDB;
    open my $fh, '<', $INC{'DBD/DuckDB.pm'} or die $!;
    my @l = <$fh>;
    my ($s) = grep { $l[$_] =~ /^\s+sub execute \{/ } 0 .. $#l;
    my ($e) = grep { $_ > $s && $l[$_] =~ /^\s+sub finish \{/ } 0 .. $#l;
    my $src = join '', @l[$s .. $e - 1];
    $src =~ s/return \$sth->set_err\(1, duckdb_result_error\(\$res\) \/\/ 'duckdb_execute_prepared failed'\);/my \$msg = duckdb_result_error(\$res) \/\/ 'duckdb_execute_prepared failed'; duckdb_destroy_result(\$res); return \$sth->set_err(1, \$msg);/
      or die 'fix 1 does not apply';
    $src =~ s/(# cache result for fetching\n)/$1        if (my \$old = delete \$sth->{duckdb_res}) { duckdb_destroy_result(\$old); }\n/
      or die 'fix 2 does not apply';
    eval "package DBD::DuckDB::st; no warnings 'redefine'; $src; 1" or die $@;
  }
}

my ($scenario, $n) = @ARGV;

sub rss {
  open my $f, '<', '/proc/self/status' or die $!;
  while (<$f>) { return $1 if /^VmRSS:\s+(\d+)/ }
}

my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '',
  { RaiseError => 0, PrintError => 0, AutoCommit => 1 });

# Destroy the statement ourselves (separate leak, karr k25): only results
# are measured.
sub rel {
  my $sth = shift;
  my $stmt = delete $sth->{duckdb_stmt};
  $sth->{duckdb_stmt} = undef;
  DBD::DuckDB::FFI::duckdb_destroy_prepare(\$stmt) if $stmt;
}

my $BIG = "SELECT repeat('x',200000)";
my $body = {
  # execute refused; error message ~200 kB
  reject      => sub { my $s = $dbh->prepare("SELECT error(repeat('x',200000))"); $s->execute; rel($s) },
  # control: successful execute, tiny result, no finish
  ok_small    => sub { my $s = $dbh->prepare('SELECT 1'); $s->execute; rel($s) },
  # successful execute, ~200 kB result, never finished
  ok_nofinish => sub { my $s = $dbh->prepare($BIG); $s->execute; rel($s) },
  # control: execute, then finish (finish destroys the result)
  ok_finish   => sub { my $s = $dbh->prepare($BIG); $s->execute; rel($s); $s->finish },
  # two executes on one handle, no finish
  overwrite   => sub { my $s = $dbh->prepare($BIG); $s->execute; $s->execute; rel($s) },
  # two executes on one handle, then finish
  overwrite_finish =>
    sub { my $s = $dbh->prepare($BIG); $s->execute; $s->execute; rel($s); $s->finish },
}->{$scenario} or die "unknown scenario $scenario";

$body->() for 1 .. 50;    # warm-up
my $before = rss();
$body->() for 1 .. $n;
my $after = rss();
printf "%-16s n=%5d rss_before=%7d kB rss_after=%7d kB delta=%7d kB per_op=%7.2f kB\n",
  $scenario, $n, $before, $after, $after - $before, ($after - $before) / ($n || 1);
```

A second variant of `reject` with an ordinary message (`SELECT error('boom')`,
N=20000) shows the size of the leak without the large message.

## Measurements

Stock DBD::DuckDB 0.16, N=1000 repetitions unless stated. The N=0 run of every
scenario moved RSS by 0 kB.

| Scenario | Leak per repetition, stock | with the fix below | Reading |
|---|---:|---:|---|
| `ok_small` (control: tiny result, no finish) | 34 kB | — | allocator and bookkeeping floor |
| `ok_finish` (control: execute, finish) | 16 kB | — | `finish` frees the result; the floor |
| `reject`, 200 kB error message | **415 kB** | 28 kB | refused execute leaks its error result |
| `reject`, ordinary message `'boom'`, N=20000 | 2.1 kB | 1.2 kB | about 1 kB per refused execute |
| `ok_nofinish`, 200 kB result | 301 kB | 298 kB | the last result is abandoned; expected, not fixed here |
| `overwrite`, two executes, no finish | **577 kB** | 286 kB | first result leaked (fix removes it); last one is the `ok_nofinish` case |
| `overwrite_finish`, two executes, then finish | **288 kB** | 4 kB | the overwritten first result is the whole leak |

Conclusion: the leak is real and proportional to what is dropped. About 2 kB
for a refused execute with a short message, about twice the message size for
a long one (the message is held more than once), and one full result per
overwrite. With the fix each of these returns to the floor of the controls.

## Cause

In `DBD::DuckDB::st::execute`:

```perl
my $res = DBD::DuckDB::FFI::Result->new;

if (duckdb_execute_prepared($duckdb_stmt, $res) == DUCKDB_ERROR) {
    return $sth->set_err(1, duckdb_result_error($res) // 'duckdb_execute_prepared failed');
    # $res is dropped here, never passed to duckdb_destroy_result
}
...
# cache result for fetching
$sth->{duckdb_res} = $res;       # replaces, and does not destroy, a previous result
```

`duckdb_destroy_result` runs in `finish` for `$sth->{duckdb_res}`, i.e. for the
last result only. The C API states that a result "must be freed with
`duckdb_destroy_result`" even when the query failed.

## Proposed fix

Destroy the error result after reading its message, and destroy the previous
result before it is replaced:

```diff
         my $res = DBD::DuckDB::FFI::Result->new;

         if (duckdb_execute_prepared($duckdb_stmt, $res) == DUCKDB_ERROR) {
-            return $sth->set_err(1, duckdb_result_error($res) // 'duckdb_execute_prepared failed');
+            my $msg = duckdb_result_error($res) // 'duckdb_execute_prepared failed';
+            duckdb_destroy_result($res);
+            return $sth->set_err(1, $msg);
         }
 ...
         # cache result for fetching
+        if (my $old = delete $sth->{duckdb_res}) {
+            duckdb_destroy_result($old);
+        }
         $sth->{duckdb_res}   = $res;
```

The message must be copied (`my $msg`) before the result is destroyed, because
the string belongs to the result.

The second destroy is best sent together with the fix of the handle-reuse
report (karr k33), which shows that a second `execute` on a handle keeps the
data chunk of the previous result. That chunk should be reset when the result
is replaced. The measurements above execute twice and finish, without
fetching in between, and did not crash with the destroy in place; a fetch
between the two executes was not measured. The first path (refused execute)
stands on its own.

## Relation to the other reports

* `docs/upstream/dbd-duckdb-prepared-statements-never-freed.md` (k25): the
  prepared *statement* is never freed. The measurements above destroy the
  statement themselves to keep the two apart; without that the statement leak
  (34 kB per repetition in the `ok_small` control) is added.
* `docs/upstream/dbd-duckdb-statement-handles-cannot-be-reused.md` (k33): its
  Defect 4 patches `finish` with `duckdb_destroy_result($res) if $res`. That
  guards the destroy in `finish`; it does not add the two destroys in
  `execute` proposed here, and leaves the leaks measured above open. The
  three patches touch different lines and can be sent together or one at a
  time.

## Impact on DBIO::DuckDB

None needed in the driver. A refused execute costs about 1 kB; with a long
message, a few hundred kB. The overwrite path is not reached by DBIO, which
takes one handle per execution (ADR 0007). The numbers are kept so that the
report can be filed if the maintainer wishes.
