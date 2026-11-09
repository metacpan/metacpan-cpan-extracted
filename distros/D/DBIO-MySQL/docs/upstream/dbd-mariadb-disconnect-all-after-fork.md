# DRAFT — NOT SENT. Sending needs the maintainer's go-ahead (karr k56)

Draft of a bug report for DBD::MariaDB
(tracker per its `META.json`: <https://github.com/perl5-dbi/DBD-MariaDB/issues>).
Nothing in here has been filed, mailed or posted anywhere.

## Before sending — what this draft rests on

Everything from "Report" downwards is the text for upstream. This section is
for us and is cut before sending.

| Statement in the report | Basis |
|---|---|
| Variants A, B, C against a server | Measured 2026-09-26 against MySQL 8.0.30 with DBD::MariaDB 1.24 and DBI 1.651 (karr k56). The script used then was not kept; the one below is a reconstruction. |
| The repro script as printed | **Not run against a server.** Run 2026-10-04 against a MySQL wire-protocol stub — a Perl socket that sends a v10 handshake, answers OK to every command and ends the session on `COM_QUIT`. It shows what the client writes to the shared socket; it is not a server. Outcomes: A alive, B dead, D dead, C either of the two outcomes described. Same script with `dbi:mysql:` (DBD::mysql 4.055): alive in all four. |
| Variant D against a server | Not measured in isolation. `t/63-future-io-listen-live.t` g) lost the parent's connections that way on 2026-09-26 (handles still referenced at the child's exit); the isolated case is stub and source only. |
| Variant C ending in a silent close instead of the panic | Stub only (2026-10-04). Against the server only the panic was seen. |
| "Cause" | Read from the sources of DBD::MariaDB 1.24, DBI 1.651 and MariaDB Connector/C 3.4.9, file and line given. The DBI trace excerpt is from the stub run. |
| Why the freed handle still reads as active | A guess, marked as one in the text. |
| "Suggested fix" | Not built, not tested. |

To do before sending: run the script against a real MySQL **and** a real MariaDB
server and replace the reconstruction note by the real output; record the client
library and Perl of that run (this machine on 2026-10-04: Perl 5.40.1, MariaDB
Connector/C 3.4.9 from Debian `libmariadb3` 11.8.6 — the card does not record
either for the 2026-09-26 run, the "Versions" line assumes the same machine);
look through the tracker for an existing report (a web search on
2026-10-04 found none, which is not a tracker search); decide whether B belongs
in the report at all (see "Expected").

## Workaround im Treiber (nicht Teil des Berichts)

Seit 2026-10-24 (ADR 0009, karr k56) umhuellt `DBIO::MySQL::MariaDBForkGuard`
`DBD::MariaDB::dr::disconnect_all` prozessweit: im Erzeugerprozess (der
installierende pid) laeuft das Original unveraendert, in jedem anderen ist der
Aufruf ein No-op. Damit sind B, C und D oben in einem Kind folgenlos (offline
gegen den Stub, `t/149`; live `t/63` g) auf MySQL 8.0.30 und MariaDB 11.8.8).
Nebenwirkung: auch eine Verbindung, die das Kind selbst oeffnet, schliesst
`disconnect_all` nicht mehr, DESTROY/`disconnect` schliessen sie weiterhin.
Der Bericht bleibt UNGESENDET; sobald DBD::MariaDB das Problem behebt, kann der
Wrap entfallen. Der Stub, an dem die Tabelle oben jetzt reproduzierbar ist:
`t/lib/MySQLProtocolStub.pm` (A lebt, B tot, C Panic/Exit 22, D tot ohne Guard;
die Reproduktion gegen einen echten Server steht weiter aus).

---

## Report

### `disconnect_all` closes connections a forked child inherited, and walks handles that were already destroyed

**Summary.** In a forked child, `DBD::MariaDB::dr::disconnect_all` — which DBI's
`END` block calls at every normal exit — runs `mysql_close()` on every
connection the child inherited from its parent, whatever `InactiveDestroy` /
`AutoInactiveDestroy` say. `mysql_close()` sends `COM_QUIT` on the socket both
processes share, so the server ends the parent's session. In addition, a handle
whose `DESTROY` was skipped because of `InactiveDestroy` stays on the driver's
list of active connections after it has been freed; `disconnect_all` then works
on freed memory, which shows as `panic: DBI active kids (-1) < 0 or > kids (0)`
or, depending on what the memory holds by then, as the same silent close.

