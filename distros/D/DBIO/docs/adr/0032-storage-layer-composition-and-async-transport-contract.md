# ADR 0032 — Storage-layer composition and the async transport contract

- Status: accepted
- Date: 2026-07-09
- Tags: storage, async, composition, extensions, contract, capabilities, builds-on-0030, hard-cut

## Context

DBIO storage *extensions* (AGE, PostGIS, EV) and DBIO async *transports*
(future_io, EV) are two independent axes. Before this decision an extension that
also wanted async had to hand-write one class per (extension × transport) cell —
an N×M matrix — and welded itself to a transport by `use base`-ing its async
storage. The #69 ideation surveyed this and the maintainer approved a single
fundamental model (#70): **one behaviour, one transport**. N extension layers and
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

### 5. Transport capabilities

`DBIO::Storage::Async->transport_capabilities` returns a list (base default
empty); transports override it (future_io → `on_connect_replay`; EV → `listen`
`notify` `copy` `pipeline` … per their own tickets). An async layer may declare
`required_transport_capabilities`. Before composing, any capability a layer
requires but the transport lacks makes `_async_storage` croak naming the layer,
the missing capabilities and the transport, with the hint to upgrade the
transport or choose another async mode. A transport gap becomes that transport's
ticket — never a silent feature loss.

### 6. The `?` placeholder contract at the async seam

`_query_async` / `_query_async_pinned` receive **sql_maker dialect with `?`
placeholders**; a transport MUST shape the dialect internally (its own
`_transform_sql` or equivalent). `_transform_sql` is demoted to a
transport-**internal** helper — no caller outside a transport implementation may
invoke it. The caller-side `_transform_sql` in `_run_crud` is therefore removed —
but *sequenced*: the transport-side internalisation (dbio-async #3) lands FIRST,
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
  frozen as #70 specified.
- Sequencing: the §6 caller-side `_transform_sql` removal in core is held behind
  the coordinated dbio-async #3 PR train.

## Downstream

Reference driver compliance + skill sync (dbio-postgresql #28), thin-transport
refactor (dbio-postgresql-ev #22), layer migration + hard cut (dbio-postgresql-age
#6, dbio-postgresql-postgis #4), transport dialect internalisation + capabilities
(dbio-async #3). Supersedes the #69 ideation.
