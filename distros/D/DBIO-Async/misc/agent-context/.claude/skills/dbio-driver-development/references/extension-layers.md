# Extensions: the declared list and the storage layer

Reference for `dbio-driver-development`. Load when writing an extension (AGE, PostGIS, tenant add-on).

A driver **extension** (AGE, PostGIS, pgvector) has two halves, and neither subclasses
`storage_type` or ships a per-extension `<pkg>::Async` transport of its own.

**The model half is a class on the declared list** (ADR 0066). The schema declares which
extensions its database has, in the driver's spelling (PostgreSQL: `pg_extensions`); that
declaration is the list, and loading a component adds nothing to it:

    package MyApp::DB;
    use DBIO 'Schema', -pg;                                         # the driver
    __PACKAGE__->pg_extensions('age', postgis => { schema => 'gis' });

- `DBIO::Extension` is the base class: `name`, `driver` (assertion, checked after driver
  resolution, never at `connect`), the interface `inspect`, `claims`, `annotate`, `verdict`,
  `activation` (interface version 1), plus `storage_layer` and the optional `components`
  (result-side component names the driver applies). Its POD is the contract.
- `DBIO::Extension::List` resolves the declared names to classes: the driver's fixed table
  of family extensions, a `class` option for any other, the plain rule-less class otherwise.
- `DBIO::Extension::Protocol` runs the phases over the active extensions (declared, each
  with its installed state), sorted by name, and merges their answers; the driver's Deploy
  class runs it around introspect, target model and diff. Rules of two extensions meet only
  there, never through class composition.
- Test the set with `DBIO::Test::ExtensionSet` (`extension_set_ok`: the extensions commute).
- The driver owns the installed-state reader, addresses, creating/dropping the extension
  and the composition of `activation` into the connection (ADR 0066 §3).

**The runtime half is a plain storage layer** — a method package, no `@ISA` pointing at a
storage — which the extension names in `storage_layer` and the driver registers
(`register_storage_layer`; an extension outside the list machinery registers it on the
schema directly):

    $schema->register_storage_layer('DBIO::X::Ext::Storage');

The extension never declares the driver; the schema does, and the DSN does not decide it
(ADR 0059, 0067).

Core composes every registered layer over the base storage by C3-MRO class
synthesis (`DBIO::Storage::Composed->compose($base, \@layers)`): the synthesised
`DBIO::Storage::Composed::<Layer>__<Base>` has `@ISA = (@layers, $base)` under
the `c3` MRO and no methods of its own, so calls walk the layers (registration
order = precedence) and fall through to the base; layer hooks chain with
`$self->next::method(@_)`. Two layers defining the *same own method* is a compose-
time croak — silent shadowing between siblings is forbidden — and no hook is exempt:
`dbio_deploy_class` belongs to the driver storage, not to a layer. The base is the
declared driver storage; when it adapts to its access path (`_adapt_to_access_path`), core
re-composes the same layers over the adapted class (`recompose`), so the layers survive
the adaptation.

**A layer states its async side** (ADR 0032 addendum 2026-09-25): it ships a
`${L}::Async` mirror, or defines `sub async_layer_class { undef }` to say it is
deliberately sync-only. A layer with neither is refused when core composes the async
storage of a schema in an async mode — silence is no opt-out. Mirror mechanics:
`references/async-transport.md`.

**The rule covers the component, not only the storage class.** Both halves of an extension
are constrained: the *layer* has no `@ISA` pointing at a storage, and the *component*
inherits no driver component's `connection()` hook. That hook is the only seam through
which a component can decide the storage class, and it is exactly where every driver
component pins `storage_type` — so the rule is about the connect path, not about a
mandated base class. All four extension components sit on `DBIO::Base` today, but
`Age` carried an empty `@ISA` until karr dbio-postgresql-age k9 and resolved identically all along, since
`load_components` unshifts the component into the consumer's `@ISA` either way.

A component that `use base`s a driver component (`DBIO::PostgreSQL`, `DBIO::MySQL`, …) inherits that component's `connection()` and with it
its `storage_type` pin — the same violation, second-hand. It also breaks the direct
stacking form: once `DBIO::X` inherits `DBIO::PostgreSQL`,

    use base qw( DBIO::PostgreSQL DBIO::X DBIO::Schema );

fails C3 linearisation ("Inconsistent hierarchy during C3 merge") and the class will not
load, while the reverse base order still works — an order trap `load_components` hides
through `Class::C3::Componentised` dedup and `use base` does not. It does not surface at
compile time either: `use base` alone does not compute the linearisation, so a naive probe
reports success and it dies at the first resolution. That stacking form is a de-facto
contract carried by tests only — seven files across dbio-postgresql-age and
dbio-postgresql-postgis stack this way, no driver POD documents it. Broken twice in the
family with two different tools: karr dbio-mysql-ev k14 (`storage_type` override),
karr dbio-postgresql-age k8 (`use base`). ADR 0032 §7 plus its 2026-08-07 addendum is the full
rule; core carries a structural test for it.

**Driver resolution is lazy — connect before you assert the access-path class.**
`_determine_driver` runs on the first `dbh` access, not on `connect`. From `connect` on, the
composed base is the declared driver storage; on the first `dbh` access it may still adapt
to its access path, and the layers are re-composed over the adapted class:

    my $schema = MyApp::DB->connect('dbi:ODBC:…', $u, $p);   # MyApp::DB: -ms + a layer
    $schema->storage->isa('DBIO::MSSQL::Storage');           # true — the declaration
    $schema->storage->isa('DBIO::MSSQL::Storage::ODBC');     # false — not yet adapted
    $schema->storage->ensure_connected;
    $schema->storage->isa('DBIO::MSSQL::Storage::ODBC');     # true — layers recomposed

A test that asserts the specialised class on a layered storage connects first. Both
violations above started from a test that sampled the intermediate state and was "fixed"
by pinning the driver in the extension — after which the assertion holds because of the
pin and no longer tests the composition at all.

