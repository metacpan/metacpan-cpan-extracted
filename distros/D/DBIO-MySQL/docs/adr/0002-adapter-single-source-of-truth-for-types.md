# ADR 0002 — `DBIO::MySQL::Adapter` is the single source of truth for base→native types

- Status: accepted
- Date: 2026-06-20
- Tags: types, adapter, ddl, diff, charset, backfill

## Context

Three layers in this driver need to agree on how a portable DBIO base type
becomes a concrete MySQL type, and on which native types carry a character
set / collation:

- `DDL.pm` emits `CREATE TABLE` column types for a fresh install.
- `Diff.pm` (`target_from_compiled`) rebuilds the desired-state model in the
  exact `information_schema` shape so it can be diffed against a live
  introspect.
- The diff comparison must know which types report `character_set_name` /
  `collation_name` as NULL (binary, numeric, datetime families) so it does not
  emit phantom charset changes.

Originally the base→native mapping and the no-charset set were duplicated
across these layers — a `%_NO_CHARSET` table lived inside `Diff.pm`, the type
map lived inside `DDL.pm`, and `to_native` logic risked a third copy. Three
sources of truth for the same fact (karr #4, "consolidate 3+ sources of
truth"). When they drifted, the diff produced spurious operations.

## Decision

`DBIO::MySQL::Adapter` (subclass of core `DBIO::Adapter::Base`) is the **one**
owner of base→native MySQL type resolution and of charset/collation
suppression.

- `to_native(\%canonical_column)` is the only place a DBIO base type
  (`integer`, `text`, `boolean`, `double`, `blob`, `timestamp`, `char`,
  `numeric`) maps to a MySQL native type (`BIGINT`, `LONGTEXT`, `TINYINT(1)`,
  `DOUBLE`, `LONGBLOB`, `DATETIME`, `CHAR(n)`, `DECIMAL(p,s)`).
- `no_charset_for($native_type)` is the only place that answers "does this
  native type carry a charset/collation in `information_schema`?" It owns the
  `%NO_CHARSET` set (`bigint tinyint double decimal longblob datetime`) and
  strips `(...)` parameters before the lookup.
- `DDL.pm` calls `$ADAPTER->to_native` for every base type (`_mysql_column_type`
  delegates to the adapter; the local `%type_map` is for *legacy/dialect
  aliases only*, explicitly not the base-type names).
- `Diff.pm`'s `target_from_compiled` calls `$ADAPTER->no_charset_for` instead
  of carrying its own table; the `%_NO_CHARSET` that used to live in `Diff.pm`
  is gone.

## Rationale

The base→native mapping and the no-charset predicate are *the same fact*
consumed by install (DDL) and migration (Diff). A duplicated fact in a
test-deploy-and-compare deployer is not a style nit: a divergence between the
DDL producer and the diff's target model manifests as phantom ALTERs on every
`upgrade`, because the desired-state model no longer round-trips to what the
DDL actually created. Centralising in the Adapter — which core already
positions as the per-driver one-way type resolver (`DBIO::Adapter::Base`) —
gives both layers the same answer by construction. The Adapter is the natural
home because it is the only module both `DDL` and `Diff` already depend on for
this purpose.

## Consequences

- New base-type → MySQL-type mappings and new charset-bearing/charset-free
  type classifications go in `Adapter.pm` only. DDL and Diff must consume it,
  never re-derive it.
- **Open escalation (not resolved here).** `target_from_compiled` leaves
  `character_set`/`collation` `undef` for *text/char* columns too, because a
  portable schema does not prescribe a charset while the live MySQL/MariaDB
  server assigns one (e.g. `utf8mb4` / `utf8mb4_uca1400_ai_ci` on MariaDB
  11.8). That produces phantom diffs for text columns whenever the live DB
  reports a non-null charset. The standing ESCALATION NOTE in `Diff.pm`
  (`target_from_compiled`) frames this as a controller-level design question —
  "should the desired-state diff ignore attributes the target leaves
  unspecified?" — and is **owned by core's diff engine**, not by this driver.
  See the cross-repo karr ticket filed against `dbio` for the desired-state /
  unspecified-attribute semantics. This ADR records where the type facts live;
  it does not decide that policy.
