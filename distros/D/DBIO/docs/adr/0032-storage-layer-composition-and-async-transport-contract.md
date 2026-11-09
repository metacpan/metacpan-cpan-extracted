# ADR 0032 — Storage-layer composition and the async transport contract

- Status: accepted
- Date: 2026-07-09
- Tags: storage, async, composition, extensions, contract, capabilities, builds-on-0030, hard-cut

## Context

DBIO storage *extensions* (AGE, PostGIS, EV) and DBIO async *transports*
(future_io, EV) are two independent axes. Before this decision an extension that
also wanted async had to hand-write one class per (extension × transport) cell —
an N×M matrix — and welded itself to a transport by `use base`-ing its async
storage. The k69 ideation surveyed this and the maintainer approved a single
fundamental model (k70): **one behaviour, one transport**. N extension layers and
M transports compose *at runtime* into every cell; no hand-written N×M classes,
ever.

The model was already true de facto: `DBIO::PostgreSQL::Age::Storage::Async` only
touches `_query_async`, `_transform_sql`, `future_class`, pure helpers and the
pool replay seam — it is transport-neutral in substance and welded to future_io
only by its `use base`. `EV::Storage` exposes the same method surface. This ADR
makes that contract structural.

Builds on **ADR 0030** (async is an explicit per-connection mode; resolution
stays explicit — only class *composition* is new here) and **ADR 0028** (embedded
async backend). It is emphatically **not** the banned ADR 0029 mode
auto-fallback: the caller still writes `{ async => 'future_io' }`; only the layer
*classes* are resolved and composed.

## Decision

### 1. Runtime C3-MRO class synthesis (`DBIO::Storage::Composed`)

Extensions ship as **layers**: plain method packages that override or wrap the
documented public storage surface and chain with `$self->next::method(@_)`. A
layer MUST NOT `use base` a driver storage. `compose($base, \@layers)` synthesises
an empty package whose `@ISA` is `(@layers, $base)` under the `c3` MRO — the same
mechanism family as `load_components` — and caches it in a `%COMPOSED` registry
keyed by a deterministic name, so a given `(base, layers)` tuple maps to exactly
one class, built at most once.

An explicit **collision check** runs at compose time: each layer's *own* methods
(compiled body originating in that package — imports and inherited subs excluded)
are scanned; if two or more layers define the same method name, `compose` croaks
naming the method and every defining package. A single layer overriding a base
method is ordinary `next::method` layering and is fine; two layers overriding the
same base method still croak — the resolution between them would be an accident of
registration order, never silent shadowing.

### 2. `register_storage_layer` on `DBIO::Schema`; registration order = precedence

`__PACKAGE__->register_storage_layer($layer_class)` appends to the inherited
class-data `storage_layers` (default `[]`). It is append-only, order-preserving,
de-duplicated by class name, and **copies before appending** — the shared
inherited default arrayref is never mutated in place, so a registration never
leaks into a parent or sibling schema. Callable on the class or a connected
instance; an extension typically calls it from its own `connection()` override.

Registration order **is** C3 precedence: the first-registered layer is the
most-specific `@ISA` rung, wins the MRO, and its `next::method` reaches the next
layer, then the base — consistent with `load_components` (first-loaded runs
first).

### 3. Composition wired into `connection()` and the driver rebless

`DBIO::Schema::connection` composes the registered layers over the resolved base
storage class (after the `+`/`::` strip) and instantiates the synthesised class.
Because the generic base gets reblessed into its concrete driver class during
`_determine_driver`, the rebless path is composition-aware: a composed instance
whose base is the generic `DBIO::Storage::DBI` still enters driver determination
(the bare `ref($self) eq __PACKAGE__` gate is widened via
`DBIO::Storage::Composed->composition_of`), and the rebless target is
`recompose(ref $self, $driver_class)` — the same layers re-composed over the
driver — at both the driver and the connector rebless sites. A non-composed
instance has no registry entry and behaves exactly as before.

### 4. Async mirror composition

Once the async transport class is resolved (ADR 0030 resolution **unchanged** —
the mode stays explicit), `_async_storage` mirrors each registered *sync* layer
onto its *async* counterpart and composes them over the transport. Per sync layer
`L`, in registration order:

- `L->async_layer_class($mode)` if `L` defines it — a package (must load, else
  croak) or `undef` (fall back to convention);
