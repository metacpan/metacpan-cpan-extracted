# ADR 0008 — Index declarations are read canonically; what DuckDB cannot do is refused

- Status: accepted
- Date: 2026-10-14

## Context

Core (ADR 0061, karr k333) made the index declaration canonical on the
result source: `DBIO::Cake` `idx` / `indices` call `add_index_declaration`,
and a driver reads it with `index_declarations_for($driver, \@allowed)`.
`DBIO::DuckDB::DDL` read only the hand-written `duckdb_indexes`, so a Cake
class got no `CREATE INDEX` -- and because the desired model of a diff is
the introspection of a throwaway database built from `install_ddl`, no
index in the diff either (karr k41).

Measured against libduckdb 1.5.3: `CREATE INDEX ... WHERE` fails ("Creating
partial indexes is not supported"); `USING art` is a parser error; `a DESC`
parses but is silently dropped from the stored index; `WITH (...)` is
accepted and dropped; `(lower(b))` works, but `Introspect::Indexes` reads
the columns of an expression index out of the first parentheses of the SQL
(`b`, not the expression).

## Decision

1. `install_ddl` reads `index_declarations_for('duckdb', [])` and merges
   it over `duckdb_indexes`; the canonical one wins on the same name.
2. The allowed key list of the own block is empty: `where`, `expression`
   and any other key throw (the core helper's message). `type` other than
   `unique` and any `options` throw too. Never a plainer index.
3. Expression indexes are refused until introspection round-trips them.

## Consequences

- Diff and deploy need no change: the desired model follows install_ddl.
- Lifting (3) needs `Introspect::Indexes` to carry the expression.

## Addendum 2026-10-14 — expression indexes lifted (karr k44)

Decision 3 is withdrawn: the own block now allows `expression`
(`index_declarations_for('duckdb', [qw(expression)])`); core knows the key
since its `%IDX_DRIVER_KEYS` carries `duckdb => [qw(expression)]`.

Measured against libduckdb 1.5.3 (`duckdb_indexes()`): DuckDB wraps every
expression element in its own parentheses and normalises it (`lower(b)`
stays, `coalesce(...)` reads back `COALESCE(...)`). `CREATE INDEX i ON t
(a, lower(b))` is stored as `sql = CREATE INDEX i ON t(a, (lower(b)))`,
`expressions = [a, '(lower(b))']`; `UNIQUE` is `is_unique`. A plain column
stays bare (`"B c"` keeps its quotes). `expressions` is a string, so
`Introspect::Indexes` parses the `sql` instead: first parenthesised list,
split at top-level commas, quotes respected. An expression element stays in
`columns` as `(lower(b))`; a plain column is its unquoted name. Both sides
of a diff are introspected from DuckDB, so the normalised text compares
equal and a changed expression is a drop/create pair (`columns` differs).

`expression` is the whole list between the parentheses, as written, and
replaces `columns` (the sqlite driver's reading). `where`, every other key,
a type other than `unique` and `options` stay refused.