DBD::mysql 4.055 is not affected: built without the embedded server it has no
`disconnect_all` at all, so DBI's `END` does nothing there.

**Versions.** DBD::MariaDB 1.24, DBI 1.651, MySQL server 8.0.30. Perl 5.40.1,
Linux x86_64.

**Reproduce.**

```perl
#!/usr/bin/perl
# A forked child and a DBD::MariaDB handle it inherited (AutoInactiveDestroy => 1).
#   DBI_DSN='dbi:MariaDB:database=test;host=127.0.0.1' DBI_USER=... DBI_PASS=... perl repro.pl
use strict;
use warnings;
use DBI;
use POSIX ();
$| = 1;

my ($dsn, $user, $pass) = @ENV{qw(DBI_DSN DBI_USER DBI_PASS)};
our $KEEP;    # variant D: a second reference that survives until END

my @variants = (
  [ 'A  undef $dbh; POSIX::_exit'          => sub { undef $_[0];         POSIX::_exit(0) } ],
  [ 'B  DBI->disconnect_all; POSIX::_exit' => sub { DBI->disconnect_all; POSIX::_exit(0) } ],
  [ 'C  exit, handle only in a lexical'    => sub { exit 0 } ],
  [ 'D  exit, handle also in a global'     => sub { $KEEP = $_[0]; exit 0 } ],
);

for my $variant (@variants) {
  my ($name, $in_child) = @$variant;
  my $dbh = DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1 });

  my $pid = fork // die "fork: $!";
  $in_child->($dbh) if !$pid;
  waitpid $pid, 0;

  my $alive = eval { $dbh->do('DO 1'); 1 };
  printf "%-38s child exit %-3d parent handle %s\n",
    $name, $? >> 8, $alive ? 'ALIVE' : 'DEAD: ' . $dbh->errstr;
}
```

> Note for the draft: this script is reconstructed from the measurement of
> 2026-09-26 and has not been run against a server again. See the table above.

**Observed.**

| | What the child does | Parent's handle afterwards |
|---|---|---|
| A | `undef $dbh; POSIX::_exit(0)` | alive |
| B | `DBI->disconnect_all; POSIX::_exit(0)` | dead: `Lost connection to server during query` |
| C | `exit 0`, the handle held only by a lexical | child prints `panic: DBI active kids (-1) < 0 or > kids (0) at .../DBI.pm line 763.` and `END failed--call queue aborted.`, exits with status 22; parent's handle alive. With a different heap layout the child exits 0 without a message and the parent's handle is dead, as in D. |
| D | `exit 0`, the handle still referenced when `END` runs | dead: `Lost connection to server during query`; child exits 0, no message |

With DBD::mysql 4.055 the parent's handle is alive in all four.

**Expected.** A child that inherited a handle opened with
`AutoInactiveDestroy => 1` does not end the parent's session by exiting (C, D).
That is what the attribute is documented for — DBI's own example is "Child
process dies, destroying the inherited dbh" — and it is what `DESTROY` already
does (A). Running into freed memory (C) is a defect whatever the answer to the
rest.

B is an explicit call. DBI documents that `InactiveDestroy` "does not disable
an explicit call to the disconnect method", and one may read `disconnect_all`
the same way; we would still expect it to leave alone connections the calling
process did not open, but C and D are the cases that hit programs which did
nothing explicit.

**Cause.** File and line refer to DBD-MariaDB-1.24, DBI-1.651 and MariaDB
Connector/C 3.4.9.

1. *`disconnect_all` closes everything it has listed.* DBI's `END`
   (`DBI.pm:536-543`) calls `DBI->disconnect_all`, which calls
   `$drh->disconnect_all` for every installed driver (`DBI.pm:760-765`; line 763
   is the one in the panic message). `mariadb_dr_discon_all`
   (`dbdimp.c:3286-3299`) empties `imp_drh->taken_pmysqls` and
   `imp_drh->active_imp_dbhs` by calling `mariadb_dr_close_mysql` /
   `mariadb_db_close_mysql` on every entry. Neither function looks at
   `DBIc_IADESTROY`, `DBIc_AIADESTROY` or the pid DBI stored for the handle;
   `mariadb_dr_close_mysql` calls `mysql_close()` (`dbdimp.c:3123`), which
   sends `COM_QUIT` (`mariadb_lib.c:2456-2463`, `mysql_close_slow_part`) before
   it closes its descriptor. The descriptor is the child's copy; the `COM_QUIT`
   goes down the connection both processes share. That is B and D.

