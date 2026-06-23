# ADR 0003 — One identifier-shortening algorithm, shared by SQL generation and deploy

- Status: accepted
- Date: 2026-06-22
- Tags: identifier, sqlmaker, ddl, deploy, oracle, limits

## Context

Oracle (pre-12.2) caps identifiers at 30 bytes. DBIO routinely generates names
that exceed it: relationship-derived table aliases (`relname_to_table_alias`),
qualified column references in WHERE/HAVING, and — on the deploy side —
generated sequence and index names. A name that is too long must be shortened,
but shortening introduces a hard correctness constraint that no other DBIO
driver faces: a name shortened at **deploy time** (when the index/sequence is
created) must come out byte-identical to the same name shortened at **query
time** (when it is referenced), or the query references an object that does not
exist.

This rules out any per-call-site or per-layer shortening logic. The two layers —
`DBIO::Oracle::SQLMaker` (query time) and `DBIO::Oracle::DDL` (deploy time) —
must run the *same* deterministic function over the *same* input.

## Decision

Own the shortening algorithm in a single module, `DBIO::Oracle::Identifier`,
exposing one pure function `shorten($name, \@keywords?)`
(`Identifier.pm:37-96`), and have every layer route through it:

- **Query time** — `DBIO::Oracle::SQLMaker::_shorten_identifier` delegates to
  `DBIO::Oracle::Identifier::shorten` (`SQLMaker.pm:172-175`); it is invoked from
  `_quote` for both the string path and the SQL::Abstract v2 arrayref-segment
  path (`SQLMaker.pm:149-170`, see ADR 0005), from `_unqualify_colname`, and via
  `DBIO::Oracle::Storage::relname_to_table_alias` (`Storage.pm:175-180`).
- **Deploy time** — `DBIO::Oracle::DDL` calls the same module when emitting
  generated sequence and index names.

The algorithm itself (`Identifier.pm:37-96`): names ≤ 30 chars are returned
**unchanged**; longer names are CamelCase-compressed (vowels trimmed, then
proportionally truncated if still too long) to form a human-readable prefix, and
suffixed with a base36-encoded MD5 of the *original* full name. The MD5 suffix
guarantees the result is stable across runs and collision-resistant; a minimum
entropy of 10 chars is reserved for the suffix (`Identifier.pm:40-43`). The
optional `\@keywords` arrayref controls the prefix (defaulting to the identifier
itself), so e.g. an index name can be built from its table+column keywords while
still hashing on the full original.

## Rationale

The correctness invariant — *same name on both sides of the
deploy/query boundary* — is only achievable if both sides call one function
over identical input. Splitting the logic (even with "the same" algorithm
copy-pasted into SQLMaker and DDL) would let the two drift, and the failure mode
is silent at generation time and only surfaces as a missing-object error at
runtime. The module's own POD states this contract explicitly
(`Identifier.pm:11-23`): "a name generated at deploy time matches the name
referenced at query time."

Hashing the *original* full name (not the truncated prefix) is what makes the
suffix a true uniqueness guard: two different long names that compress to the
same prefix still get different suffixes. The deterministic base36(MD5) was kept
(rather than a counter or a session-scoped map) precisely because it needs no
shared state between the deploy process and the query process — the only way two
independent code paths can agree without coordination.

## Consequences

- Oracle is the only DBIO driver with a dedicated identifier module; this is the
  expected shape, not an outlier to "simplify" away.
- **The algorithm is frozen by contract.** Changing the compression, the suffix
  length, the entropy reserve, or the hash input changes the produced names — and
  any name already materialised in a deployed Oracle schema would no longer match
  what query time generates. Treat `shorten` as a versioned wire format: a change
  is a migration concern, not a refactor.
- Every site that needs a shortened Oracle name must go through
  `DBIO::Oracle::Identifier::shorten` (directly or via
  `SQLMaker::_shorten_identifier`). Introducing a second shortening path
  reintroduces the drift this ADR exists to prevent.
- Requires `Digest::MD5`, `Math::BigInt`, `Math::Base36` (`Identifier.pm:7-9`).

## Related

- ADR 0005 (CONNECT BY / arrayref `_quote` — the WHERE/HAVING qualifier path
  that was found bypassing shortening and had to be routed back through this
  module)
- core ADR 0008 (`DBIO::SQL::Util` cross-driver helpers — generic quoting that
  this Oracle-specific concern sits alongside, not inside)
