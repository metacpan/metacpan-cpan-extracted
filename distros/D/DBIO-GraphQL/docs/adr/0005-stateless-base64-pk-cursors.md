# ADR 0005 — Stateless base64 PK cursors; cursor pagination assumes PK order

- Status: accepted
- Date: 2026-06-21
- Tags: graphql, pagination, cursor, backfill

## Context

The plural `all<Source>s` query offers two pagination modes
(`_apply_pagination`, `GraphQL.pm`): offset pagination (`page: { skip, take }`)
and cursor pagination (`cursor: { after, first }`). Cursor pagination needs
an opaque token that names a position in the result stream, such that
"give me the rows after this token" is well-defined and cheap.

The available designs span a spectrum: a server-side cursor handle held
across requests (stateful, needs storage and lifecycle), an encrypted/opaque
blob backed by a dependency, or a self-describing token derived from the last
row's stable key. This distribution is a schema-generation layer with a
deliberately small dependency footprint, and cursors must survive across
independent stateless requests.

## Decision

Cursors are **stateless, self-describing, base64-encoded primary keys**, with
no server-side state and no extra dependencies beyond core `MIME::Base64`
(`GraphQL.pm`, `_encode_cursor` / `_decode_cursor`).

- A cursor is `base64( val1:val2:... )` of the **last returned row's primary
  key** (all PK columns, in order — composite PKs supported). Colons and
  percent signs inside values are percent-escaped (`%` → `%25`, `:` → `%3A`)
  so the `:` separator is unambiguous; `_decode_cursor` reverses this.
- `after` applies a **`pk > value` seek**, row-wise over all PK columns: one
  `OR` branch per column, with every column before it equal to the cursor's
  value and that column greater (`a > x OR (a = x AND b > y) OR …`). A
  single-column PK is the one-branch case of the same construction. A cursor
  that does not carry one value per PK column is refused, as is any `after`
  that is not canonical base64 (`_decode_cursor` checks alphabet, length and
  that re-encoding gives the input back; `decode_base64` alone would skip
  illegal characters). `after` is tested with `defined`: the cursor of the
  key `''` is the empty string and is a valid position. Splitting keeps empty
  trailing components (`split /:/, $raw, -1`), so `('x', '')` round-trips.
  Cursor pagination on a source without a primary key, and `first < 1`, die
  with a clear message (karr k12). The query then
  fetches `first + 1` rows to compute `hasNextPage`, and emits `nextCursor`
  from the last kept row's PK.
- **Cursor wins over `page`.** When both `cursor` and `page` are supplied,
  cursor pagination is taken and offset pagination is ignored
  (`_apply_pagination` checks `$args->{cursor}` first; the precedence is
  documented in the helper's comment).
- Ordering defaults to ascending PK (`_apply_pagination` orders by
  `primary_columns` when no `orderBy` is given), which is what makes the
  `pk > value` seek correspond to "the next page." Under `cursor` that order
  is the only one: an `orderBy` naming the first PK column ascending is
  accepted and leaves the full PK order in place, any other `orderBy` is
  refused with an error (karr k6).

## Rationale

A stateless PK cursor needs no server-side session, no storage, and no
cleanup — every request carries everything required to resume, which is the
right fit for a stateless GraphQL endpoint and for a layer that wants to add
no runtime dependency. Encoding the PK (rather than an offset) makes
`after` a keyset seek (`pk > value`) instead of a large `OFFSET`, so deep
pages stay cheap and do not skew when rows are inserted/deleted between
requests. Base64 keeps the token opaque to clients and URL/transport-safe;
the percent-escaping of `:` and `%` keeps composite-PK decoding unambiguous.

The design's correctness rests on one assumption: that the result is ordered
by the same PK the cursor encodes. That assumption is satisfied by the
default ordering, which is why cursor pagination is paired with PK ordering.

## Consequences

- **`cursor` with any other order is refused, not served.** The `after` seek
  is always `pk > lastPK`; if the result were ordered by another column, or by
  the PK descending, that seek would no longer correspond to "rows after the
  last one in display order" — pages skip or repeat rows, and under PK `DESC`
  `nextCursor` leads straight back to the first page. `_apply_pagination`
  therefore dies on such a combination instead of handing out a cursor that
  cannot be followed (karr k6); for those orderings clients **use offset
  (`page`) pagination**, which is order-agnostic. Serving them by cursor would
  need the sort column's value in the cursor and a seek in that order — a
  different cursor format, deliberately not built.
- Cursors are not encrypted or signed — they expose the boundary row's PK
  values to the client. This is acceptable because PKs are already visible as
  ordinary fields; do not treat a cursor as a secret.
- Composite PKs are supported with a strict lexicographic keyset predicate.
  The earlier per-column `>` (`a > x AND b > y`) dropped every row whose later
  key columns were not greater than the cursor's, while `total` still counted
  them (karr k6); `t/05-composite-pk.t` walks a two- and a three-column key to
  the end by cursor to keep that from coming back.
- Because cursor wins over `page`, a client that sends both gets cursor
  behaviour; this precedence is intentional and must be preserved.
