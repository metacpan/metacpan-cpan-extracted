# ADR 0007 — SQLSTATE class 01 is not an exception

- Status: proposed
- Date: 2026-10-07
- Tags: storage, error-handling, dbd-db2, transactions

Implemented with karr k43; the choice among the three options below was made by
the coordinating agent on the measurements and is waiting for the maintainer's
confirmation. Until then this stays `proposed`.

## Context

Db2 answers a `DELETE` or `UPDATE` without a `WHERE` clause with a warning:
SQLSTATE `01504`, `SQL0513W The SQL statement will modify an entire table or
view`. The statement has run. At the CLI level that is `SQL_SUCCESS_WITH_INFO`,
not `SQL_ERROR`.

`DBD::DB2` reports it the way it reports an error. The DBI contract has `err`
set to `"0"` or `""` for a warning or an information message, and a true value
only for an error; `DBD::DB2` sets a true value in both cases. Measured against
Db2 12.1.5 with `DBD::DB2` 1.92 on a plain DBI handle, `RaiseError` off:

| Statement | Return value | `err` | `state` |
|---|---|---|---|
| `$dbh->do('DELETE FROM "t"')` | 3 | 513 | `01504` |
| `prepare` + `execute` of the same | 3, at `execute` | 513 | `01504` |
| `UPDATE "t" SET v='x'` (literal) | 3 | 513 | `01504` |
| `UPDATE "t" SET v=?` (bind value) | 3 | — | — |

The three rows are deleted or updated in every one of them. Tried and without
any warning: `MAX()`/`SUM()` over `NULL`, `CAST('abcdef' AS VARCHAR(3))` — so
`01504` is the only member of class `01` seen from this server so far.

`DBIO::Storage::DBI::_connect` forces `RaiseError` on and installs a
`HandleError` that throws `DBI Exception: ...`. With a true `err` DBI calls it,
and so:

- `$rs->delete` on an unrestricted resultset threw after deleting every row;
- inside `txn_do` the exception rolled the delete back, so the same call had
  two different outcomes depending on where it stood;
- `$rs->update({...})` without a condition went through, because DBIO binds the
  value, while `$rs->update({ v => \"'x'" })` threw;
- `DBIO::DB2::Deploy` and core's `DBIO::Deploy::Base::_execute_ddl` call
  `$dbh->do` on the raw handle and are exposed in the same way, as is any raw
  SQL through `dbh_do`.

The suite did not cover the case: `t/10-db2.t` only deletes with a condition.

## Decision

`DBIO::DB2::Storage` treats a DBI message of SQLSTATE class `01` as what the
class means — the statement completed — and does not let it become an
exception.

The seam is `_connect` in `lib/DBIO/DB2/Storage.pm`. After core's `_connect`
has made the handle and installed its handler, the override replaces that
handler with a wrapper: a message whose `state` begins with `01` is answered as
handled (the handler returns true, DBI raises nothing and the method returns
its value), every other message goes to core's handler unchanged. The wrapper
is blessed into the class core tells its own handler by
(`__DBIO__DBH__ERROR__HANDLER__`), so a handle that comes back through a
connection coderef is not refused as carrying a foreign `HandleError`. Core is
not changed and no `@ISA` is touched.

Three options were on the card:

1. **Class 01 is not an error, in the storage** (chosen). Fixes the cause —
   a warning reported as an error — on every connect path (DSN, connection
   coderef, `DBIO::AccessBroker`, reconnect) and for every statement, raw SQL
   on the handle included, without rewriting anything the user wrote.
2. **`WHERE 1=1` in `DBIO::DB2::SQLMaker`.** Measured: the server sends no
   warning for it. It reaches only statements the SQLMaker renders — not
   `_execute_ddl`, not `DBIO::DB2::Deploy`'s own `do` calls, not raw SQL
   through `dbh_do` — and it changes the SQL of every unrestricted delete and
   update to silence a message about one of them.
3. **A driver setting.** Measured: the CLI keywords `IgnoreWarnList="'01504'"`
   and `IgnoreWarnings=1` in the DSN suppress the warning. They exist only for
   a string DSN, which the storage would have to rewrite; a connection coderef
   and a handle supplied from outside never see them. `IgnoreWarnList` also
   names one state where the fault is in how the whole class is reported.

## Rationale

SQLSTATE is the one thing in the message that says whether the statement ran,
and it is the server's statement, not the DBD's: class `00` success, `01`
warning, `02` no data, everything else an error. `err` is exactly the field
`DBD::DB2` fills wrongly, so it cannot be the criterion; the return value
cannot be either (below). Deciding on the class rather than on `01504` follows
from that: the fault is that a warning is reported as an error, and listing
the states one at a time would repeat this card for the next one.

**A class 01 message beside an `undef` return value passes too.** `HandleError`
is called for every DBI method, and for several of them `undef` is a value:
`selectrow_array` and `fetchrow_array` return it for a `NULL` — which is the
shape of `01003`, "null values eliminated in set function". Throwing on
"class 01 and `undef`" would turn that row into an exception. Where DBIO
itself depends on a true value the check is already there and stays:
`_dbh_execute` in core throws when `execute` returns false, with the handle's
`errstr`. So no statement DBIO runs is taken as done on the state alone, and
no value is taken for a failure because it is `undef`. Both halves are pinned
in `t/55-sqlstate-warning.t`.

## Consequences

- **The warning is silent.** No exception, no `warn`, no `carp`. It is not
  discarded: `err`, `state` and `errstr` stay on the handle until its next
  call, and a caller who wants them reads them there (`dbh_do`). Printing it
  would be noise on every unrestricted delete; the POD of `_connect` says how
  to ask.
- **All of class 01, not only `01504`.** A truncation warning (`01004`) or any
  other `01xxx` no longer throws either. Before this ADR each of them was an
  exception on a statement that had completed; none was ever measured from
  this server apart from `01504`.
- **`unsafe` is exempt.** Core installs no handler under `unsafe => 1` and this
  storage adds none: there the error handling is the caller's. With
  `RaiseError` on, a `DELETE` without `WHERE` dies there as it does in plain
  DBI.
- **`txn_do` commits what ran.** A warned delete or update inside a
  transaction is committed with it; a real error after it still rolls
  everything back (`t/56-sqlstate-warning-live.t`).
- **The wrapper depends on two things in core**: that `_connect` is the one
  place a handle is made (`_populate_dbh` is its only caller for a storage's
  own handle), and the name of the handler's class. If core renames the class
  the wrapper is simply not installed and `t/55-sqlstate-warning.t` goes red.
- **Not covered:** a statement that Db2 reports with a non-`01` state although
  it calls the message a warning. Seen once: `CREATE INDEX` on a column
  sequence that already has an index answers `SQL0605W` with state `42S11` and
  an `undef` return value. That is an error by its class and still throws.
- Tests: `t/55-sqlstate-warning.t` (offline, on a `DBD::NullP` handle with
  `set_err` standing in for the DBD) and `t/56-sqlstate-warning-live.t`.

## Future architecture work (tracked cross-repo, not here)

The cause is in `DBD::DB2`: `SQL_SUCCESS_WITH_INFO` should leave `err` at
`"0"`, as the DBI contract has it for a warning. Fixed there, DBI would not
call `HandleError` for a class 01 message at all and this wrapper would be
dead code, harmless and removable. No ticket is filed for it from here.
