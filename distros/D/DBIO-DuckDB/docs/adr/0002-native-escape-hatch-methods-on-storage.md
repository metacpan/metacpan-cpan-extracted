# ADR 0002 — DuckDB-native features are exposed as escape-hatch methods on Storage

- Status: accepted
- Date: 2026-06-20

## Context

DBIO inherits a row-oriented, DBI-shaped storage interface from
`DBIO::Storage::DBI`: prepare/execute, a row cursor, scalar bind. DuckDB is a
columnar, embedded analytical engine whose most valuable features do not fit
that shape:

- bulk loading via the native **Appender** API (orders of magnitude faster than
  row-by-row `INSERT`),
- columnar result transport (**Arrow** IPC buffers, bypassing the DBI row
  iterator and per-scalar coercion),
- file/table functions (`read_csv`, `read_parquet`, `read_json`),
- extension management (`INSTALL`/`LOAD`), `CHECKPOINT`,
- the **Quack** client-server RPC extension (`quack_serve`, `quack_attach`,
  `quack_detach`).

None of these are reachable through the portable ORM contract, and forcing them
through it would either be impossible (Appender, Arrow) or would mean smuggling
engine-specific SQL through `$rs->search`. Unlike `dbio-postgresql-async`, there
is no async-protocol reason to abandon DBI wholesale — DuckDB is embedded and
synchronous, so the DBI plumbing is kept for all ordinary ORM work
(transactions, bind, cursor, ResultSet) and only the columnar/server features
need an exit.

The async PostgreSQL driver set the family precedent of putting native-protocol
operations (`listen`/`notify`/`copy_in`) directly on its Storage object. This is
the first *blocking, DBI-based* DBIO driver to do the same, and it does so at a
larger surface.

## Decision

DuckDB-native features that do not fit the DBI/ORM model are exposed as
**direct methods on `DBIO::DuckDB::Storage`**, namespaced by feature family, and
documented as escape hatches — not routed through the portable ORM API.

1. The `duckdb_*` family wraps `DBD::DuckDB`'s `x_duckdb_*` entry points and
   raw DuckDB SQL: `duckdb_appender`, `duckdb_arrow_fetch`, `duckdb_read_csv`,
   `duckdb_read_parquet`, `duckdb_read_json`, `duckdb_version`,
   `duckdb_install_extension`, `duckdb_checkpoint`.
2. The `quack_*` family wraps the Quack RPC extension: `quack_serve`,
   `quack_attach`, `quack_detach`, plus the `connect_call_quack_attach`
   on-connect hook for `on_connect_call`.
3. Methods that interpolate caller-supplied values into SQL (extension names,
   quack addresses/tokens/aliases) **validate or escape every interpolated
   value** at the method boundary: identifier-shaped arguments are matched
   against `^[A-Za-z_][A-Za-z0-9_]*$`, string literals have `'` doubled, and
   addresses/tokens reject embedded quotes/newlines.
4. `duckdb_arrow_fetch` is explicitly marked **experimental**: it currently
   falls back to DBI row iteration and its return shape will change when the
   real libduckdb Arrow path lands. Callers are warned not to depend on the
   fallback shape in long-lived code.

## Consequences

- DuckDB power features are available without leaving the DBIO schema/Storage
  object — no second connection, no separate transport layer.
- The escape-hatch surface is engine-specific by construction. Code that calls
  `duckdb_*`/`quack_*` is not portable to another driver; that is the intended
  trade and is the reason these live as named methods rather than ORM sugar.
- Methods that bypass DBI also bypass DBI's placeholder binding, so input
  validation/escaping is a load-bearing security boundary in this driver, not a
  nicety. New escape hatches that build SQL strings must follow the same
  validate-or-escape discipline.
- `duckdb_arrow_fetch`'s contract is unstable until the Arrow path is
  implemented; that instability is documented at the method and acknowledged
  here so a future return-type change is not a surprise regression.

## Addendum 2026-10-09 — tokens: quotes doubled, newlines refused; the secret of `quack_attach`

Point 3 said addresses *and tokens* reject embedded quotes and newlines. The
code never did that for tokens: `_validate_quack_addr` refuses quotes and
newlines, `_validate_quack_token` refuses **newlines only**, and a `'` in a
token is **doubled** into its string literal in `quack_serve` and
`quack_attach`. The point reads, as built: addresses reject quotes and
newlines; tokens reject newlines and have quotes doubled.

