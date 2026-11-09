# ADR 0007 — A data-structure bridge to ClickHouse::Encoder, not a Native fast path in the storage
- Status: accepted
- Date: 2026-08-11
## Context
`ClickHouse::Encoder` (EGOR, XS) builds ClickHouse's columnar binary **Native**
format from Perl data: `new(columns => [[$name, $type], ...])` plus rows as
arrayrefs in column order, and helpers that ship the bytes (`insert_http`,
`bulk_inserter`, `stream`). It is the fastest way to get bulk rows into
ClickHouse from Perl, and it is much faster than parameterized `INSERT`s over
the MySQL wire.
The type string it wants is the syntax `describe table` emits — which is
exactly what `DBIO::ClickHouse::DDL`'s column-type renderer already produces,
`Nullable(...)` / `LowCardinality(...)` / `Enum8(...)` / `Decimal(P, S)`
wrapping included. So the distance between "a DBIO schema" and "a configured
encoder" was one public method, and the distance between "a DBIO resultset"
and "encoder rows" was a column-order permutation plus deflation. The question
was what to build out of that, and how much of it.
Three things constrain the answer.
**The transport is settled (ADR 0001).** This driver rides the MySQL wire
protocol on server port 9004, and that is deliberately its *only* channel.
`ClickHouse::Encoder`'s shippers use the HTTP interface (8123) or pipe into
`clickhouse-client`. A "Native fast path" inside `DBIO::ClickHouse::Storage` —
`populate` detecting a bulk insert and diverting it to HTTP — would mean the
storage silently using a second protocol, on a second port, with separate
authentication and separate failure modes, in the middle of a `DBIO::Storage::DBI`
subclass. It would also make an XS module a hard dependency of every insert.
**The module is young.** 0.01 in May 2026, 0.02 on 2026-08-11. Nothing in this
driver should stop building because an XS distribution that new does not
compile somewhere.
**The value is in the translation, not the shipping.** Everything hard here is
knowing what `column_info` becomes as a type string and what a DBIO row's
values must look like. Once you have both, `insert_http` is four lines the
user is better off writing themselves, because they own the HTTP policy —
retries, compression, deduplication tokens, TLS.
## Decision
Ship `DBIO::ClickHouse::Native`: a translation between two data
representations, and nothing else.
### 1. It never loads `ClickHouse::Encoder`
No `use`, no `require`, no runtime probe, anywhere in `lib/`. The module
produces plain Perl structures; the user loads the encoder and drives it.
`cpanfile` therefore carries `suggests 'ClickHouse::Encoder'`, never
`requires`. `t/50-native.t` asserts the non-dependency structurally — it
compares generated structures against expected ones and ends by checking that
`ClickHouse/Encoder.pm` is absent from `%INC`. That test is the actual
guarantee; the cpanfile line only records it.
Consequence: no runtime dependency, no XS requirement, no second transport,
and no collision with ADR 0001. The Native bytes leave over a channel DBIO has
no part in, which is the point.
### 2. One type table, exposed rather than copied
`DBIO::ClickHouse::DDL::_clickhouse_column_type` gets a public wrapper,
`DBIO::ClickHouse::DDL->column_type($column_info)`. `columns_for` calls it.
There is no type map in `Native.pm`.
This is the whole reason the bridge is cheap, and duplicating the map would
have been the one change that made it expensive: the Native format is *typed*,
so a column list that disagrees with the deployed table is a wrong-width
binary block rather than a readable error. `t/50-native.t` asserts the
agreement in both directions — `columns_for` against `column_type`, and
`column_type` against what `install_ddl` actually emits — so a second type
table cannot be introduced without turning the suite red.
### 3. Export only; no decode side
There is deliberately no counterpart turning `decode_rows` output back into
`$rs->populate`. Reads already come back over the MySQL wire, so the Native
format buys no throughput there, and supporting it would duplicate the
value-conversion rules for a much narrower case. This is a scope decision, not
a deferral.
### 4. The row side is an iterator, with a slurping convenience over it
`row_iterator($rows, $columns)` returns a coderef yielding one row arrayref
per call and `undef` at the end. `rows_from` is that iterator drained into an
arrayref.
The iterator is primary because it is the encoder's own contract:
`$enc->stream(\&iter, \&writer, batch_size => N)` takes exactly a coderef
returning the next row or `undef`, and runs the pull loop in XS. Matching that
shape means an export of any size goes straight into the encoder's streaming
path with no glue and no materialization — and the encoder's `streamer` /
`push_row` reach it just as directly. `rows_from` stays because `encode`,
`insert_http(rows => ...)` and `bulk_inserter->push_many` all want an
arrayref, and a small export should not pay for a loop it does not need.
The column list is a **required** argument to both, not derived from the
resultset. Deriving it would let the encoder and the rows disagree about the
block layout silently; requiring it makes the coupling something the caller
wrote down.
### 5. Values are deflated by DBIO, converted by nobody
Rows go through `DBIO::Row::get_column`, which *is* DBIO's deflation path — a
value set through an `InflateColumn` accessor is deflated there. The bridge
performs no value conversion of its own, in either direction.
It does not have to. DBIO's deflated temporal form is the storage datetime
parser's `YYYY-MM-DD HH:MM:SS` string, and rows read from the database are in
that same form because that is what the MySQL wire returns. `ClickHouse::Encoder`
parses that form for `Date`, `Date32`, `DateTime` and `DateTime64(P)`;
verified against 0.02's `datetime.c`, where the fractional part and the
timezone marker are both optional, so a DBIO datetime with no fraction lands
correctly. `t/51-native-encoder.t` measures it end to end.
Passing values through untouched is load bearing, not just tidy: a `Decimal`
column arrives from the DBD as a string, and the encoder's string path is
parsed digit-by-digit and exact where its numeric path goes through a `double`
and is lossy past 2^53. Numifying on the way through would silently drop
digits.
### 6. Anything it cannot translate truthfully throws
The Native format is binary and column-typed. A misinterpreted value is a
server error at best and wrong data at worst, so there is no case where
guessing beats failing. All four refusals were measured against
`ClickHouse::Encoder` 0.02 rather than assumed:
- **A column the row never fetched.** `get_column` would answer `undef` and
  the export would carry a value the row does not have.