- otherwise the convention sibling `"${L}::Async"` via `load_optional_class`;
- absent → skip `L` silently (a sync-only extension, e.g. PostGIS).

The resolved async layers are composed over the transport with the same collision
check. A storage with no live schema carries no layers and mirrors nothing.

**Amended 2026-09-25 (k159):** the meaning of `undef` from `async_layer_class`
is reversed — defined-and-`undef` is now the stated sync-only opt-out, and only a
layer that does *not* define the method uses the convention. The silent
"absent → skip" is gone: since step 3 (2026-09-25) it is a refusal. See the
addendum at the end of this ADR.

### 5. Transport capabilities

`DBIO::Storage::Async->transport_capabilities` returns a list (base default
empty); transports override it (future_io → `on_connect_replay`; EV → `listen`
`notify` `copy` `pipeline` … per their own tickets). An async layer may declare
`required_transport_capabilities`. Before composing, any capability a layer
requires but the transport lacks makes `_async_storage` croak naming the layer,
the missing capabilities and the transport, with the hint to upgrade the
transport or choose another async mode. A transport gap becomes that transport's
ticket — never a silent feature loss.

**Amended 2026-07-27 (k118):** the rule as stated above is declaration-driven
and is no longer complete on its own — a layer that declares *nothing* is not
unchecked, it is taken to require the default query seam `_query_async`. See the
addendum at the end of this ADR.

### 6. The `?` placeholder contract at the async seam

`_query_async` / `_query_async_pinned` receive **sql_maker dialect with `?`
placeholders**; a transport MUST shape the dialect internally (its own
`_transform_sql` or equivalent). `_transform_sql` is demoted to a
transport-**internal** helper — no caller outside a transport implementation may
invoke it. The caller-side `_transform_sql` in `_run_crud` is therefore removed —
but *sequenced*: the transport-side internalisation (dbio-async k3) lands FIRST,
because `?`→`$N` rewriting is idempotent on SQL with no `?` left, so shaping in
both places during the transition is safe, whereas core removing its call sites
before transports shape internally would send unshaped SQL to the wire.

### 7. Hard cut of the extension `storage_type`-override pattern

Extensions no longer subclass a driver storage via `storage_type`; they register
layers. This is a **hard cut** — no deprecation window — justified by pre-stable
status.

## Consequences

- No hand-written N×M extension×transport classes; every cell is synthesised on
  demand. Extensions are transport-neutral in substance.
- Failure is loud and early: method collisions and capability gaps croak at
  compose time, never silently shadow or degrade.
- **Known follow-up seam (future_io walk vs. composed sync MRO):** the future_io
  convention walk resolves the transport by probing `<pkg>::Async` along
  `mro::get_linear_isa(ref $self)`. Once a *sync* storage is composed with layers,
  its MRO contains the layer packages, and a layer's async mixin `L::Async` (the
  §4 convention target — a plain layer, not a `DBIO::Storage::Async`) is probed
  *before* the driver's real transport and croaks "loaded but is not a
  DBIO::Storage::Async". No consumer hits this yet (no extension registers a sync
  layer today), but it must be reconciled in core before AGE/PostGIS migrate to
  layers on future_io — the walk should resolve against the composition *base*,
  not `ref($self)`. Tracked separately; the ADR 0030 walk is otherwise left
  frozen as k70 specified.
  **Update 2026-07-20: landed.** The walk now resolves against the composition
  base: `DBIO::Storage::DBI::_async_resolution_class` strips registered layers
  via `DBIO::Storage::Composed->composition_of` before the future_io probe and
  the mode-registry lookup, so a sync layer's plain `L::Async` mixin is never
  mistaken for the transport (k70; covered by
  `t/composed/async_walk_base.t`).
- Sequencing: the §6 caller-side `_transform_sql` removal in core is held behind
  the coordinated dbio-async k3 PR train.

## Downstream

Reference driver compliance + skill sync (dbio-postgresql k28), thin-transport
refactor (dbio-postgresql-ev k22), layer migration + hard cut (dbio-postgresql-age
k6, dbio-postgresql-postgis k4), transport dialect internalisation + capabilities
(dbio-async k3). Supersedes the k69 ideation.

## Addendum 2026-07-27 — the default seam is the implicit requirement

