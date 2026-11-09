# ADR 0041 — Capability tiers: `_use_X` is both the caller's force and the driver's declaration, and `undef` clears

- Status: accepted
- Date: 2026-08-04
- Tags: capability, storage, contract, drivers, cross-repo, adr-0037

> Supersedes nothing. It **confirms** ADR 0037 §2's recommended declaration form
> and fixes the code that made it look wrong. No driver has to change its
> declaration; four driver files carry a rationale comment that is now false and
> get a doc-only follow-up (§6).

## Context

### What was reported

Two tickets came out of the ADR 0037 / 0039 driver rollout (k135), from two
different drivers, about two edges of the same mechanism.

**k137, from dbio-sqlite.** A driver declaring a capability with
`__PACKAGE__->_use_X(1)` — the form ADR 0037 §2 names — makes a caller's force
unclearable. Measured:

| Form | fresh | force(0) | force(undef) |
|---|---|---|---|
| A — `__PACKAGE__->_use_supports_exists_query(1)` | 1 | 0 | **0** |
| B — `sub _determine_supports_supports_exists_query { 1 }` | 1 | 0 | 1 |

The diagnosis offered: `_use_X` is an inherited accessor, `get_inherited` reads
the instance with `exists()` rather than `defined()`, *so a class-level
declaration lands in the same slot as an instance-level force*. Therefore
`_use_X` is the caller's slot, `_determine_` is the driver's, and ADR 0037 §2
recommends the trap.

**k136, from dbio-oracle.** A driver that declares a capability of its own
gets its `_use_X` accessor only in its own class, so on a not-yet-reblessed
storage the method does not exist:

```
Can't locate object method "_use_set_operator_all_family" via package "DBIO::Storage::DBI"
```

The diagnosis offered: the `around` wrapper at the top of `DBIO::Storage::DBI`
iterates a fixed name list, core's capabilities are on it and a driver's cannot
be, so the fix is a registration mechanism instead of a name list.

Both were reproduced, not theorised. Both symptoms are real. **Both diagnoses
are wrong about the mechanism**, and the shapes proposed to fix them follow from
the wrong diagnoses.

### The mechanism, measured

`Class::Accessor::Grouped::set_inherited` writes **two different places**
depending on the invocant — the instance hash for an object, the
`$Class::__cag_<field>` package variable for a class. `get_inherited` reads the
instance slot with `exists`, then walks the class and its `get_super_paths` with
`defined`.

So there are already three tiers, and they are three distinct slots:

| Tier | Slot | Written by | Read with |
|---|---|---|---|
| 1 — force | `$storage->{_use_X}` | `$storage->_use_X(0\|1)` | `exists` |
| 2 — declaration | `$Class::__cag__use_X`, inherited down `@ISA` | `__PACKAGE__->_use_X(0\|1)` | `defined` |
| 3 — determination | `_dbh_details->{capability}`, wiped per `$dbh` | `sub _determine_supports_X` | — |

Probed directly on `DBIO::Test::Storage` (which declares `supports_exists_query`
in tier 2):

```
class pkg var T::Declared::__cag__use_supports_exists_query = 1
instance slot after force(0):     exists=yes val=0
instance slot after force(undef): exists=yes val=undef  -> getter says 0
after deleting the instance slot:                       -> getter says 1
```

The class declaration was **never overwritten**. It sat there the whole time,
recoverable, behind an instance key that existed and was not defined. The
`undef` assignment did not clear the force — it wrote a **tombstone**, and
`exists` made the tombstone win forever.

That is the entire defect. Not a missing tier, not a slot collision: a clear
that does not clear.

### What that does to the three candidate shapes

- **"`_determine_` is the driver's slot, `_use_` is the caller's."** Rests on the
  false premise. Tier 2 is not the caller's slot; a force and a declaration
  written through the same accessor land in different places, which is exactly
  why the declaration survives the force. Adopting this would correct ADR 0037
  §2 on the strength of a wrong reading, churn nine drivers, and take away the
  one-liner most driver authors reached for — to fix nothing.
- **"Add a third tier below the force."** It exists. Tier 2 *is* a driver-default
  slot below the caller's force and distinct from `_determine_`. Building a
  fourth would give two ways to say the same thing.