- **`undef` in a type that is not `Nullable`.** The encoder writes the type's
  zero value — `0` for `Int32`, the empty string for `String` — with no error.
  Silent, so we refuse.
- **A blessed value.** This is the case where the first draft of the error
  message was *wrong*, and measuring changed the reasoning. The encoder does
  not dispatch through `->epoch` — but it does use the value's string or
  numeric conversion, so an object encodes to *something*. With a
  `DateTime` carrying `time_zone => 'Europe/Berlin'`: into `DateTime` it
  stringifies to ISO 8601 without a zone marker and is read as UTC, so the
  epoch is off by the offset; into `Int64` or `Float64` it becomes `2026`, the
  leading digits of the stringification; into `Decimal(10, 2)`, `202600`. All
  without an error. A blessed value means deflation did not happen, and the
  fix belongs on the DBIO side.
- **A composite column holding a plain scalar** — see below.
### 7. Composite types are documented as one-way, not abstracted over
`Array(T)`, `Map(K, V)`, `Tuple(...)`, `JSON`, `Variant(...)` and the geo
aliases need a Perl reference per value. This distribution renders those types
at deploy time, but reading such a column back over the MySQL wire yields
ClickHouse's *text* rendering — the string `['perl','db']` — never an
arrayref. There is no round trip, and there will not be one: heuristic string
splitting would be a parser for a format nobody specified, guessing at
quoting and nesting, and getting it wrong quietly.
So `rows_from` throws when a composite column holds a plain scalar, naming the
column and the reason. The encoder would reject the value too (`Expected
arrayref for Array type`); what is added is the diagnosis, because the useful
question is not that the value is a string but why it could never have been
anything else. Composite columns are exportable from rows built in Perl —
that direction works and is tested.
### 8. The column list is this distribution's deploy truth
`columns_for` answers "what type would *we* deploy", not "what type does the
target table have". For a table this dist deployed they agree by construction;
for a hand-made table they may not, and a mismatch is a wrong-width block.
Documented prominently in the POD, with the pointer to
`ClickHouse::Encoder->for_table`, which runs `describe table` and builds the
encoder from the server's answer. `rows_from` works with that column list just
as well — it reads the type strings, not our metadata.
## Consequences
- New public surface: `DBIO::ClickHouse::Native` (`columns_for`, `rows_from`,
  `row_iterator`) and `DBIO::ClickHouse::DDL->column_type`. Both are stable
  API from here.
- `DBIO::ClickHouse::DDL` now has a consumer outside DDL generation. Changing
  the type map changes what gets *inserted*, not only what gets deployed —
  which was already true of the diff, but is now true of live data paths too.
- New test slot `5x`: `t/50-native.t` (offline, no optional deps, never skips)
  and `t/51-native-encoder.t` (`skip_all` without `ClickHouse::Encoder` /
  `DateTime`). The second is an extra: it verifies claims about *someone
  else's* parser that a structural comparison cannot reach — that every type
  the DDL renders is a type the encoder parses, and that DBIO's deflated
  strings decode to the right ticks and day counts.
- If a Native *fast path* is ever wanted inside the storage, this ADR is what
  it has to argue against, and the argument is ADR 0001: it needs a second
  transport. The bridge does not foreclose it; it makes it unnecessary for the
  case that motivated it.
