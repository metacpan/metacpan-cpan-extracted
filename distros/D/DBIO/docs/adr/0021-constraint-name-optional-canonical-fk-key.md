# ADR 0021 — `constraint_name` is an optional canonical foreign-key key

- Status: accepted
- Date: 2026-06-21
- Tags: introspect, foreign-keys, diff, drivers, cross-driver, family-policy

## Context

The canonical introspect model that `DBIO::Introspect::Base`
(`lib/DBIO/Introspect/Base.pm`, "CANONICAL MODEL") defines describes each
foreign key in the `foreign_keys` section — `{ $table => [ \%fk, ... ] }` — with
five keys: `from_columns`, `to_table`, `to_columns`, `on_update`, `on_delete`.
There is no key for the foreign key's name.

Yet the server-assigned constraint name is fetched by essentially every driver,
because it is the natural grouping key for composite (multi-column) foreign keys:
the catalog returns one row per local/remote column pair, and the rows for a
single composite FK are tied together by their shared name. Core's own grouping
helper documents exactly this — `_aggregate_by_ordered`
(`lib/DBIO/Introspect/Base.pm`, ~line 63) uses `'constraint_name'` as its
worked example, and the drivers call it with that field to keep the declared
local/remote column pairing in order.

What each driver does with the name *after* grouping has diverged, and the
divergence is purely in the key spelling — not in whether the value exists:

- **MSSQL** keeps it as bare `constraint_name` in the per-FK model hash
  (`dbio-mssql/lib/DBIO/MSSQL/Introspect/ForeignKeys.pm:62`, POD documents the
  key). Conformant.
- **PostgreSQL** keeps bare `constraint_name` in the `foreign_keys` section
  (`dbio-postgresql/lib/DBIO/PostgreSQL/Introspect/ForeignKeys.pm:115`), but its
  `table_fk_info` relationship path emits `_constraint_name`
  (`dbio-postgresql/lib/DBIO/PostgreSQL/Introspect.pm:347`). Mixed.
- **DB2** keeps `_constraint_name`
  (`dbio-db2/lib/DBIO/DB2/Introspect.pm:85`). Underscore variant.
- **Informix** keeps `_constraint_name`
  (`dbio-informix/lib/DBIO/Informix/Introspect.pm:174`; POD ~line 165).
  Underscore variant.
- **Sybase** fetches *and* keeps `constraint_name` in the subdir helper
  (`dbio-sybase/lib/DBIO/Sybase/Introspect/ForeignKeys.pm:61`), then **drops it**
  in `_group_fks_by_constraint`
  (`dbio-sybase/lib/DBIO/Sybase/Introspect.pm:79`) — the resulting `foreign_keys`
  entries carry only the five canonical keys, so the name is lost from the model.
  Non-conformant: it loses the name.

So the field is present nearly everywhere; only the **key name** is
unstandardised (`constraint_name` vs `_constraint_name`), and Sybase alone drops
it on the floor. A cross-driver contract field-name is exactly the kind of
family-wide rule that, per the ownership lesson of ADR 0018, belongs in core and
not in any one driver's repo. This ADR is a sibling to 0018 in spirit: it makes
the naming call once, here, with authority over the whole family.

## Decision

1. `constraint_name` becomes an **optional** canonical foreign-key key in the
   `DBIO::Introspect::Base` "CANONICAL MODEL" `foreign_keys` section, alongside
   the five existing keys. It follows the same "optionally" precedent that the
   `columns` section already sets for `is_auto_increment`: a driver that can
   introspect a stable server-assigned FK name **should** carry it; a driver
   whose engine cannot omits it, and the model stays valid either way. It is not
   promoted to a required key.

2. The blessed key name is **`constraint_name`** (bare, no leading underscore).
   The `_constraint_name` underscore variants — DB2, Informix, and the
   PostgreSQL `table_fk_info` relationship path — are non-conformant and realign
   to `constraint_name`.

3. `table_fk_info` (`lib/DBIO/Introspect/Base.pm:267`), the relationship/generation
   contract method consumed by `DBIO::Generate`, is **not** changed by this
   decision. Nothing on the generation path consumes the FK name today, so
   threading it through there would be speculative. This ADR notes it only as a
   possible future surface; the decision does not touch it now.

4. The motivating consumer is the **Diff/Deploy** path (ADR 0007). A driver's
   `Diff::ForeignKey` reads `model->{foreign_keys}` directly; when
   `constraint_name` is present it **should** prefer the real server name for
   `DROP`/`ALTER` instead of a deterministically generated name.

## Rationale

The constraint name is already a first-class part of how every driver builds its
FK model — it is the grouping key, and core's helper documents it as such. The
only thing missing was a *blessing* in the canonical model and a single agreed
spelling. Recording it as optional rather than required matches reality: not
every engine exposes a stable, reusable server-side FK identifier, and a driver
that cannot must not be made non-conformant for lacking one. The `is_auto_increment`
precedent in the `columns` section is the established shape for "carry it if you
have it" — reusing that pattern keeps the model honest and avoids forcing drivers
to fabricate a value.

Standardising on the bare name (not `_constraint_name`) follows the rest of the
canonical model, where every section key is bare; the underscore variants were
local accidents, not a deliberate convention, and a single spelling is what makes
a *cross-driver* consumer like Diff able to read the field uniformly. Leaving
`table_fk_info` untouched is simplicity-first: no generation-path code reads the
name, so adding it there would be an abstraction with no caller.

The decision belongs in core because it is a family-wide field-name contract, and
ADR 0018 already established that a family rule recorded in a single driver's repo
carries no authority over the others. Blessing the key here gives every driver —
and the Diff layer that spans them — one source for the rule.

## Consequences

- **Sybase karr #14 is unblocked and becomes purely driver-local.** No core code
  change is required; the contract blessing is enough. Sybase stops dropping the
  name in `_group_fks_by_constraint`, carries `constraint_name` into
  `model->{foreign_keys}`, and has `DBIO::Sybase::Diff::ForeignKey` prefer the
  real server name for `DROP` (falling back to the deterministically generated
  name only when the name is absent). This is the FK drop/alter fidelity gap that
  follows the FK diff op shipped in Sybase karr #11.
- **Drivers using `_constraint_name` realign to bare `constraint_name`** — DB2,
  Informix, and the PostgreSQL `table_fk_info` relationship path. Each is tracked
  as a per-driver follow-up ticket on that driver's own board (driver-repo work).
- **MSSQL and the PostgreSQL `foreign_keys` section are already conformant** and
  need no change.
- **`constraint_name` must NOT be added to the compared field set of the FK
  comparator.** `changed_fk_fields` (core; ADR 0019) compares FK *attributes*, not
  identity. The constraint name is FK metadata for DROP/ALTER fidelity, not a
  semantic attribute of the relationship — adding it to the compared fields would
  make two otherwise-identical FKs that happen to carry different server-assigned
  names phantom-diff on every upgrade. It is read for DROP targeting, never
  compared.
- `table_fk_info` may later carry the name if a generation-path consumer appears;
  until then it is deliberately left alone.

Relates to ADR 0007 (native diff/deploy layer), ADR 0018 (family-policy ownership
pattern), and ADR 0019 (FK comparator and desired-state skip); and to Sybase karr
#11 (FK diff op shipped) and #14 (this follow-up).