§5 states the transport gate as **declaration-driven**: a layer that declares
`required_transport_capabilities` is checked against the transport, a layer that
declares nothing is not checked at all. k118 (commit `8f0a1593b`) added a
refusal case §5 does not describe, which changes the decision recorded here rather
than merely implementing it — hence an addendum rather than an inline update.

### The hole, and the rule that closes it

The protection ran the wrong way round. A layer that *declared* a requirement and
did not find it was stopped; a layer that simply said **nothing** composed onto any
transport without a word — including a transport that owns no query path, where the
layer would load, compose and then quietly do nothing. That is precisely the silent
feature loss §5 exists to prevent, and it was reachable only by the layers that had
said the least: well-behaved authors were policed, silent ones were waved through.
The gate protected by *declaration*, not by *seam*.

A missing declaration is therefore now read as **"needs the default seam"**. The
layer is taken to require `_query_async` — the seam a layer wraps — and a transport
that does not own that seam refuses the composition, croaking with the layer, the
seam, the transport and what the author should do instead. "Says nothing" becomes
the safe case rather than the unchecked one, and the hole closes for every
transport, not only for the forked one (the Model A shape of ADR 0030 §4, which
overrides the six `*_async` entry points directly and runs ordinary sync CRUD in the
child, is what surfaced it).

The seam rule is an *alternative* to the declared check, not an addition on top of
it: a layer that declares anything is checked against its declaration alone and
keeps the pre-k118 behaviour exactly. Declaring is the author answering the
transport question, and we do not then second-guess the answer.

### How the seam is probed — and why not the two obvious ways

A transport owns the seam **iff it actually overrides the abstract `_query_async`
stub on `DBIO::Storage::Async`**. `_async_storage` in `lib/DBIO/Storage/DBI.pm`
resolves `_query_async` on the transport class and on `DBIO::Storage::Async` and
compares the two code refs by **identity**: the transport has the seam only where
its resolution differs from the abstract one. Both alternatives a later reader is
likely to reach for are wrong, so they are recorded here rather than left to be
rediscovered and "cleaned up":

- **Not `can()` alone.** `DBIO::Storage::Async` defines `_query_async` as an
  abstract stub, so every transport inherits it and `can()` is true for all of them.
  A `can()` test cannot distinguish a transport that owns the query path from one
  that does not; only the comparison against the stub can.
- **Not as a capability name.** Requiring the string `_query_async` through the
  ordinary `transport_capabilities` machinery would look tidier and would be wrong:
  no transport lists `_query_async` there — it is a seam, not a feature a transport
  advertises — so a name-based check would have refused *every* existing
  composition, including the pooled transports that do own the query path. The seam
  question is structural and has to be answered structurally.

### The explicit empty list is the documented opt-out

A layer that genuinely needs nothing from the transport declares an **explicit
empty** `required_transport_capabilities`, and composes over a seamless transport
exactly as before. The distinction the rule turns on is not "requires nothing"
versus "requires something" but **stated versus silent**: "I need nothing" is an
assertion the layer author owns and can be held to, while silence carries no
information and is read as needing the seam. A layer that legitimately belongs on a
Model A transport therefore has a one-line, self-documenting way to say so.

### Why option (b) — a named axis — stays out

The alternative was a declared axis such as `sync_crud_in_child`: a Model A
transport advertises it, a layer that can live without a query seam requires it, and
the ordinary capability machinery does the rest. It stays out, as decided in
dbio-forked k1; the reasoning is recorded here because ADR 0032 is where such an
axis would land if it is ever built.

A named axis earns its keep only once somebody actually wants a layer on Model A.
Nobody does today, and minting the vocabulary in advance would stand up a second,
parallel way of expressing "this layer needs no query path" beside the empty
declaration, for zero consumers. Nothing above precludes it: the seam rule is a
default for *silence*, and a future axis would be one more thing a layer can
declare — at which point the layer is no longer silent and the default no longer
applies to it.

### Blast radius: the stricter rule locks nobody out

Surveyed read-only across the family before k118 landed. It belongs in the ADR and
not only in the ticket, because the ADR is what still gets read in five years:

- Exactly **two** sync storage layers are registered anywhere in the family.
  `dbio-postgresql-age`'s async mirror declares `on_connect_replay`, so it is a
  declaring layer and is untouched; `dbio-postgresql-postgis` has no `::Async`
  sibling at all, is skipped by the §4 mirror step and never reaches the gate.
