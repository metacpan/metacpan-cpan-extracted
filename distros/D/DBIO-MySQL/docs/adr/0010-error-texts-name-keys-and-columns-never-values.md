# ADR 0010 — Error texts name keys and columns, never values

- Status: accepted (maintainer's rule of 2026-11-02, core ADR 0075 and its addendum; the shape of the rules is the coordinator's)
- Date: 2026-11-02
- Tags: storage, exceptions, bind-values, mariadb, future_io

## Context

MySQL and MariaDB write the offending value into their own error text, also
when the value arrived as a bind: `Incorrect integer value: 'x' for column 'i'
at row 1`, `Duplicate entry 'x' for key 'tab.PRIMARY'`, `Truncated incorrect
DOUBLE value: 'x'`. Both DBDs (DBD::mysql 4.055, DBD::MariaDB 1.24) also put
the bound values into the SQL on the client side, so the `near '...'` excerpt
of a syntax error holds them. Core ADR 0075 (addendum, decision 7–8) masks
bound values of four characters or more in every engine text and gives the
driver the hook `_mask_error_values($text, \@values, $statement)` for the forms
its engine writes. A short value (`7`, `'ab'`) is not found by that net.

## Decision

1. **`DBIO::MySQL::Util::mask_error_details($text, \@binds, $statement)`**
   holds the form rules. It replaces the value in the sentences that quote
   one (`Incorrect ... value`, `Duplicate entry`, `Truncated incorrect ...
   value`, `Incorrect string value`, unknown time zone / character set /
   collation, ...) with `***`, and every quoted literal in the `near '...'`
   excerpt of a syntax error. The type, the column, the table, the key name,
   the code and the position stay. A key of several columns is written
   `'a-b'` without a readable column split, so its whole value text is `***`.
   A text without a known form is returned as it is.
2. **`DBIO::MySQL::Storage` overrides `_mask_error_values`**: the form rules,
   then `next::method`. It serves both DBDs (`::Storage::MariaDB` inherits it).
3. **`DBIO::MySQL::Storage::Async` has the same method** and every path on
   which the DBD's text becomes an exception or a failed Future passes it:
   the async connections are DBI handles of their own with `RaiseError`, and
   the class is no `DBIO::Storage::DBI`, so core's handler never sees them.
4. **Statement text is not masked.** A literal the developer wrote into the
   SQL, an identifier, or a default value in DDL stays: that is ADR 0075
   decision 4, and the excerpt rule is the one deliberate exception, because
   there the engine shows the statement with the binds already inside it.
5. **`$dbh->errstr` stays raw**, as a DBI attribute.

## Rationale

The excerpt of a syntax error cannot tell a bind from a literal of the
statement, so every quoted literal in it goes: the statement's own text is
appended by core in placeholder form anyway. Where the rules are unsure the
text is masked more, not less.

## Consequences

- An error of this driver still names type, column and constraint; the value
  is in the caller's hands when it is needed.
- A syntax error excerpt also loses the bare numbers of typed binds
  (`where i = ***`, and a `LIMIT 10` with them).
- A sentence of the engine that is not known quotes its value until a rule is
  added; the core net still catches values of four characters or more.
