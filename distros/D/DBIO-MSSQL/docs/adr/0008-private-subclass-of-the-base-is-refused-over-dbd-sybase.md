# ADR 0008 — A private subclass of the transport-neutral base is refused over DBD::Sybase

- Status: accepted
- Date: 2026-10-17
- Tags: storage, access-path, sybase, transactions, adr-0059, adr-0007, karr-k42, karr-k43

## Context

[ADR 0007](0007-dedicated-odbc-storage-class-over-transport-neutral-base.md)
made `DBIO::MSSQL::Storage` transport-neutral. It fits neither DBD that reaches
SQL Server as it stands. A schema declares this driver with the `MSSQL`
component or `-ms`, both pin the base, and `_adapt_to_access_path` (core ADR
0059, karr k37) moves the declared base into `DBIO::MSSQL::Storage::ODBC` or
`DBIO::MSSQL::Storage::Sybase`. Core ADR 0059 lets only the declared class move:
a private subclass pinned through `storage_type` stays what it is, and core
reports a DBD that is not its own as a driver mismatch -- a warning, an error
only with `driver_strict` (ADR 0059 c/d).

Over DBD::Sybase that leaves a base class running without what the Sybase class
does for the DBD. Measured live (karr k41, k42, k43, k40, k50, k56; SQL Server
2022, DBD::Sybase 1.27 / FreeTDS 1.3.17):

- a transaction in which no statement ran can be neither committed nor rolled
  back (Msg 3902 / 3903);
- with an open cursor COMMIT and ROLLBACK are refused by the client library
  (results pending) and reach nobody, and `txn_do` takes the connection for
  lost and runs its body a second time on a new one;
- a bind value over 4000 bytes is cut by the server without an error;
- binary values arrive as text and are read as hex digits or not at all.

No single one of these is fixable in the base without putting DBD::Sybase
knowledge into it (the transaction statements would contradict ADR 0007), and
the Sybase class already has all of it. Nobody uses the pin yet: the driver is
at its first version.

## Decision

**Option A of karr k42.** `DBIO::MSSQL::Storage::_adapt_to_access_path($dbd)`
throws when `$dbd` is `Sybase` and the storage class is a private subclass of
the base -- neither the declared base itself, nor derived from
`DBIO::MSSQL::Storage::Sybase`, nor a layer class core composed over the
declared base (for those core's declared class is the base, and the hook
moves them as before).

- The message names the class, `DBIO::MSSQL::Storage::Sybase` as the class to
  derive from, and DBD::ODBC as the other way, and carries nothing of the
  connect info.
- It throws whatever `driver_strict` and `driver_warnings` say, and before the
  check for DBIO::Sybase (installing it would not help this class).
- Over DBD::ODBC nothing changes: the base on a pin is not measured as
  defective there, core's mismatch warning stands.
- No `@ISA` change. Not option B (composing the access-path class under the
  private subclass: reverses "only the declared base moves" and rebuilds
  `@ISA`), not C (leaving the warning: the measured defects are silent data
  loss and a doubled transaction body), not D (transaction statements in the
  base: contradicts ADR 0007).

## Departure from core ADR 0059

(c)/(d) of ADR 0059 make a driver mismatch a warning that `driver_strict` turns
into an error. Here the mismatch of one pairing -- a private base subclass over
DBD::Sybase -- is an error for every schema. This is the driver saying that
the pairing is defective, not that it merely belongs to another driver. The
rest of ADR 0059 (the hook, the one rule that the storage stays an instance of
the declared class, layers) is unchanged.

## Consequences

- k42 and the pin part of k43 end here. Part 1 of k43 (what `txn_begin`,
  `txn_commit`, `txn_rollback` do with an open statement handle) belongs to
  dbio-sybase (k65); the TODO tests in t/61 are its.
- `t/62-adapt-access-path.t` pins the refusal, the unchanged ODBC pin, the
  accepted `::Sybase` derivation and the declared base. The offline blocks of
  t/64 and t/66 that described the pin as "not covered" now assert the refusal.
- Whoever needs the base on DBD::Sybase for a reason of their own has no
  supported way; deriving from `DBIO::MSSQL::Storage::Sybase` is it.