2. *A handle destroyed under `InactiveDestroy` stays listed.* Every connected
   handle is put on `active_imp_dbhs` (`dbdimp.c:2464`) and taken off only in
   `mariadb_db_close_mysql` (`dbdimp.c:3180-3181`). For a handle with
   `AutoInactiveDestroy` in another process, DBI's dispatcher sets
   `InactiveDestroy` and clears the `Active` flag before the driver's `DESTROY`
   runs (`DBI.xs:3513-3519`), and `DESTROY` then skips the disconnect
   (`Driver.xst:401-405`). `mariadb_db_destroy` only disconnects a handle that
   is still active (`dbdimp.c:3368-3374`), so nothing removes the list entry.
   DBI then frees the handle; the entry's `data` keeps pointing at its
   `imp_dbh`. The connection is left open, as intended — that is A.

3. *`disconnect_all` then uses the freed `imp_dbh`.* On `exit`, Perl releases
   lexicals before it runs `END` blocks, so in C the handle is destroyed as in
   2. and DBI's `END` runs afterwards. `mariadb_dr_discon_all` passes the stale
   pointer to `mariadb_db_close_mysql`, whose first statement is
   `DBIc_ACTIVE_off(imp_dbh)` (`dbdimp.c:3178`). If the freed memory reads as
   "active", the macro decrements the driver handle's active-kids count, which
   is already 0, and croaks (`DBIXS.h:331-341`) — the message names `(-1)` and
   `kids (0)`, the counts of a driver handle whose only child is gone. The croak
   leaves the function before `mysql_close()`, which is why the parent survives
   in that case. If the memory does not read as "active", the function goes on
   to `imp_dbh->pmysql` and closes the connection as in 1. A DBI trace of the
   child shows the order:

   ```
   -> DESTROY for DBD::MariaDB::db (DBI::db=HASH(0x55f3d943e970)~INNER)
        DESTROY DBI::db=HASH(0x55f3d943e970) skipped due to InactiveDestroy
   <- DESTROY= ( ) [0 items] at trace_probe.pl line 6
   -- DBI::END ($@: , $!: )
   -> disconnect_all for DBD::MariaDB::dr (DBI::dr=HASH(0x55f3d94435d8)~0x55f3d9443518)
       mariadb_db_close_mysql: imp_dbh=55f3d9394000 pmysql=55f3d9475fa0
   ```

   Why the flag reads as set although DBI cleared it before freeing: our guess,
   not verified, is that `flags` is the first member of the handle's common
   structure (`DBIXS.h:87-88`), where the allocator keeps its own data in a
   freed block.

DBD::mysql 4.055 defines `dbd_discon_all` only for the embedded build
(`dbdimp.h:408-410`), so `DBD::mysql::dr` has no `disconnect_all`; DBI treats a
missing one as a no-op (`DBI.pm:436`, flag `0x0800` = `IMA_NOT_FOUND_OKAY`,
`DBI.xs:192`). Its handles are closed by `DESTROY` alone, which honours
`AutoInactiveDestroy`.

**Suggested fix.** Not built or tested by us.

- In `mariadb_dr_discon_all`, do not call `mysql_close()` on a connection that
  is not the calling process's to close: a handle with `InactiveDestroy` set,
  or with `AutoInactiveDestroy` and a stored pid different from the current
  one — the test DBI applies in `DBI.xs:3513-3516`. Such an entry would be
  dropped from the list and counted out of `imp_drh->instances` without
  talking to the server.
- In `mariadb_db_destroy`, remove `imp_dbh->list_entry` from `active_imp_dbhs`
  also when the handle is no longer active, so the list never points at a freed
  `imp_dbh`. `imp_drh->instances` needs the matching adjustment, or
  `disconnect_all` reports "database handlers were not released"
  (`dbdimp.c:3303-3306`).
- `taken_pmysqls` (connections taken with `take_imp_data`) has the same
  question in a child, and no pid to answer it with; from the source alone we
  cannot say how that should be decided.
