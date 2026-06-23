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
- `after` applies a **`pk > value` seek**: for a single-column PK,
  `{ $pk => { '>' => $decoded } }`; for a composite PK, a per-column
  `{ $pk[i] => { '>' => $decoded[i] } }` condition. The query then fetches
  `first + 1` rows to compute `hasNextPage`, and emits `nextCursor` from the
  last kept row's PK.
- **Cursor wins over `page`.** When both `cursor` and `page` are supplied,
  cursor pagination is taken and offset pagination is ignored
  (`_apply_pagination` checks `$args->{cursor}` first; the precedence is
  documented in the helper's comment).
- Ordering defaults to ascending PK (`_apply_pagination` orders by
  `primary_columns` when no `orderBy` is given), which is what makes the
  `pk > value` seek correspond to "the next page."

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

- **A custom non-PK `orderBy` breaks cursor advancement.** The `after` seek is
  always `pk > lastPK`, but if the result is ordered by some other column, the
  PK-based seek no longer corresponds to "rows after the last one in display
  order." Pages can skip or repeat rows. This is a sharp, known failure mode:
  when ordering by a non-PK column, **fall back to offset (`page`)
  pagination**, which is order-agnostic. Cursor pagination is only sound when
  the effective order is the PK order the cursor assumes.
- Cursors are not encrypted or signed — they expose the boundary row's PK
  values to the client. This is acceptable because PKs are already visible as
  ordinary fields; do not treat a cursor as a secret.
- Composite PKs are supported, but the multi-column `after` condition is a
  per-column `>` (not a strict lexicographic keyset predicate); it is correct
  for the common single-column PK and for ascending PK order, and should be
  revisited if strict composite keyset semantics are ever required.
- Because cursor wins over `page`, a client that sends both gets cursor
  behaviour; this precedence is intentional and must be preserved.
