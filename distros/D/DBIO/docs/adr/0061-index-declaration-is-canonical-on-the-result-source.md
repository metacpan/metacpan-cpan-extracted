# ADR 0061 — The index declaration is canonical on the result source, and every driver reads it

- Status: accepted
- Date: 2026-10-10
- Tags: cake, candy, ddl, indexes, drivers, cross-driver, family-policy, builds-on-0060, relates-0052, relates-0059

## Context

A Result class declares secondary indexes in two ways: `DBIO::Cake::idx`
(`type`, `options`, and a `pg => { where, using, with, expression }` block) and
`DBIO::ResultSourceProxy->indices` (name and columns only). Both wrote the
declaration into one slot on the result source and passed it on into exactly one
driver namespace: the class method `pg_indexes`, installed by
`_install_index_hooks`. The other two native DDL emitters read a namespace of
their own and nothing else:

| driver | reads | form of an entry |
|---|---|---|
| dbio-postgresql (`DBIO::PostgreSQL::DDL`) | `pg_indexes` | `columns`, `unique`, `using`, `expression`, `opclasses`, `include`, `with`, `where` |
| dbio-sqlite (`DBIO::SQLite::DDL`) | `sqlite_indexes` | `columns`, `unique`, `expression`, `where` |
| dbio-mysql (`DBIO::MySQL::DDL`) | `mysql_indexes` | `columns`, `unique`, `using` (BTREE/HASH/FULLTEXT/SPATIAL) |

Measured 2026-10-08 (karr k333, k286): a Cake class with six `idx` and one
`indices` produces seven `CREATE INDEX` on PostgreSQL and **none** on SQLite and
MySQL — no error, no warning. The declaration was installed into a namespace
only one driver reads.

## Decision

Maintainer decision 2026-10-09 (karr k333): **core holds the index declaration
canonically, one namespace; every driver reads it; driver-specific blocks stay
possible as an override on the same entry.**

1. **Where.** The declaration lives on the `DBIO::ResultSource`. Two public
   methods:
   - `add_index_declaration(\%decl)` — the single writer.
   - `index_declarations` — the single reader; a list of entries in
     declaration order, as copies.
2. **Form of an entry.**

   ```perl
   {
     name    => 'name_city_idx',          # index name, required
     columns => ['name', 'city'],         # arrayref; a scalar is promoted
     unique  => 1,                        # 0|1; from `unique`, or type 'unique'
     type    => 'unique',                 # as declared (sqlt-era), or undef
     options => [ ... ],                  # as declared, or undef
     driver  => { pg => { where => '…' }, # one block per driver name
                  mysql => { using => 'FULLTEXT' } },
   }
   ```

   `name` and `columns` carry what all three drivers express. `driver` is the
   block a driver reads for what only it can say (`where`, `using`, `with`,
   `include`, `opclasses`, `expression`). Core does not enumerate the keys of
   a driver block; the driver validates its own.
3. **Who writes.** `Cake::idx` and `ResultSourceProxy->indices` call
   `add_index_declaration` and nothing else; they no longer touch a driver
   namespace. A declaration of the same name replaces the earlier one in its
   place, so one name is never emitted twice.
4. **Who reads.** A driver's DDL emitter (install DDL and the desired-model
   builder of the diff) calls `$source->index_declarations_for($driver, \@keys)` (point 7) and
   builds from `name`, `columns`, `unique` plus its own `driver->{<name>}`
   block. An index
   written by hand in the driver's own namespace (`pg_index`, `sqlite_index`,
   `mysql_index`) stays valid; if the same name is also declared canonically,
   the canonical declaration wins.
5. **Transition.** Ended 2026-10-10 (karr k333). dbio-postgresql reads
   `index_declarations` itself, so core no longer derives `pg_indexes` or an
   `sqlt_deploy_hook` from the declarations (`_install_index_hooks` is gone). A
   class gets no index method from `idx`/`indices`; an index written by hand in
   a driver namespace (`pg_index`) is untouched.
6. **One block per driver; the schema's driver reads its own.** A schema is
   bound to exactly one driver and an index declaration is driver-specific.
   `idx` takes `pg => {...}`, `sqlite => {...}` and `mysql => {...}` with one
   strictness: the block must be a hashref and its keys are checked when the
   class loads (pg: `where using with expression`; sqlite: `where expression`;
   mysql: `using`). Any other driver key is refused at declaration, and
   `add_index_declaration` accepts only the names of
   `ResultSource->index_declaration_drivers` -- that list is the one place.
   A class that has to serve two drivers is two schema classes sharing the
   source's columns.
7. **A foreign block is refused loudly.** Declaring does not know the driver,
   so the check is in the reader: `$source->index_declarations_for($driver,
   \@allowed_keys)` returns the entries for that driver and throws, naming
   source, index and driver, on an entry that carries only another driver's
   block, and on a key in the driver's own block that is not in
   `\@allowed_keys`. An empty own block means the plain index. Every driver's
   DDL emitter reads through it; `index_declarations` stays the unchecked
   reader.
8. **`options` and `type` on PostgreSQL.** `options`, and any `type` other
   than `unique`, are refused on PostgreSQL at DDL generation, at once and
   without a deprecation step. The refusal is dbio-postgresql's (karr
   dbio-postgresql k129); core only carries the values.
9. **What a driver does with what it cannot implement** (family line since
   ADR 0060): it implements it correctly or refuses loudly at DDL generation,
   naming the class, the index and the attribute. It never emits a plainer index
   and says nothing. A block under another driver's name is dealt with by
   point 7.

## Rationale

- *One namespace* is what the card asked for and what makes "declare once, deploy
  on every driver" true; a per-driver namespace filled by Cake would need Cake to
  know the driver, which ADR 0032/0059 keep out of the declaration.
- The declaration sits on the **source**, not in a class method, because that is
  where `idx` already wrote it, where `unique_constraints` live, and where the
  desired model of the diff is built from.
- Entries are copies because drivers adapt entries (default values, name
  generation); a shared mutable slot would leak one driver's adaptation into the
  next reader.
- `unique` rather than `is_unique`: the declaration side says `unique` in all
  three drivers; `is_unique`/`index_type` are the *introspected* canonical model
  (ADR 0052), a different structure. A driver maps `driver->{x}{using}` to
  `index_type` when it builds its desired model.

## Consequences

- A Cake or vanilla class with `idx`/`indices` gets its indexes on every driver
  once that driver reads `index_declarations_for`; core alone changes nothing
  for a driver that does not read it.
- dbio-postgresql, dbio-sqlite, dbio-mysql each need one small follow-up (named in
  karr k333); other drivers adopt the same reader when they have an index DDL.
- `$source->{_cake_indexes}` is gone; nothing outside core read it.
- Core's `index_declarations` test (`t/index_declarations.t`) holds the form, the
  order, the replace rule and a mock reader that builds `CREATE INDEX` from a
  Cake class without any driver namespace.

## Addendum 2026-10-14: the driver list grows to every driver with index DDL

`ResultSource->index_declaration_drivers` now also names `oracle`, `mssql`,
`sybase`, `firebird`, `clickhouse` and `duckdb`: each of them writes
`CREATE INDEX` and would otherwise ignore `idx`/`indices` silently. A name in the
list lets the driver call `index_declarations_for` and lets a declaration carry a
block for it; it does not make a driver read it -- each driver adopts the reader
in its own dist (core karr k333 follow-up). `db2` is not named: it has no live
database to prove the adoption against.
