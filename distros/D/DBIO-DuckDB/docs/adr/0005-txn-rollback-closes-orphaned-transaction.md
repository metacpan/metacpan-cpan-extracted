# ADR 0005 — txn_do rollback closes the orphaned DuckDB transaction itself

- Status: accepted
- Date: 2026-08-16

## Context

DBD::DuckDB 0.16 (the current CPAN release) implements `rollback` as:

    $dbh->do('ROLLBACK');
    $dbh->do('BEGIN TRANSACTION');

which is correct for `AutoCommit=0`. DBI then restores `AutoCommit=1`, but
the `STORE` branch that would COMMIT the reopened transaction is
unreachable code:

    my $never_set = !$old_value;
    if (!$old_value && $value && $never_set) { }         # always wins
    elsif (!$old_value && $value) { $dbh->do('COMMIT') } # dead code

`$never_set` is by definition `!$old_value`, so both conditions are
identical and the `0 -> 1` AutoCommit transition is a silent no-op.

Consequence: after any `$storage->txn_do { ... }` that rolls back, DuckDB
is still inside a transaction that DBI believes is closed. The next
`txn_begin` dies with "cannot start a transaction within a transaction" or
"Current transaction is aborted (please ROLLBACK)". On a `:memory:` DSN --
DuckDB's headline mode -- the poisoned handle is silently replaced by a
connection to a brand-new, EMPTY database, because
`DBIO::Storage::DBI::_exec_txn_begin` deliberately retries `begin_work` on
reconnect. The deployed schema is simply gone, with nothing raised.

This is the reason karr k13 declared `transactional_ddl` as 0: the engine
has transactional DDL, but the DBI driver underneath could not end such a
transaction.

## Decision

Override `_exec_txn_rollback` in `DBIO::DuckDB::Storage` to close the
orphaned transaction after the driver's rollback:

    sub _exec_txn_rollback {
      my $self = shift;
      $self->next::method(@_);
      try {
        $self->_dbh->do('ROLLBACK');
      }
      catch {
        die $_ unless $_ =~ /no transaction is active/i;
      };
    }

The extra `ROLLBACK` closes the transaction DBD::DuckDB reopened. The
"no transaction is active" error is swallowed because it is the expected
outcome once DBD::DuckDB's `STORE` branch is fixed upstream -- the
override must not break the normal rollback path.

The upstream fix (one line: remove the `$never_set` guard) was reported as
giterlizzi/perl-DBD-DuckDB#54 on 2026-08-16; this override covers the gap
for our users until that is released.

With the orphan closed, the engine argument for `transactional_ddl => 1`
stands on its own feet, and the declaration in `DBIO::DuckDB::Storage` is
revised to 1 (karr k15).

## Consequences

- A `txn_do` that rolls back leaves the connection usable: the next
  `txn_begin` works, and on `:memory:` the database is not silently
  replaced by an empty one.
- The deploy loop is bracketed in a transaction (`transactional_ddl => 1`):
  a failed apply rolls back whole AND the connection survives, so core's
  documented recovery -- re-running the upgrade -- works.
- The override is a no-op in behaviour once DBD::DuckDB is fixed upstream
  (the extra `ROLLBACK` finds no transaction and is swallowed).