- **"Registration instead of a name list."** Cannot work, for a reason
  independent of the name list: core keeps a **static** `%_driver_registry`
  mapping DBD names to storage class names, and `_determine_driver` loads the
  driver's storage class lazily via `load_optional_class`. Pre-rebless the class
  is typically **not loaded at all**, so a `register_capability` call in its body
  has not run and cannot have. Registration can only work after the moment the
  problem disappears.

  The name list is also not the cause. No `_use_*` or `_supports_*` name appears
  on it. Core's capabilities work pre-rebless because every `_use_` accessor
  routes through `get_use_dbms_capability`, and *that* is on the list. A driver's
  capability fails one step earlier, in method resolution, before any wrapper can
  fire.

### What already works for k136, undocumented

Because the shared getter and setter are name-independent, they work pre-rebless
for **any** capability, including one core has never heard of. Measured against a
fake registered driver, with no database:

```
$storage->_use_widgets(1)                              -> dies, no such method
$storage->set_use_dbms_capability('_use_widgets', 0)   -> ok, writes tier 1, no connect
$storage->get_use_dbms_capability('_use_widgets')      -> reblesses, then answers
```

The getter is on the driver-determination list, so asking determines the driver
and answers from it; the setter writes the tier-1 slot the driver's own accessor
reads once it exists. k136 is not a missing mechanism. It is an undocumented one
plus a real, irreducible limitation on the per-name accessor.

## Decision

### 1. Tier 2 and tier 3 are both the driver's; tier 1 is the caller's

`_use_X` is not "the caller's accessor". It is the accessor for the question,
and *how* you write to it decides which tier you are writing to. A driver
declares at class level, a caller forces on an instance, and the two never touch.

Which of the driver's two slots to use is decided by **what is being declared**,
not by what the caller might do with it:

- a **static fact** about the driver → tier 2, `__PACKAGE__->_use_X(0|1)`. Answers
  as a class method, before any connection.
- a **probed fact** (server version, loaded DBD) → tier 3,
  `sub _determine_supports_X`, where `_server_info` is reachable.

**ADR 0037 §2 stands as written.** So does the `DBIO::Storage::DBI::Capabilities`
POD that blessed both forms. The two documents never actually contradicted each
other; the code did.

### 2. `undef` on an instance removes the force

`set_use_dbms_capability` deletes the instance slot instead of assigning `undef`
to it. `undef` is unambiguous here — `get_use_dbms_capability` has always read
`undef` as "no opinion, ask the next tier", so it can never have meant "off";
"off" is `0`. A class invocant is untouched: `get_inherited` already tests
`defined` while walking classes, so an `undef` declaration falls through by
itself.

With that, the measured table reads `1 / 0 / 1` for **both** declaration forms.
The two forms are now interchangeable for the round trip, which is what both
documents always claimed.

### 3. `_use_X` is the read accessor, `_supports_X` is tier 3's

A driver declaring only in tier 2 leaves `$storage->_supports_X` answering the
tier-3 default while `_use_X` answers the declaration. dbio-sqlite recorded this
as a second reason to prefer tier 3, and the observation is correct — but it is
not a disagreement to fix. `_supports_X` means "what did the probe find";
`_use_X` means "what is the answer". Every consumer in core reads `_use_X`
(`ResultSet::upsert`, `ResultSet::results_exist`, `Diff::Op::should_emit_if_exists`,
`Deploy::Base::_execute_ddl`, `DeploymentHandler`, `Storage::Async`); nothing
reads `_supports_X` for a decision. The POD now says so at the tier list.

### 4. k136 is documented, not mechanised

The per-name accessor of a driver-declared capability does not exist before the
rebless, and core cannot make it: it does not know the name and has not loaded
the class. That stays true. What the POD now carries, at the place a driver
author reads before declaring, is the two forms that work regardless — the class
form `DBIO::Yourdb::Storage->_use_X(0|1)` (tier 2, valid from load time) and the
two-argument `get_/set_use_dbms_capability('_use_X', ...)` (name-independent,
valid pre-rebless, and it clears with `undef` like everything else).

A driver's own POD should name one of them. dbio-oracle already does.

### 5. The shared capability name stays driver-local

Three drivers invented the same *kind* of driver-declared capability during the
rollout, feeding their own `_set_operation_keyword` override:
`_use_set_operator_all_family` (dbio-oracle, dbio-mysql),
`_use_set_operator_intersect_except` (dbio-mysql), `_use_intersect_except`
(dbio-sybase). Core does **not** take the name. Three reasons, in order of
weight:

1. **Core never reads them.** ADR 0039's whole point is that core asks
   `_set_operation_keyword($op)` and knows nothing about which engine facts feed
   the answer. A capability core does not consult is not part of core's contract,
   and hoisting these would re-import into core exactly the per-engine grammar
   0039 pushed out.
2. **There is no defensible core default.** The three declare different
   polarities for different reasons — Oracle 0 (no `ALL` family before 21c),
   MySQL 1, Sybase 1 as an opt-*out* a pre-16.0-SP03 deployment sets. ADR 0037's
   precedent for a core default is 0 meaning "nobody checked", which would read
   as "no `ALL` family" on engines that have had it for decades.
3. **They are not the same fact.** The names line up for Oracle and MySQL by
   coincidence of engine history. Sybase's flag is named after a different fact
   because its engine has `UNION ALL` but neither `INTERSECT ALL` nor
   `EXCEPT ALL` at any version — not expressible as `all_family` at all, which is
   why it was not spelled that way.

What core *does* now own is the shape: three tiers, which slot is whose, and how
a driver-declared capability is reached before the rebless. That is the part all
three needed and none of them had.

The one loose end is cosmetic and deliberately not forced: dbio-mysql and
dbio-sybase spell the same engine fact `_use_set_operator_intersect_except` and
`_use_intersect_except`. Worth aligning if either is touched for other reasons;
not worth a rename on its own.

### 6. Contract version: inside 1.2

`$CONTRACT_VERSION` stays `'1.2'`, by the in-cycle rule
`t/test/12_contract_version.t` already records: 1.2 has never been released, so
no consumer can have seen a 1.2 with the old behaviour. Even outside the cycle
this is not a bump a driver could act on — no shape changes, only which of two
already-documented declaration forms is correct, and the answer is now "both".
The tripwire comment in that file carries the reasoning.

## Consequences

- Both declaration forms are correct and interchangeable. A driver author picks
  by what they are declaring, not by which trap they are avoiding.
- A caller can force a capability off and get the driver's answer back. Nothing
  in the family does this today outside tests; the reason it matters is that four
  driver files chose their declaration form to work around it.
- Drivers that declared in both tiers "belt and braces" (dbio-oracle, dbio-sybase
  for their set-operation flags) no longer need to. Harmless either way; not
  worth a change on its own.
- One core test changed its assertion, and that is the finding: the
  `T::EQ::Undeclared` block in `t/test/23_exists_query_seam.t` was faking a
  non-declaring engine *by writing the tombstone*, with a comment saying "this
  engine's driver never declared the capability" about a class that inherits the
  declaration. It now declares `0` at class level and says so.
- `t/test/26_capability_tiers.t` pins the measurement: the k137 table on
  both forms, that tiers 1 and 2 are separate slots, that `undef` is not `0`,
  inheritance, the class invocant, and the k136 pre-rebless behaviour in
  both directions. Reverting the fix fails exactly four of its assertions.

### Cross-repo follow-up (doc-only, tracked, not done here)

No driver's declaration is wrong. Four files carry a *rationale* that is now
false — they state that a class-level `_use_` declaration sits in the same slot
as an instance force and is therefore unrecoverable:

- **dbio-sqlite** — `lib/DBIO/SQLite/Storage.pm` (the comment block above
  `_determine_supports_supports_exists_query`, and the shorter one above
  `supports_upsert_where`) and `t/23-results-exist.t`. The `_determine_` choice
  itself remains valid and needs no change; the mechanism claim and the closing
  "this is an ADR 0037 precision for the core board" both resolve here. The
  driver's second argument — that tier 2 leaves `_supports_X` answering the
  default — is correct and is answered by §3, not by the code.
- **dbio-mysql** — `lib/DBIO/MySQL/Storage.pm` (the comment above the two
  set-operation capabilities) and `t/28-set-operations.t` (the `$roundtrip`
  block). Same correction; the `_determine_` declarations stay.
- **dbio-oracle** — optional. Its POD names the class form as primary, which is
  right; it may now also name the two-argument form for the per-storage case it
  currently describes as "valid on a storage that has already been reblessed".

## Future architecture work (tracked cross-repo, not here)

None. The `_set_operation_keyword` capabilities stay where they are (§5); if a
tenth driver needs the same fact under a third spelling, that is a naming
question on the driver boards, not a core one.