- Every transport a layer composes over in the driver dists implements
  `_query_async` — `DBIO::Async::Storage` and the PG/MySQL adapters derived from it,
  `DBIO::PostgreSQL::EV::Storage`, `DBIO::MySQL::EV::Storage` — so their undeclared
  test-fixture layers still compose.
- The one composition that broke was an under-specified fixture in core's own suite:
  the stand-in transport in `t/composed/async_walk_base.t` was a bare
  `DBIO::Storage::Async`, kept minimal because that test drives the MRO walk and
  never executes a query. It gained the `_query_async` a real transport always has.

`t/composed/async_layer_default_seam.t` holds the rule: an undeclared layer over a
transport with the seam composes, the same layer over a seamless Model A transport
is refused with a message naming the seam, and a declaring layer — including one
declaring an explicit empty list — behaves as before.

## Addendum 2026-08-07 — §7 is mechanism-independent, and the resolution is lazy

§7 states the hard cut as "Extensions no longer subclass a driver storage via
`storage_type`; they register layers." That names the *tool* of the single violation
that existed when it was written. Read as written, every other way of pinning a driver
from inside an extension falls outside it — and the family has now hit two:

- **dbio-mysql-ev k14.** `DBIO::MySQL::EV` overrode `connection()` to force
  `storage_type('+DBIO::MySQL::EV::Storage')` on every connect. The literal §7 case;
  removed, with the reasoning kept as a comment in the module so a cross-repo reader
  finds it.
- **dbio-postgresql-age k8.** `DBIO::PostgreSQL::Age` gained
  `use base 'DBIO::PostgreSQL'`. No `storage_type` anywhere in the extension — the pin
  arrives second-hand, through the driver component's own `connection()`, by inheriting
  it. §7 as worded does not cover this, and the change passed review as a one-line bugfix.

Same error, two tools, both found only after the fact. The decision this ADR actually
made is therefore restated at the level it belongs on:

**An extension never determines the driver.** Not by `storage_type`, not by inheriting a
driver component, not by a role, not by any future mechanism that has the same effect. The
extension component registers a layer and inherits no driver's connect hook; the DSN decides
the driver and `_determine_driver` composes the layer over it. An extension that names a
driver class anywhere outside documentation or an `isa` assertion is the smell.

The rule is about the *connect path*, not about a mandated base class. `connection()` is the
only seam through which a component can decide the storage class, and it is exactly where
every driver component pins `storage_type`. A component that inherits such a hook — directly
or through any ancestor — has determined the driver, whatever route it took. What a component
derives from otherwise is style, not contract: all four extension components now sit on
`DBIO::Base`, but `PostgreSQL::Age` carried an empty `@ISA` until dbio-postgresql-age k9 and resolved
identically all along, because `load_components` unshifts the component into the consumer's
`@ISA` either way. The alignment cost nothing precisely because it added no ordering
constraint — `DBIO::PostgreSQL` and `DBIO::Schema` already derive from `DBIO::Base`, so it was
in the merge tail before Age named it, and both stacking orders linearise byte-identically to
before. Contrast dbio-postgresql-age k8, where the inherited component had to both precede
and follow Age depending on stacking order: an unsatisfiable merge. That difference is the
whole point — do not let a structural check conflate a base class with a connect hook.

Inheriting the driver component is additionally wrong on its own terms, independent of the
pin. It converts a mixin into an is-a relationship, and it breaks the direct stacking form:
with the Age component inheriting `DBIO::PostgreSQL`,

    use base qw( DBIO::PostgreSQL DBIO::PostgreSQL::Age DBIO::Schema );

fails C3 linearisation outright ("Inconsistent hierarchy during C3 merge") and the class
will not load. The reverse base order still works, so it is an order trap nobody sees
coming. `load_components` de-duplicates through `Class::C3::Componentised` and hides it;
`use base` does not. The failure also does not surface at compile time — `use base` alone
does not compute the linearisation, so a naive probe reports success; it dies at the first
resolution.

That form was a de-facto contract carried entirely by tests: seven files across
dbio-postgresql-age and dbio-postgresql-postgis stack this way, while `DBIO::PostgreSQL`
documented only the classic `use base 'DBIO::Schema'` + `load_components` form. Closed by
dbio-postgresql k55 — the form is now documented where it is owned, and pinned by a
test in that repo rather than only in the two dists that consume it.

