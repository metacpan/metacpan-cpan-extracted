# ADR 0012 — The driver answers the shared DDL case table: sizes kept, bit / enum / dotted names refused, no second index

- Status: accepted (maintainer decision of 2026-10-19, karr k55)
- Date: 2026-10-19
- Tags: ddl, conformance, drivers, refusals, indexes, testing

## Context

Core ADR 0060 states 19 DDL cases once and has every driver answer them: right,
refused loudly, or a declared deviation. `DBIO::Firebird::Test::Conformance`
(`t/80-conformance-ddl*.t`) is this driver's half. The first live run, against
Firebird 5.0.4, found:

- `data_type => 'character'` lost its size (the bare keyword is `CHAR(1)`);
  the base type `double` was written `DOUBLE`, a syntax error.
- `bit` and `enum` reached the server as type names it does not have
  (`Specified domain or source column BIT does not exist`).
- A table `other.t` became a table literally named `other.t` in the one
  namespace Firebird has.
- A declared index over a unique constraint's or a foreign key's columns was
  built next to the index the server had made for that constraint.
- `CHAR(5) DEFAULT '007'` reads back `'007  '`.

## Decision

1. **Sizes are kept**, and type names arrive as Firebird spells them
   (`character`, `character varying`, `binary`, `varbinary`, `double`).
2. **`bit` is refused** by `install_ddl` with a `DBIO::Exception` naming table
   and column. Mapping it was considered and rejected: no Firebird type holds a
   bit string of a fixed width. `BOOLEAN` is one bit, `BINARY(n)` counts bytes,
   so any mapping changes what `size` means (`bit(8)` as `BINARY(1)` reads back
   with size 1). **`enum` is refused** the same way (no `VARCHAR` + `CHECK`).
3. **A table name with a dot is refused**: there are no schemas before
   Firebird 6. A literal name (`\'a.b'`) stays SQL as written.
4. **No second index**: a declared index over exactly the columns of the primary
   key or of a written unique constraint, or, when it is not unique, of a
   written foreign key, is not built. A unique index over foreign key columns
   is not a duplicate and is built.
5. **`CHAR(n)` padding is a declared deviation** (`ddl-default-digit-string`),
   as on PostgreSQL: the type's definition, the driver does not trim.
6. **The namespace of a case is the test database.** No schemas before 6, so a
   case refuses to run in a database that holds a table or view. Otherwise
   `conformance_namespace` returns the mark of the case -- the names of the
   tables and views its sources will create -- and `conformance_cleanup`
   removes those objects (their foreign keys, the views, the tables, where they
   exist) through a connection of its own, and nothing else. Core's runner calls
   the cleanup also when the namespace seam threw; without a mark the cleanup
   only disconnects, so a database that was refused is left as it was. It never
   drops "everything in the database" (t/85).
7. **Time zone types are refused**: the server has them (Firebird 4+), but
   DBD::Firebird 1.39 cannot bind a value to such a column and reads one back
   as `** unknown **` (t/88). `binary` and `varbinary` are refused on a server
   below Firebird 4; the version is the seam `DDL->server_major_version`.
8. **The guards of the boolean column ask for the mapped type**
   (`Type::is_boolean_type`), so the alias `bool` is guarded like `boolean`.
9. **A string without a size is text** (`BLOB SUB_TYPE TEXT`), `real` is
   `DOUBLE PRECISION`, a view name with a dot is refused, and `is_unique` beside
   a unique constraint of the same column builds one index.
10. **Every native connection reads ISO dates and timestamps** (`ib_time_all`
    set by the storage before the caller's connect actions): the conformance
    connect no longer asks for `datetime_setup`.

## Consequences

- A database installed before this change keeps the second index; the diff
  drops it.
- `ddl-view-declared` is answered as pending on core's card dbio#k349 (the
  runner is to quote the identifiers of a view definition). The refusal comes
  from the test class (`conformance_install`), not from the driver: a real
  deploy of that view gives the server's error, because `FROM base` is folded
  to `BASE` while the driver creates `"base"`.
- A column declared with a string without a size changes from `VARCHAR(255)`
  to text; it can no longer carry a key or an index.
- Code that read the locale-format timestamps changes with decision 10.

## Addendum 2026-10-22 (karr k56)

Core gained the hook `conformance_quote_ident` (dbio k349); its default quotes an
identifier with the quote character of the SQL maker, `"` for this driver, so the
view definition of `ddl-view-declared` names `"base"` the way the driver creates
it. The pending answer and the refusal in `conformance_install` are gone and the
case runs against the server like the others (measured on Firebird 5: all 19
cases pass, one deviation remains, `ddl-default-digit-string`). The decision
above is otherwise unchanged.