Doubling is safe, measured in `t/62-quack-token-quotes.t`: a token such as
`it's "x"'); DROP TABLE hello; --` goes through `quack_serve` on one storage
and `quack_attach` on another, the attach authenticates against the server
with it, the server's table is still there, and a token that is only a prefix
of it is refused. (`duckdb_secrets()` will not show a secret unredacted by
default, so the stored value is shown through the server's authentication,
not by reading it back.) Refusing quotes would have rejected tokens that work.

Not covered by the decision above and noted here, not decided: since karr k32
`quack_attach` with a `token` creates a named, scoped secret
`dbio_quack_<alias>` (`SCOPE` the address) and runs the `CREATE OR REPLACE
SECRET` and the `ATTACH` in one `txn_do`, so a failed attach leaves the secret
store as it was; `quack_detach` drops that secret again. Whether this wants an
ADR of its own is the maintainer's call (karr k37).

## Addendum 2026-10-31 — `duckdb_arrow_fetch` reads through the Arrow interface

`duckdb_arrow_fetch` reads a result through libduckdb's Arrow interface and
answers it as columns, in the form below. This replaces point 4 and the last
Consequences bullet: the method is a stable escape hatch with that form.

The method (code in `DBIO::DuckDB::Arrow`) prepares and executes the
statement through DBD::DuckDB, takes the result and its logical types from
the handle, and calls libduckdb's current Arrow functions only
(`duckdb_result_get_arrow_options`, `duckdb_to_arrow_schema`,
`duckdb_fetch_chunk`, `duckdb_data_chunk_to_arrow`; not `duckdb_query_arrow*`
or `duckdb_execute_prepared_arrow`). `duckdb_to_arrow_schema` takes arrays,
which DBD::DuckDB::FFI binds as single pointers, so the module has an
FFI::Platypus instance of its own on the same library, found as DBD::DuckDB
finds it (`DUCKDB_NO_ALIEN` is honoured). The answer is

    { names => [...], formats => [...], columns => [ [...], ... ], rows => N }

by position, because a result may have two columns of one name. Each block is
decoded per buffer (one `unpack` per buffer and column), NULL is read from the
validity bitmap only where the block has NULLs, and the values equal those of
`selectall_arrayref` laid on their side, except that DATE, TIME, TIMESTAMP (every
unit) and INTERVAL are DuckDB's own text, what `CAST(v AS VARCHAR)` returns, and
TIMESTAMPTZ is UTC:

- The fraction of TIME and TIMESTAMP is padded to the precision of the type and
  loses its trailing zeros (`11:30:00.12`).
- Years up to 0 are `YYYY-MM-DD (BC)` with year `1 - y`; in a timestamp `(BC)`
  stands between date and time.
- An infinite DATE or TIMESTAMP (every unit, TIMESTAMPTZ too) is the text
  `infinity` or `-infinity`. DuckDB writes +infinity as the largest value of
  the storage type (INT32 for DATE, INT64 for the timestamps) and -infinity as
  the smallest plus one, checked against libduckdb 1.5.3.
- INTERVAL has sign and time part (`-1 day`, `1 day 03:00:00`).
- TIMESTAMPTZ is UTC (`+00`), whatever the session zone is: the one deliberate
  difference from the row path, which depends on the zone.

The row path of DBD::DuckDB 0.16 differs from DuckDB's text in the fraction,
BC years, INTERVAL (the time part is dropped) and infinity (the far dates
`5881580-07-11`, `294247-01-10 04:00:54.775807`, `-290308-12-21 19:59:05.224193`).

Nested text is decoded to characters. A type the decoder does not render
throws before the first row, naming column and format, never a value. UNION,
BIT, BIGNUM and TIME WITH TIME ZONE are found by DuckDB's type ids, because
BIT and BIGNUM reach Arrow as the BLOB format and TIME WITH TIME ZONE as the
TIME format; a format the decoder does not know (TIME_NS, for one) is refused
by the format, and so is a MAP whose key is a LIST, ARRAY, STRUCT or MAP (a
hash has text keys). The offset and the validity of the MAP's entry struct are
honoured like those of every other array. The Arrow array, the data chunk, the
schema, the options and the statement are released on every way out, so
nothing is left behind.

`DBIO::DuckDB::Arrow` is loaded by the method, inside its `try`, and not by the
storage class: the module binds libduckdb's Arrow functions when it loads, and
a storage class that loads whatever the library is stays loadable. A missing
library surfaces as the exception of `duckdb_arrow_fetch`. The decoder assumes
64-bit pointers (`Q` templates, 72 and 80 byte structs) and dies on load
otherwise.