The condition for the free order is narrower than it first looks, and worth stating exactly
because the obvious formulation is wrong: it is **not** "every component derives from
`DBIO::Base`". `PostgreSQL::PostGIS` carries `DBIO::InflateColumn` and `DBIO::Row` in its own
`@ISA` and stacks in either order regardless. The actual condition is that **no component in
the list inherits another one** — which is precisely what dbio-postgresql-age k8 broke, and why the break
was asymmetric: the inherited component had to both precede and follow the extension
depending on stacking order.

### Why both attempts went wrong in the same place: the resolution is lazy

Both violations were reached from the same wrong premise — that the composition resolves
its base at `connect`. It does not. §3 says the rebless path re-composes over the concrete
driver during `_determine_driver`, and `_determine_driver` runs on the **first `dbh`
access**, not on `connect`. Between the two, a layered schema legitimately carries
`Composed::<Layer>__DBIO_Storage_DBI`:

    my $schema = $age_only_schema->connect('dbi:Pg:...', ...);
    $schema->storage;                    # Composed::…Age_Storage__DBIO_Storage_DBI
    $schema->storage->isa('DBIO::PostgreSQL::Storage');   # false — nothing is wrong yet
    $schema->storage->ensure_connected;
    $schema->storage->isa('DBIO::PostgreSQL::Storage');   # true

The dbio-postgresql-age k8 incident sampled the first state, read it as a core bug in
`register_storage_layer`, and both proposed fixes pinned the driver to make the sample true.
Neither was needed: the mechanism was working. Anything that asserts the *driver* on a
layered storage must connect first — and an assertion that only holds because the
extension pinned the driver has stopped testing the composition and is testing the pin.

### Mechanical enforcement

Documentation alone has now failed twice, so the rule is asserted in code rather than only
written down. Core ships a structural check an extension distribution runs over its own
component/layer pair; the two historical violations are its fixtures. A third relapse fails
a test instead of reaching review.

## Addendum 2026-09-25 — §4 gets a stated opt-out; the silent skip goes

§4 ends with "absent → skip `L` silently (a sync-only extension, e.g. PostGIS)".
After the 2026-07-27 addendum that is the last silent path in the async resolver. A
mirror file whose package name carries a typo makes an extension quietly sync-only,
and nothing distinguishes that accident from PostGIS, which is sync-only on purpose
and says so only in its POD. This addendum records the maintainer decision of
2026-09-24 on karr k159 and changes §4. It is an addendum rather than an inline edit
for the same reason as the k118 one: the decision changes, not just its
implementation.

### The actual defect: `undef` was already taken

The silence was the symptom. The cause was that `async_layer_class($mode)`
returning `undef` meant "use the convention". That spends the one natural value for
"deliberately none", so under the old reading every opt-out needs either a magic
sentinel or a second method. §5 did not have this problem: there the opt-out is the
explicit empty list, a natural value of its domain.

### Decision (form A′): swap the meanings

| `L` …                                   | means                        | effect |
|-----------------------------------------|------------------------------|--------|
| defines `async_layer_class`, returns a package | this is the async layer | must load, else croak (unchanged) |
| defines `async_layer_class`, returns `undef`   | **stated**: deliberately sync-only for `$mode` | skipped, **no load attempt**, a `${L}::Async` sibling is ignored |
| does not define `async_layer_class`            | **silent**: use the convention | `${L}::Async` if present (broken → croak); absent → see Sequence |

This is the stated-vs-silent axis of the 2026-07-27 addendum applied to §4. Defining
the method *is* the statement, just as declaring an empty
`required_transport_capabilities` is. No sentinel constant and no third declaration
method are needed.

The forms we rejected, with their costs, are on karr k159 (the options write-up of
2026-09-05). In short:

- **A — a named sentinel from `async_layer_class`.** Gives one method two meanings
  told apart by a magic value, and a mistyped sentinel falls into the must-load path.
- **B — a separate predicate method.** Adds a third declaration method, and the
  predicate and `async_layer_class` can contradict each other.
- **C — declaring it at `register_storage_layer`.** Puts a property of the layer
  into every consumer's schema, and changes a public signature.
- **D — only tracing the skip.** Leaves silence silent, just louder in a log.

A′ was cheap because nobody in the family defined `async_layer_class` (grep across
every dbio repo, 2026-09-05). The old `undef` meaning had no consumer outside core's
own test fixture, so reversing it costs this addendum and one replaced test scenario,
not a migration.

Two details follow from resolving through `can()` and passing `$mode`, and both are
intended:

- A subclass of a declaring layer inherits its answer.
- A layer can be sync-only under one mode and mirrored under another.

Reading `undef` from a defined method as an answer, not a forgotten `return`, is
documented where the resolver makes the decision (`_async_storage` in
`lib/DBIO/Storage/DBI.pm`) and in the `DBIO::Storage::Composed` POD.

### Sequence — additive first, strict last

As in §6, the permissive step lands before the strict one, and never the other way
round:

1. **Core understands the stated opt-out** (karr k159, step 1). Defined-and-`undef`
   skips without a load attempt. "Silent and absent → skip" **stays** for now,
   marked transitional in the resolver, because `dbio-postgresql-postgis` still
   relies on it. This step on its own breaks nothing.
2. **`dbio-postgresql-postgis` declares itself sync-only.** Its storage layer defines
   `async_layer_class` returning `undef`, and its POD section "No async layer" points
   at the method. Behaviour there is unchanged. Then `dzil install`.
3. **Core makes "silent and absent" a refusal.** A layer that neither defines
   `async_layer_class` nor ships a `${L}::Async` sibling croaks at compose time,
   naming the layer, the convention class it tried and the one-line opt-out.
   Before this step, the other exits must stay closed: a present-but-broken sibling
   already croaks (`_try_load_async_class` names the cause), so the refusal catches
   only genuine absence.

The blast radius is the one surveyed in the 2026-07-27 addendum. Exactly two sync
layers exist in the family: AGE has an `::Async` sibling and is unaffected, and
PostGIS has none. Step 3 would break exactly that one dist, which is why step 2
precedes it.

`t/composed/async_mirror.t` scenario 3 holds the opt-out. A declaring layer is not
composed even when a convention sibling exists, triggers no load attempt, and does
not stop its silent neighbours from mirroring. Before k159 that scenario asserted
the opposite ("`undef` falls back to the convention"); the claim was replaced
deliberately, not lost.

### Step 3 done, 2026-09-25

Steps 1 and 2 landed first: core commit a13e6f0d, and dbio-postgresql-postgis
cd3a8ec (postgis k8), installed. Step 3 then removed the silent path. In
`_async_storage` a layer that does not define `async_layer_class` and has no
loadable `${L}::Async` now throws a `DBIO::Exception`. The message names the
layer, the async mode and the convention class it looked for. It shows both ways
out, `sub async_layer_class { undef }` in the layer or an `${L}::Async` mirror, and
points at this addendum and k159. The §4 mirror step no longer has a silent path.

Before tightening, every DBIO repo except `dbio-informix` was surveyed again,
read-only. Every layer registered anywhere either ships a sibling or declares:

- Shipped layers: `DBIO::PostgreSQL::Age::Storage` has `::Async`, and
  `DBIO::PostgreSQL::PostGIS::Storage` declares `undef`.
- Test fixtures in dbio-postgresql, dbio-mysql, dbio-postgresql-ev and
  dbio-mysql-ev all ship an `::Async` sibling.
- The fixture layers in the sync-only seam tests (dbio-postgresql `t/44`, `t/46`)
  are never composed async, so the refusal cannot reach them.

In core, two test claims that sampled the silent skip were replaced, not kept.
`t/composed/async_mirror.t` scenario 1 had a layer with no sibling. It now declares
itself sync-only, and the new scenario 5 asserts the refusal. The PostGIS stand-in
in `t/composed/async_modes_example.t` now declares `undef`, as the real layer does.

## Addendum 2026-10-15 — `dbio_deploy_class` belongs to the driver storage

Amended by ADR 0066 section 4. `dbio_deploy_class` names the driver's Deploy
class and has one owner, the driver storage; the set of chainable layer hooks
is empty. `compose` refuses a layer that defines `dbio_deploy_class` with a
`DBIO::Exception` naming the layer and the rule. What an extension adds to a
deploy reaches it through the extension list the driver runs (ADR 0066), and
callers (`Storage::DBI::deploy`, `Schema`, `DeployMethod::Native`) keep asking
`$storage->dbio_deploy_class`. Every other doubly defined method still fails at
compose time.
